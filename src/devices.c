/* ============================================================================
 * devices.c
 * author: nicholas cooley
 * maintainer: nicholas cooley
 * 
 * general functions for device management
 * these functions represent the C layer of the interface between R and the
 * metal API
 * ========================================================================= */

// general headers
#include <Rinternals.h>
#include <stdlib.h>

// for TARGET_OS_OSX macro
#include <TargetConditionals.h>

// local header
#include "ACFmetal.h"

/* ============================================================================
 * device discovery
 * 
 * nothing about the device information returned by MTLCopyAllDevices() can
 * be leveraged to identify the default device in every case, so comparisons to
 * MTLCreateSystemDefaultDevice() are required
 * ========================================================================= */

// call to objC layer for metal API call MTLCopyAllDevices()
SEXP c_metal_get_all_devices(void) {
  size_t count = 0;
  void** devices = objc_metal_get_all_devices(&count);
  
  if (!devices || count == 0) {
    return allocVector(VECSXP, 0);
  }
  
  SEXP result = PROTECT(allocVector(VECSXP, count));
  
  for (size_t i = 0; i < count; i++) {
    SEXP device_ptr = PROTECT(R_MakeExternalPtr(devices[i], R_NilValue, R_NilValue));
    R_RegisterCFinalizer(device_ptr, objc_inclusive_finalizer);
    SET_VECTOR_ELT(result, i, device_ptr);
    UNPROTECT(1);
  }
  
  free(devices);
  UNPROTECT(1);
  return result;
}

// call to objC layer for metal API call MTLCreateSystemDefaultDevice()
SEXP c_metal_devices_default(void) {
  
  // always returns a pointer (void*)
  // either the address for the object that obj-c cast to C
  // or
  // address zero for NULL
  void* device = objc_metal_devices_default();
  
  if (device) {
    // Create a list of length 1
    SEXP result = PROTECT(allocVector(VECSXP, 1));
    
    // Wrap the pointer into an external pointer
    SEXP device_ptr = PROTECT(R_MakeExternalPtr(device, R_NilValue, R_NilValue));
    R_RegisterCFinalizer(device_ptr, objc_inclusive_finalizer);
    
    // Put the external pointer in the list
    SET_VECTOR_ELT(result, 0, device_ptr);
    
    UNPROTECT(2);
    return result;
  } else {
    // Return an empty list
    return allocVector(VECSXP, 0);
  }
  
}

SEXP c_metal_device_information(SEXP device_ptr) {
  // bring the pointer from R into this function space
  void* device = R_ExternalPtrAddr(device_ptr);
  if (!device) {
    Rf_error("invalid device pointer");
  }
  
  // allocate the resulting list and names based on the TARGET_OS
  // not all queries are supported outside OSX, so this is mostly a formality
  // for now
#if TARGET_OS_OSX
  SEXP result = PROTECT(allocVector(VECSXP, 16));
  SEXP names  = PROTECT(allocVector(STRSXP, 16));
#else
  SEXP result = PROTECT(allocVector(VECSXP, 11));
  SEXP names  = PROTECT(allocVector(STRSXP, 11));
#endif
  
  // general information
  SET_STRING_ELT(names,  0, mkChar("name"));
  SET_VECTOR_ELT(result, 0, mkString(metal_device_name(device)));
  
  SET_STRING_ELT(names,  1, mkChar("registry_id"));
  SET_VECTOR_ELT(result, 1, ScalarReal((double)metal_device_registry_id(device)));
  
  SET_STRING_ELT(names,  2, mkChar("has_unified_memory"));
  SET_VECTOR_ELT(result, 2, ScalarLogical(metal_device_has_unified_memory(device)));
  
  SET_STRING_ELT(names,  3, mkChar("is_low_power"));
  SET_VECTOR_ELT(result, 3, ScalarLogical(metal_device_is_low_power(device)));
  
  SET_STRING_ELT(names,  4, mkChar("is_headless"));
  SET_VECTOR_ELT(result, 4, ScalarLogical(metal_device_is_headless(device)));
  
  SET_STRING_ELT(names,  5, mkChar("is_removable"));
  SET_VECTOR_ELT(result, 5, ScalarLogical(metal_device_is_removable(device)));
  
  // memory limits
  SET_STRING_ELT(names,  6, mkChar("recommended_max_working_set_size_bytes"));
  SET_VECTOR_ELT(result, 6, ScalarReal((double)metal_device_recommended_max_working_set_size(device)));
  
  SET_STRING_ELT(names,  7, mkChar("max_buffer_length_bytes"));
  SET_VECTOR_ELT(result, 7, ScalarReal((double)metal_device_max_buffer_length(device)));
  
  SET_STRING_ELT(names,  8, mkChar("current_allocated_size_bytes"));
  SET_VECTOR_ELT(result, 8, ScalarReal((double)metal_device_current_allocated_size(device)));
  
  // threading limits
  size_t width = 0;
  size_t height = 0;
  size_t depth = 0;
  metal_device_max_threads_per_threadgroup(device, &width, &height, &depth);
  
  SEXP threads = PROTECT(allocVector(INTSXP, 3));
  INTEGER(threads)[0] = (int)width;
  INTEGER(threads)[1] = (int)height;
  INTEGER(threads)[2] = (int)depth;
  
  SET_STRING_ELT(names,  9, mkChar("max_threads_per_threadgroup"));
  SET_VECTOR_ELT(result, 9, threads);
  UNPROTECT(1);
  
  SET_STRING_ELT(names,  10, mkChar("max_threadgroup_memory_length_bytes"));
  SET_VECTOR_ELT(result, 10, ScalarReal((double)metal_device_max_threadgroup_memory_length(device)));
  
#if TARGET_OS_OSX
  
  // physical slot information
  SET_STRING_ELT(names,  11, mkChar("location"));
  SET_VECTOR_ELT(result, 11, ScalarReal((double)metal_device_location(device)));
  
  SET_STRING_ELT(names,  12, mkChar("location_number"));
  SET_VECTOR_ELT(result, 12, ScalarReal((double)metal_device_location_number(device)));

  SET_STRING_ELT(names,  13, mkChar("peer_group_id"));
  SET_VECTOR_ELT(result, 13, ScalarReal((double)metal_device_peer_group_id(device)));
  
  SET_STRING_ELT(names,  14, mkChar("peer_index"));
  SET_VECTOR_ELT(result, 14, ScalarReal((double)metal_device_peer_index(device)));
  
  SET_STRING_ELT(names,  15, mkChar("peer_count"));
  SET_VECTOR_ELT(result, 15, ScalarReal((double)metal_device_peer_count(device)));
#endif

  // set the names and return the list
  setAttrib(result, R_NamesSymbol, names);
  UNPROTECT(2);
  return result;
}

