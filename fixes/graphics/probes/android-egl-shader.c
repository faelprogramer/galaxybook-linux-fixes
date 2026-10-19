/* Hardware-only local EGL/GLES shader test. Never accepts a software renderer. */
#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <GLES3/gl3.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <dlfcn.h>
static __typeof__(&eglBindAPI) api_eglBindAPI;
static __typeof__(&eglChooseConfig) api_eglChooseConfig;
static __typeof__(&eglCreateContext) api_eglCreateContext;
static __typeof__(&eglCreatePbufferSurface) api_eglCreatePbufferSurface;
static __typeof__(&eglDestroyContext) api_eglDestroyContext;
static __typeof__(&eglDestroySurface) api_eglDestroySurface;
static __typeof__(&eglGetError) api_eglGetError;
static __typeof__(&eglGetProcAddress) api_eglGetProcAddress;
static __typeof__(&eglInitialize) api_eglInitialize;
static __typeof__(&eglMakeCurrent) api_eglMakeCurrent;
static __typeof__(&eglQueryString) api_eglQueryString;
static __typeof__(&eglTerminate) api_eglTerminate;
static __typeof__(&glAttachShader) api_glAttachShader;
static __typeof__(&glClear) api_glClear;
static __typeof__(&glClearColor) api_glClearColor;
static __typeof__(&glCompileShader) api_glCompileShader;
static __typeof__(&glCreateProgram) api_glCreateProgram;
static __typeof__(&glCreateShader) api_glCreateShader;
static __typeof__(&glDeleteProgram) api_glDeleteProgram;
static __typeof__(&glDeleteShader) api_glDeleteShader;
static __typeof__(&glDrawArrays) api_glDrawArrays;
static __typeof__(&glFinish) api_glFinish;
static __typeof__(&glGetError) api_glGetError;
static __typeof__(&glGetProgramInfoLog) api_glGetProgramInfoLog;
static __typeof__(&glGetProgramiv) api_glGetProgramiv;
static __typeof__(&glGetShaderInfoLog) api_glGetShaderInfoLog;
static __typeof__(&glGetShaderiv) api_glGetShaderiv;
static __typeof__(&glGetString) api_glGetString;
static __typeof__(&glLinkProgram) api_glLinkProgram;
static __typeof__(&glReadPixels) api_glReadPixels;
static __typeof__(&glShaderSource) api_glShaderSource;
static __typeof__(&glUseProgram) api_glUseProgram;
static __typeof__(&glViewport) api_glViewport;
static int init_driver_apis(void) {
 const char *dir=getenv("LKF_PROBE_LIBRARY_DIR"); if(!dir)return 0;
 char path[4096];snprintf(path,sizeof(path),"%s/libEGL_mesa.so",dir);
 void *egl=dlopen(path,RTLD_NOW|RTLD_GLOBAL);if(!egl){fprintf(stderr,"EGL load: %s\n",dlerror());return 0;}
 snprintf(path,sizeof(path),"%s/libGLESv2_mesa.so",dir);
 void *gles=dlopen(path,RTLD_NOW|RTLD_GLOBAL);if(!gles){fprintf(stderr,"GLES load: %s\n",dlerror());return 0;}
 api_eglBindAPI=(__typeof__(api_eglBindAPI))dlsym(egl,"eglBindAPI");if(!api_eglBindAPI){fprintf(stderr,"Missing eglBindAPI\n");return 0;}
 api_eglChooseConfig=(__typeof__(api_eglChooseConfig))dlsym(egl,"eglChooseConfig");if(!api_eglChooseConfig){fprintf(stderr,"Missing eglChooseConfig\n");return 0;}
 api_eglCreateContext=(__typeof__(api_eglCreateContext))dlsym(egl,"eglCreateContext");if(!api_eglCreateContext){fprintf(stderr,"Missing eglCreateContext\n");return 0;}
 api_eglCreatePbufferSurface=(__typeof__(api_eglCreatePbufferSurface))dlsym(egl,"eglCreatePbufferSurface");if(!api_eglCreatePbufferSurface){fprintf(stderr,"Missing eglCreatePbufferSurface\n");return 0;}
 api_eglDestroyContext=(__typeof__(api_eglDestroyContext))dlsym(egl,"eglDestroyContext");if(!api_eglDestroyContext){fprintf(stderr,"Missing eglDestroyContext\n");return 0;}
 api_eglDestroySurface=(__typeof__(api_eglDestroySurface))dlsym(egl,"eglDestroySurface");if(!api_eglDestroySurface){fprintf(stderr,"Missing eglDestroySurface\n");return 0;}
 api_eglGetError=(__typeof__(api_eglGetError))dlsym(egl,"eglGetError");if(!api_eglGetError){fprintf(stderr,"Missing eglGetError\n");return 0;}
 api_eglGetProcAddress=(__typeof__(api_eglGetProcAddress))dlsym(egl,"eglGetProcAddress");if(!api_eglGetProcAddress){fprintf(stderr,"Missing eglGetProcAddress\n");return 0;}
 api_eglInitialize=(__typeof__(api_eglInitialize))dlsym(egl,"eglInitialize");if(!api_eglInitialize){fprintf(stderr,"Missing eglInitialize\n");return 0;}
 api_eglMakeCurrent=(__typeof__(api_eglMakeCurrent))dlsym(egl,"eglMakeCurrent");if(!api_eglMakeCurrent){fprintf(stderr,"Missing eglMakeCurrent\n");return 0;}
 api_eglQueryString=(__typeof__(api_eglQueryString))dlsym(egl,"eglQueryString");if(!api_eglQueryString){fprintf(stderr,"Missing eglQueryString\n");return 0;}
 api_eglTerminate=(__typeof__(api_eglTerminate))dlsym(egl,"eglTerminate");if(!api_eglTerminate){fprintf(stderr,"Missing eglTerminate\n");return 0;}
 api_glAttachShader=(__typeof__(api_glAttachShader))dlsym(gles,"glAttachShader");if(!api_glAttachShader){fprintf(stderr,"Missing glAttachShader\n");return 0;}
 api_glClear=(__typeof__(api_glClear))dlsym(gles,"glClear");if(!api_glClear){fprintf(stderr,"Missing glClear\n");return 0;}
 api_glClearColor=(__typeof__(api_glClearColor))dlsym(gles,"glClearColor");if(!api_glClearColor){fprintf(stderr,"Missing glClearColor\n");return 0;}
 api_glCompileShader=(__typeof__(api_glCompileShader))dlsym(gles,"glCompileShader");if(!api_glCompileShader){fprintf(stderr,"Missing glCompileShader\n");return 0;}
 api_glCreateProgram=(__typeof__(api_glCreateProgram))dlsym(gles,"glCreateProgram");if(!api_glCreateProgram){fprintf(stderr,"Missing glCreateProgram\n");return 0;}
 api_glCreateShader=(__typeof__(api_glCreateShader))dlsym(gles,"glCreateShader");if(!api_glCreateShader){fprintf(stderr,"Missing glCreateShader\n");return 0;}
 api_glDeleteProgram=(__typeof__(api_glDeleteProgram))dlsym(gles,"glDeleteProgram");if(!api_glDeleteProgram){fprintf(stderr,"Missing glDeleteProgram\n");return 0;}
 api_glDeleteShader=(__typeof__(api_glDeleteShader))dlsym(gles,"glDeleteShader");if(!api_glDeleteShader){fprintf(stderr,"Missing glDeleteShader\n");return 0;}
 api_glDrawArrays=(__typeof__(api_glDrawArrays))dlsym(gles,"glDrawArrays");if(!api_glDrawArrays){fprintf(stderr,"Missing glDrawArrays\n");return 0;}
 api_glFinish=(__typeof__(api_glFinish))dlsym(gles,"glFinish");if(!api_glFinish){fprintf(stderr,"Missing glFinish\n");return 0;}
 api_glGetError=(__typeof__(api_glGetError))dlsym(gles,"glGetError");if(!api_glGetError){fprintf(stderr,"Missing glGetError\n");return 0;}
 api_glGetProgramInfoLog=(__typeof__(api_glGetProgramInfoLog))dlsym(gles,"glGetProgramInfoLog");if(!api_glGetProgramInfoLog){fprintf(stderr,"Missing glGetProgramInfoLog\n");return 0;}
 api_glGetProgramiv=(__typeof__(api_glGetProgramiv))dlsym(gles,"glGetProgramiv");if(!api_glGetProgramiv){fprintf(stderr,"Missing glGetProgramiv\n");return 0;}
 api_glGetShaderInfoLog=(__typeof__(api_glGetShaderInfoLog))dlsym(gles,"glGetShaderInfoLog");if(!api_glGetShaderInfoLog){fprintf(stderr,"Missing glGetShaderInfoLog\n");return 0;}
 api_glGetShaderiv=(__typeof__(api_glGetShaderiv))dlsym(gles,"glGetShaderiv");if(!api_glGetShaderiv){fprintf(stderr,"Missing glGetShaderiv\n");return 0;}
 api_glGetString=(__typeof__(api_glGetString))dlsym(gles,"glGetString");if(!api_glGetString){fprintf(stderr,"Missing glGetString\n");return 0;}
 api_glLinkProgram=(__typeof__(api_glLinkProgram))dlsym(gles,"glLinkProgram");if(!api_glLinkProgram){fprintf(stderr,"Missing glLinkProgram\n");return 0;}
 api_glReadPixels=(__typeof__(api_glReadPixels))dlsym(gles,"glReadPixels");if(!api_glReadPixels){fprintf(stderr,"Missing glReadPixels\n");return 0;}
 api_glShaderSource=(__typeof__(api_glShaderSource))dlsym(gles,"glShaderSource");if(!api_glShaderSource){fprintf(stderr,"Missing glShaderSource\n");return 0;}
 api_glUseProgram=(__typeof__(api_glUseProgram))dlsym(gles,"glUseProgram");if(!api_glUseProgram){fprintf(stderr,"Missing glUseProgram\n");return 0;}
 api_glViewport=(__typeof__(api_glViewport))dlsym(gles,"glViewport");if(!api_glViewport){fprintf(stderr,"Missing glViewport\n");return 0;}
 return 1;
}
#define eglBindAPI api_eglBindAPI
#define eglChooseConfig api_eglChooseConfig
#define eglCreateContext api_eglCreateContext
#define eglCreatePbufferSurface api_eglCreatePbufferSurface
#define eglDestroyContext api_eglDestroyContext
#define eglDestroySurface api_eglDestroySurface
#define eglGetError api_eglGetError
#define eglGetProcAddress api_eglGetProcAddress
#define eglInitialize api_eglInitialize
#define eglMakeCurrent api_eglMakeCurrent
#define eglQueryString api_eglQueryString
#define eglTerminate api_eglTerminate
#define glAttachShader api_glAttachShader
#define glClear api_glClear
#define glClearColor api_glClearColor
#define glCompileShader api_glCompileShader
#define glCreateProgram api_glCreateProgram
#define glCreateShader api_glCreateShader
#define glDeleteProgram api_glDeleteProgram
#define glDeleteShader api_glDeleteShader
#define glDrawArrays api_glDrawArrays
#define glFinish api_glFinish
#define glGetError api_glGetError
#define glGetProgramInfoLog api_glGetProgramInfoLog
#define glGetProgramiv api_glGetProgramiv
#define glGetShaderInfoLog api_glGetShaderInfoLog
#define glGetShaderiv api_glGetShaderiv
#define glGetString api_glGetString
#define glLinkProgram api_glLinkProgram
#define glReadPixels api_glReadPixels
#define glShaderSource api_glShaderSource
#define glUseProgram api_glUseProgram
#define glViewport api_glViewport

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
    if(!init_driver_apis())return 1;
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
