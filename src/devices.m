/* ============================================================================
 * devices.m
 * author: nicholas cooley
 * maintainer: nicholas cooley
 *
 * general functions for device management
 * these functions represent the obj C layer of the interface between R and the
 * metal API
 * ========================================================================= */

// import is objC specific
#import <Metal/Metal.h>
#import <Foundation/Foundation.h>

// include can be used for straight C
#include "ACFmetal.h"

/* ============================================================================
 * GENERAL NOTES:
 * these notes will be retained until i am comfortable enough with obj C to not
 * need them
 * 
 * id == objC's builtin pointer type
 *
 * <MTLDevice> is a protocol constraint, i.e. <whatever> constrains the object
 * to objects that conform to <whatever>s protocol
 * <constraints> are compile time warnings only ... do not affect runtime
 *
 * object_type<constraint> name = way_to_create_it()
 * creates the object name with that type and checks the constraints
 * 
 * objC and swift use Automatic Reference Counting -- ARC, so object ownership
 * within objC has baked in ownership rules, object ownership exterior to objC
 * still requires some oversight
 * 
 * (__bridge_retained object_type)object_name
 * and
 * (__bridge_transfer object_type)object_name
 * are examples of bridge casting between ARC world and C's non-ARC world,
 * 'retained' casts to C and increments the retain count, when casting this way
 * CFRelease() must eventually be called to avoid memory leaks ... or worse?
 * 
 * 'transfer' works in the opposite direction, bringing an object from non-ARC
 * world in, decrementing the retain count and giving the object to ARC to
 * release when it believes it can
 *
 * (__bridge object_type)object_name alone just reinterprets the pointer and
 * can be used if the object can be discarded from all ownership spaces whnever
 * the ARC sees fit?
 * 
 * ObjC to C ... 
 * (__bridge) if the ObjC side will outlive the C side
 * (__bridge_retained) if the C side will outlive the ObjC side
 * 
 * C to ObjC
 * (__bridge) if the object was not previously retained, with CFRetain() or
 * something else, you will need to call CFRelease() on it, but keeping track
 * matters, calling CFRelease() on an object on an object that doesn't need it
 * will release the object too early
 * (__bridge_transfer) if you want to pass it to ARC and never worry about it
 * again?
 *
 * in objc 'id' is always explicitly a pointer!
 *
 * function return value == void, early exit  == return;
 * function return value == pointer, early exit == return NULL;
 * function return value == int/numeric, early exit == return 0; or return -1;
 * depending on the sentinel situation
 * function return value == SEXP, early exit == return R_NilValue;
 * for the R null object
 * ========================================================================= */

/* ============================================================================
 * SECTION: general device interrogation
 * ========================================================================= */

// get the default metal device
void* objc_metal_devices_default(void) {
  id<MTLDevice> device = MTLCreateSystemDefaultDevice();
  if (!device) {
    return NULL;
  }
  return (__bridge_retained void*)device;
}

// get all metal devices
// nothing that MTLCopyAllDevices() can be deterministically used to capture
// the default
void** objc_metal_get_all_devices(size_t* count) {
  if (!count) {
    return NULL;
  }
  
#if TARGET_OS_OSX
  NSArray<id<MTLDevice>>* devices = MTLCopyAllDevices();
#else
  // MTLCopyAllDevices() is not available on iOS/tvOS
  // fall back to single device
  id<MTLDevice> single = MTLCreateSystemDefaultDevice();
  NSArray<id<MTLDevice>>* devices = single ? @[single] : @[];
#endif
  
  if (!devices || [devices count] == 0) {
    *count = 0;
    return NULL;
  }
  
  *count = [devices count];
  
  void** device_array = (void**)malloc(*count * sizeof(void*));
  if (!device_array) {
    *count = 0;
    return NULL;
  }
  for (size_t i = 0; i < *count; i++) {
    device_array[i] = (__bridge_retained void*)devices[i];
  }
  return device_array;
}

/* ============================================================================
 * SECTION: general device information
 * ========================================================================= */

const char* metal_device_name(void* device) {
    if (!device) {
      return NULL;
    } else {
      // type<constraint> = (casting directive)existing_pointer
      id<MTLDevice> mtl_device = (__bridge id<MTLDevice>)device;
      // create a pointer to an NSString named name from the dot function of mtl.device
      NSString* name = mtl_device.name;
      // return the conversion of the NSString as a UTF8String
      // objc implicitly handles pointer dereferencing
      return [name UTF8String];
    }
}

uint64_t metal_device_registry_id(void* device) {
    if (!device) {
      return 0;
    } else {
      id<MTLDevice> mtl_device = (__bridge id<MTLDevice>)device;
      return mtl_device.registryID;
    }
}

int metal_device_has_unified_memory(void* device) {
    if (!device) {
      return 0;
    } else {
      id<MTLDevice> mtl_device = (__bridge id<MTLDevice>)device;
      return mtl_device.hasUnifiedMemory ? 1 : 0;
    }
}

int metal_device_is_low_power(void* device) {
    if (!device) {
      return 0;
    } else {
#if TARGET_OS_OSX
    id<MTLDevice> mtl_device = (__bridge id<MTLDevice>)device;
    return mtl_device.isLowPower ? 1 : 0;
#else
    return 0;
#endif
    }
}

int metal_device_is_headless(void* device) {
    if (!device) {
      return 0;
    }
#if TARGET_OS_OSX
    id<MTLDevice> mtl_device = (__bridge id<MTLDevice>)device;
    return mtl_device.isHeadless ? 1 : 0;
#else
    return 0;
#endif
}

int metal_device_is_removable(void* device) {
    if (!device) {
      return 0;
    }
#if TARGET_OS_OSX
    id<MTLDevice> mtl_device = (__bridge id<MTLDevice>)device;
    return mtl_device.isRemovable ? 1 : 0;
#else
    return 0;
#endif
}

/* ============================================================================
 * SECTION: memory limits
 * ========================================================================= */

uint64_t metal_device_recommended_max_working_set_size(void* device) {
    if (!device) {
      return 0;
    }
    id<MTLDevice> mtl_device = (__bridge id<MTLDevice>)device;
    return mtl_device.recommendedMaxWorkingSetSize;
}

uint64_t metal_device_max_buffer_length(void* device) {
    if (!device) {
      return 0;
    }
    id<MTLDevice> mtl_device = (__bridge id<MTLDevice>)device;
    return mtl_device.maxBufferLength;
}

uint64_t metal_device_current_allocated_size(void* device) {
    if (!device) {
      return 0;
    }
    id<MTLDevice> mtl_device = (__bridge id<MTLDevice>)device;
    return mtl_device.currentAllocatedSize;
}

/* ============================================================================
 * SECTION: threading limits
 * ========================================================================= */

/* ============================================================================
 * NOTE: writing to values through reference ...
 * 
 * MTLSize is a struct with width, height, depth components
 * it cannot be returned directly to C so we unpack it into three size_t
 * values via pointers
 * i.e: C side would look like:
 * size_t width = 0;
 * size_t height = 0;
 * size_t depth = 0;
 * metal_device_max_threads_per_threadgroup(device, &width, &height, &depth);
 * ========================================================================= */

void metal_device_max_threads_per_threadgroup(void* device,
                                              size_t* width,
                                              size_t* height,
                                              size_t* depth) {
    if (!device || !width || !height || !depth) {
        if (width)  *width  = 0;
        if (height) *height = 0;
        if (depth)  *depth  = 0;
        return;
    }
    id<MTLDevice> mtl_device = (__bridge id<MTLDevice>)device;
    MTLSize max_threads = mtl_device.maxThreadsPerThreadgroup;
    *width  = max_threads.width;
    *height = max_threads.height;
    *depth  = max_threads.depth;
}

size_t metal_device_max_threadgroup_memory_length(void* device) {
    if (!device) {
      return 0;
    }
    id<MTLDevice> mtl_device = (__bridge id<MTLDevice>)device;
    return mtl_device.maxThreadgroupMemoryLength;
}

/* ============================================================================
 * SECTION: performance monitoring
 * ========================================================================= */

/* ============================================================================
 * NOTE: writing to values through reference ...
 * 
 * uint64_t cpu_ts = 0;
 * uint64_t gpu_ts = 0;
 * metal_device_sample_timestamps(device, &cpu_ts, &gpu_ts);
 * cpu_ts and gpu_ts now contain the values
 *
 * sampleTimestamps returns two values by pointer -- cpu and gpu timestamps
 * both are uint64_t, paired samples taken at the same moment
 * useful for correlating CPU and GPU timelines
 * ========================================================================= */

void metal_device_sample_timestamps(void* device,
                                    uint64_t* cpu_timestamp,
                                    uint64_t* gpu_timestamp) {
    if (!device || !cpu_timestamp || !gpu_timestamp) {
        if (cpu_timestamp) *cpu_timestamp = 0;
        if (gpu_timestamp) *gpu_timestamp = 0;
        return;
    }
    id<MTLDevice> mtl_device = (__bridge id<MTLDevice>)device;
    MTLTimestamp cpu_ts = 0;
    MTLTimestamp gpu_ts = 0;
    [mtl_device sampleTimestamps:&cpu_ts gpuTimestamp:&gpu_ts];
    *cpu_timestamp = (uint64_t)cpu_ts;
    *gpu_timestamp = (uint64_t)gpu_ts;
}

// whether the device supports timestamp queries at all
// not all devices support counter sets
int metal_device_supports_counter_sampling(void* device,
                                           int sampling_point) {
    if (!device) {
      return 0;
    }
    id<MTLDevice> mtl_device = (__bridge id<MTLDevice>)device;
    return [mtl_device supportsCounterSampling:(MTLCounterSamplingPoint)sampling_point] ? 1 : 0;
}

/* ============================================================================
 * SECTION: physical slot information
 * macOS only -- external GPU topology
 * it is likely that these will need to adjusted for non-OSX
 * platforms eventually ¯\_(ツ)_/¯
 * ========================================================================= */

#if TARGET_OS_OSX

// location is an MTLDeviceLocation enum
// 0 == built-in, 1 == slot, 2 == external, 3 == unspecified
int metal_device_location(void* device) {
    if (!device) {
      return -1;
    }
    id<MTLDevice> mtl_device = (__bridge id<MTLDevice>)device;
    return (int)mtl_device.location;
}

// locationNumber is the slot index for devices in MTLDeviceLocationSlot
// only meaningful when location == 1 (slot)
uint64_t metal_device_location_number(void* device) {
    if (!device) {
      return 0;
    }
    id<MTLDevice> mtl_device = (__bridge id<MTLDevice>)device;
    return (uint64_t)mtl_device.locationNumber;
}

// peerGroupID and peerIndex are relevant when multiple GPUs
// are connected via peer-to-peer fabric (e.g. AMD Pro MPX modules)
// peerGroupID == 0 means the device is not part of a peer group
uint64_t metal_device_peer_group_id(void* device) {
    if (!device) {
      return 0;
    }
    id<MTLDevice> mtl_device = (__bridge id<MTLDevice>)device;
    return (uint64_t)mtl_device.peerGroupID;
}

uint32_t metal_device_peer_index(void* device) {
    if (!device) {
      return 0;
    }
    id<MTLDevice> mtl_device = (__bridge id<MTLDevice>)device;
    return (uint32_t)mtl_device.peerIndex;
}

uint32_t metal_device_peer_count(void* device) {
    if (!device) {
      return 0;
    }
    id<MTLDevice> mtl_device = (__bridge id<MTLDevice>)device;
    return (uint32_t)mtl_device.peerCount;
}

#endif /* TARGET_OS_OSX */

