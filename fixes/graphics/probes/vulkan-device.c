/* MIT: identify the real Intel GPU and submit/verify a Vulkan GPU buffer fill. */
#include <vulkan/vulkan.h>
#include <stdint.h>
#include <stdio.h>
#define CHECK(call) do { VkResult r=(call); if(r!=VK_SUCCESS){fprintf(stderr,"%s: %d\n",#call,r);return 1;} } while(0)
int main(void) {
 VkApplicationInfo ai={.sType=VK_STRUCTURE_TYPE_APPLICATION_INFO,.pApplicationName="Lakefield graphics validation",.apiVersion=VK_API_VERSION_1_1};
 VkInstanceCreateInfo ci={.sType=VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO,.pApplicationInfo=&ai};VkInstance instance;
 CHECK(vkCreateInstance(&ci,0,&instance));
 uint32_t count=16;VkPhysicalDevice devices[16];CHECK(vkEnumeratePhysicalDevices(instance,&count,devices));
 VkPhysicalDevice gpu=VK_NULL_HANDLE;
 for(uint32_t k=0;k<count;k++) {VkPhysicalDeviceProperties p;vkGetPhysicalDeviceProperties(devices[k],&p);printf("GPU %04x:%04x %s\n",p.vendorID,p.deviceID,p.deviceName);if(p.vendorID==0x8086&&p.deviceID==0x9840&&p.deviceType==VK_PHYSICAL_DEVICE_TYPE_INTEGRATED_GPU)gpu=devices[k];}
 if(!gpu){fputs("FAIL: Intel Lakefield hardware GPU unavailable\n",stderr);return 1;}
 VkQueueFamilyProperties q[32];uint32_t nq=32;vkGetPhysicalDeviceQueueFamilyProperties(gpu,&nq,q);uint32_t family=0;
 while(family<nq&&!(q[family].queueFlags&VK_QUEUE_GRAPHICS_BIT))family++;
 if(family==nq)return 2;
 float priority=1;VkDeviceQueueCreateInfo qi={.sType=VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,.queueFamilyIndex=family,.queueCount=1,.pQueuePriorities=&priority};
 VkDeviceCreateInfo di={.sType=VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO,.queueCreateInfoCount=1,.pQueueCreateInfos=&qi};VkDevice device;CHECK(vkCreateDevice(gpu,&di,0,&device));
 VkQueue queue;vkGetDeviceQueue(device,family,0,&queue);
 VkBufferCreateInfo bi={.sType=VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO,.size=4,.usage=VK_BUFFER_USAGE_TRANSFER_DST_BIT};VkBuffer buffer;CHECK(vkCreateBuffer(device,&bi,0,&buffer));
 VkMemoryRequirements req;vkGetBufferMemoryRequirements(device,buffer,&req);VkPhysicalDeviceMemoryProperties props;vkGetPhysicalDeviceMemoryProperties(gpu,&props);uint32_t type=0;
 while(type<props.memoryTypeCount&&(!(req.memoryTypeBits&(1u<<type))||((props.memoryTypes[type].propertyFlags&(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT|VK_MEMORY_PROPERTY_HOST_COHERENT_BIT))!=(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT|VK_MEMORY_PROPERTY_HOST_COHERENT_BIT))))type++;
 if(type==props.memoryTypeCount)return 3;
 VkMemoryAllocateInfo ma={.sType=VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO,.allocationSize=req.size,.memoryTypeIndex=type};VkDeviceMemory memory;CHECK(vkAllocateMemory(device,&ma,0,&memory));CHECK(vkBindBufferMemory(device,buffer,memory,0));
 uint32_t *mapped;CHECK(vkMapMemory(device,memory,0,req.size,0,(void**)&mapped));*mapped=0;
 VkCommandPoolCreateInfo pi={.sType=VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO,.queueFamilyIndex=family};VkCommandPool pool;CHECK(vkCreateCommandPool(device,&pi,0,&pool));
 VkCommandBufferAllocateInfo ca={.sType=VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO,.commandPool=pool,.level=VK_COMMAND_BUFFER_LEVEL_PRIMARY,.commandBufferCount=1};VkCommandBuffer command;CHECK(vkAllocateCommandBuffers(device,&ca,&command));
 VkCommandBufferBeginInfo begin={.sType=VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO};CHECK(vkBeginCommandBuffer(command,&begin));vkCmdFillBuffer(command,buffer,0,4,0x4c4b4632);
 VkMemoryBarrier barrier={.sType=VK_STRUCTURE_TYPE_MEMORY_BARRIER,.srcAccessMask=VK_ACCESS_TRANSFER_WRITE_BIT,.dstAccessMask=VK_ACCESS_HOST_READ_BIT};vkCmdPipelineBarrier(command,VK_PIPELINE_STAGE_TRANSFER_BIT,VK_PIPELINE_STAGE_HOST_BIT,0,1,&barrier,0,0,0,0);CHECK(vkEndCommandBuffer(command));
 VkSubmitInfo submit={.sType=VK_STRUCTURE_TYPE_SUBMIT_INFO,.commandBufferCount=1,.pCommandBuffers=&command};CHECK(vkQueueSubmit(queue,1,&submit,VK_NULL_HANDLE));CHECK(vkQueueWaitIdle(queue));
 int ok=*mapped==0x4c4b4632;printf("%s: Vulkan Intel GPU submission and memory result 0x%08x\n",ok?"PASS":"FAIL",*mapped);
 vkUnmapMemory(device,memory);vkDestroyCommandPool(device,pool,0);vkDestroyBuffer(device,buffer,0);vkFreeMemory(device,memory,0);vkDestroyDevice(device,0);vkDestroyInstance(instance,0);return ok?0:4;
}
