/* Hardware-only local EGL/GLES shader test. Never accepts a software renderer. */
#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <GLES3/gl3.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static void die(const char *message)
{
    fprintf(stderr,"FAIL: %s (EGL error 0x%x)\n",message,eglGetError());
    exit(1);
}
static GLuint shader(GLenum type,const char *text)
{
    GLuint s=glCreateShader(type); glShaderSource(s,1,&text,NULL); glCompileShader(s);
    GLint ok=0; glGetShaderiv(s,GL_COMPILE_STATUS,&ok);
    if (!ok) { char log[4096]; glGetShaderInfoLog(s,sizeof(log),NULL,log); fprintf(stderr,"Shader: %s\n",log); die("shader compilation"); }
    return s;
}
int main(int argc,char **argv)
{
    setvbuf(stdout,NULL,_IOLBF,0);
    if (argc!=2) { fprintf(stderr,"Usage: %s /dev/dri/renderD128\n",argv[0]); return 2; }
    PFNEGLQUERYDEVICESEXTPROC query=(PFNEGLQUERYDEVICESEXTPROC)eglGetProcAddress("eglQueryDevicesEXT");
    PFNEGLQUERYDEVICESTRINGEXTPROC string=(PFNEGLQUERYDEVICESTRINGEXTPROC)eglGetProcAddress("eglQueryDeviceStringEXT");
    PFNEGLGETPLATFORMDISPLAYEXTPROC platform=(PFNEGLGETPLATFORMDISPLAYEXTPROC)eglGetProcAddress("eglGetPlatformDisplayEXT");
    if (!query || !string || !platform) die("EGL device extensions unavailable");
    EGLDeviceEXT devices[16]; EGLint count=0; EGLDeviceEXT selected=EGL_NO_DEVICE_EXT;
    if (!query(16,devices,&count)) die("enumerating EGL devices");
    for (int i=0;i<count;i++) {
        const char *node=string(devices[i],EGL_DRM_RENDER_NODE_FILE_EXT);
        if (node && !strcmp(node,argv[1])) selected=devices[i];
    }
    if (selected==EGL_NO_DEVICE_EXT) die("requested DRM render node is unavailable to EGL");
    EGLDisplay d=platform(EGL_PLATFORM_DEVICE_EXT,selected,NULL);
    EGLint major=0,minor=0;
    if (d==EGL_NO_DISPLAY || !eglInitialize(d,&major,&minor)) die("initializing hardware EGL display");
    printf("EGL %d.%d device %s vendor %s\n",major,minor,argv[1],eglQueryString(d,EGL_VENDOR));
    if (!eglBindAPI(EGL_OPENGL_ES_API)) die("binding GLES API");
    EGLint attrs[]={EGL_SURFACE_TYPE,EGL_PBUFFER_BIT,EGL_RENDERABLE_TYPE,EGL_OPENGL_ES3_BIT_KHR,
                   EGL_RED_SIZE,8,EGL_GREEN_SIZE,8,EGL_BLUE_SIZE,8,EGL_ALPHA_SIZE,8,EGL_NONE};
    EGLConfig cfg; EGLint n=0;
    if (!eglChooseConfig(d,attrs,&cfg,1,&n) || n!=1) die("choosing GLES3 pbuffer config");
    EGLint pb[]={EGL_WIDTH,32,EGL_HEIGHT,32,EGL_NONE};
    EGLSurface surface=eglCreatePbufferSurface(d,cfg,pb);
    EGLint ca[]={EGL_CONTEXT_CLIENT_VERSION,3,EGL_NONE};
    EGLContext ctx=eglCreateContext(d,cfg,EGL_NO_CONTEXT,ca);
    if (surface==EGL_NO_SURFACE || ctx==EGL_NO_CONTEXT || !eglMakeCurrent(d,surface,surface,ctx)) die("creating GLES3 context");
    const char *renderer=(const char*)glGetString(GL_RENDERER);
    printf("GL_VENDOR=%s\nGL_RENDERER=%s\nGL_VERSION=%s\nGLSL_VERSION=%s\n",
           glGetString(GL_VENDOR),renderer,glGetString(GL_VERSION),glGetString(GL_SHADING_LANGUAGE_VERSION));
    if (!renderer || !strstr(renderer,"Lakefield") || strstr(renderer,"llvmpipe") || strstr(renderer,"softpipe")) die("renderer is not the experimental Lakefield GPU");
    const char *vs="#version 300 es\nconst vec2 p[3]=vec2[3](vec2(-1.,-1.),vec2(3.,-1.),vec2(-1.,3.));void main(){gl_Position=vec4(p[gl_VertexID],0.,1.);}";
    const char *fs="#version 300 es\nprecision highp float;out vec4 color;void main(){color=vec4(0.25,0.5,0.75,1.);}";
    GLuint v=shader(GL_VERTEX_SHADER,vs),f=shader(GL_FRAGMENT_SHADER,fs),program=glCreateProgram();
    glAttachShader(program,v); glAttachShader(program,f); glLinkProgram(program);
    GLint ok=0; glGetProgramiv(program,GL_LINK_STATUS,&ok);
    if (!ok) {char log[4096];glGetProgramInfoLog(program,sizeof(log),NULL,log);fprintf(stderr,"Link: %s\n",log);die("linking GLES program");}
    glViewport(0,0,32,32);glClearColor(1,0,1,1);glClear(GL_COLOR_BUFFER_BIT);
    glUseProgram(program);glDrawArrays(GL_TRIANGLES,0,3);glFinish();
    unsigned char pixels[32*32*4];glReadPixels(0,0,32,32,GL_RGBA,GL_UNSIGNED_BYTE,pixels);
    GLenum error=glGetError();if(error!=GL_NO_ERROR){fprintf(stderr,"GL error 0x%x\n",error);die("render/readback");}
    const int expected[4]={64,128,191,255};
    for(int p=0;p<32*32;p++)for(int c=0;c<4;c++)if(abs((int)pixels[4*p+c]-expected[c])>2){
        fprintf(stderr,"Pixel %d channel %d = %u, expected %d\n",p,c,pixels[4*p+c],expected[c]);die("GPU shader output mismatch");
    }
    puts("PASS: hardware GLES3 shader compiled, rendered 1024 pixels, and all RGBA values matched.");
    puts("Desktop scanout and stability are separate, still unvalidated steps.");
    glDeleteProgram(program);glDeleteShader(v);glDeleteShader(f);
    eglMakeCurrent(d,EGL_NO_SURFACE,EGL_NO_SURFACE,EGL_NO_CONTEXT);
    eglDestroyContext(d,ctx);eglDestroySurface(d,surface);eglTerminate(d);
    return 0;
}
