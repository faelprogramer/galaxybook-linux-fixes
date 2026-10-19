/* MIT: actual GLX renderer check; direct rendering alone is insufficient. */
#include <GL/gl.h>
#include <GL/glx.h>
#include <stdio.h>
#include <string.h>
int main(void) {
 Display *d=XOpenDisplay(NULL); if(!d){fputs("No X11 display\n",stderr);return 1;}
 int attrs[]={GLX_X_RENDERABLE,True,GLX_DRAWABLE_TYPE,GLX_PBUFFER_BIT,GLX_RENDER_TYPE,GLX_RGBA_BIT,GLX_RED_SIZE,8,GLX_GREEN_SIZE,8,GLX_BLUE_SIZE,8,None};
 int n=0;GLXFBConfig *cfg=glXChooseFBConfig(d,DefaultScreen(d),attrs,&n);
 if(!cfg||!n)return 2;
 int pa[]={GLX_PBUFFER_WIDTH,32,GLX_PBUFFER_HEIGHT,32,None};
 GLXPbuffer pb=glXCreatePbuffer(d,cfg[0],pa);
 GLXContext c=glXCreateNewContext(d,cfg[0],GLX_RGBA_TYPE,0,True);
 if(!c||!pb||!glXMakeContextCurrent(d,pb,pb,c))return 3;
 const char *renderer=(const char*)glGetString(GL_RENDERER);
 printf("GLX direct=%d renderer=%s\n",glXIsDirect(d,c),renderer?renderer:"(null)");
 int ok=renderer&&strstr(renderer,"Lakefield")&&glXIsDirect(d,c);
 glXMakeContextCurrent(d,None,None,0);glXDestroyContext(d,c);glXDestroyPbuffer(d,pb);XFree(cfg);XCloseDisplay(d);
 return ok?0:4;
}
