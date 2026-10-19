/* Hardware-only local EGL/GLES shader test. Never accepts a software renderer. */
#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <GLES3/gl3.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <gbm.h>
#include <xf86drm.h>
#include <xf86drmMode.h>
#include <drm_fourcc.h>

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
    if (argc!=2) { fprintf(stderr,"Usage: %s /dev/dri/card0\n",argv[0]); return 2; }
    int fd=open(argv[1],O_RDWR|O_CLOEXEC);
    if(fd<0) die("opening firmware KMS node");
    drmVersionPtr version=drmGetVersion(fd);
    if(!version || strcmp(version->name,"simpledrm")) die("output is not simpledrm");
    drmFreeVersion(version);
    drmModeRes *resources=drmModeGetResources(fd);
    if(!resources || resources->min_width<32 || resources->min_height<32) die("reading firmware framebuffer dimensions");
    uint32_t width=resources->min_width,height=resources->min_height;
    drmModeFreeResources(resources);
    printf("Firmware minimum framebuffer: %ux%u\n",width,height);
    struct gbm_device *gbm=gbm_create_device(fd);
    if(!gbm) die("creating hardware GBM bridge on firmware KMS node");
    PFNEGLGETPLATFORMDISPLAYEXTPROC platform=(PFNEGLGETPLATFORMDISPLAYEXTPROC)eglGetProcAddress("eglGetPlatformDisplayEXT");
    if(!platform) die("EGL platform extension unavailable");
    EGLDisplay d=platform(EGL_PLATFORM_GBM_KHR,gbm,NULL);
    EGLint major=0,minor=0;
    if (d==EGL_NO_DISPLAY || !eglInitialize(d,&major,&minor)) die("initializing hardware EGL display");
    printf("EGL %d.%d device %s vendor %s\n",major,minor,argv[1],eglQueryString(d,EGL_VENDOR));
    if (!eglBindAPI(EGL_OPENGL_ES_API)) die("binding GLES API");
    EGLint attrs[]={EGL_SURFACE_TYPE,EGL_WINDOW_BIT,EGL_RENDERABLE_TYPE,EGL_OPENGL_ES3_BIT_KHR,
                   EGL_RED_SIZE,8,EGL_GREEN_SIZE,8,EGL_BLUE_SIZE,8,EGL_NONE};
    EGLConfig configs[128],cfg=NULL; EGLint n=0;
    if(!eglChooseConfig(d,attrs,configs,128,&n)) die("enumerating GBM window configs");
    for(int i=0;i<n;i++) {
        EGLint visual=0;eglGetConfigAttrib(d,configs[i],EGL_NATIVE_VISUAL_ID,&visual);
        if((unsigned)visual==GBM_FORMAT_XRGB8888) {cfg=configs[i];break;}
    }
    if(!cfg) die("no XRGB8888 hardware window config");
    struct gbm_surface *window=gbm_surface_create(gbm,width,height,GBM_FORMAT_XRGB8888,
        GBM_BO_USE_SCANOUT|GBM_BO_USE_RENDERING|GBM_BO_USE_LINEAR);
    if(!window) die("creating linear scanout GBM surface");
    EGLSurface surface=eglCreateWindowSurface(d,cfg,(EGLNativeWindowType)window,NULL);
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
    if(!eglSwapBuffers(d,surface)) die("swapping GPU-rendered GBM window");
    struct gbm_bo *bo=gbm_surface_lock_front_buffer(window);
    if(!bo) die("locking GPU-rendered scanout buffer");
    uint32_t handles[4]={gbm_bo_get_handle(bo).u32,0,0,0};
    uint32_t strides[4]={gbm_bo_get_stride(bo),0,0,0},offsets[4]={0,0,0,0},fb=0;
    if(!handles[0] || gbm_bo_get_modifier(bo)!=DRM_FORMAT_MOD_LINEAR) die("invalid linear KMS buffer");
    if(drmModeAddFB2(fd,width,height,GBM_FORMAT_XRGB8888,handles,strides,offsets,&fb,0)) {
        perror("drmModeAddFB2");die("importing GPU buffer as firmware KMS framebuffer");
    }
    printf("PASS: GPU-rendered linear buffer imported into simpledrm framebuffer %u; no display flip performed.\n",fb);
    drmModeRmFB(fd,fb);
    gbm_surface_release_buffer(window,bo);
    glDeleteProgram(program);glDeleteShader(v);glDeleteShader(f);
    eglMakeCurrent(d,EGL_NO_SURFACE,EGL_NO_SURFACE,EGL_NO_CONTEXT);
    eglDestroyContext(d,ctx);eglDestroySurface(d,surface);eglTerminate(d);
    gbm_surface_destroy(window);gbm_device_destroy(gbm);close(fd);
    return 0;
}
