/* SPDX-License-Identifier: MIT */
#include <va/va.h>
#include <va/va_drm.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
int main(int argc,char **argv) {
 if(argc!=2)return 2;
 int fd=open(argv[1],O_RDWR|O_CLOEXEC);if(fd<0){perror("render node");return 1;}
 VADisplay d=vaGetDisplayDRM(fd);int major=0,minor=0;
 if(!d||vaInitialize(d,&major,&minor)!=VA_STATUS_SUCCESS)return 1;
 const char *vendor=vaQueryVendorString(d);printf("VA-API %d.%d: %s\n",major,minor,vendor?vendor:"unknown");
 int max=vaMaxNumProfiles(d),count=0,found=0;VAProfile *p=calloc((size_t)max,sizeof(*p));
 if(!p||vaQueryConfigProfiles(d,p,&count)!=VA_STATUS_SUCCESS)return 1;
 for(int i=0;i<count;i++)if(p[i]==VAProfileH264High)found=1;
 if(!found)return 1;
 VAConfigID config;VASurfaceID surface;
 if(vaCreateConfig(d,VAProfileH264High,VAEntrypointVLD,NULL,0,&config)!=VA_STATUS_SUCCESS)return 1;
 if(vaCreateSurfaces(d,VA_RT_FORMAT_YUV420,1920,1080,&surface,1,NULL,0)!=VA_STATUS_SUCCESS)return 1;
 printf("H264 High decode config + GPU surface 1920x1080: OK\n");
 vaDestroySurfaces(d,&surface,1);vaDestroyConfig(d,config);vaTerminate(d);free(p);close(fd);return 0;
}
