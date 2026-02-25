/* ============================================================================
 * libraries_functions_pipelines.c
 * author: nicholas cooley
 * maintainer: nicholas cooley
 *
 * C functions for libraries, metal functions, and pipelines
 * ========================================================================= */

#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include "ACFmetal.h"

SEXP metal_get_library_pointer(SEXP filepath,
                               SEXP device_ptr) {
  
  void* device_pointer = R_ExternalPtrAddr(device_ptr);
  if (!device_pointer) {
    Rf_error("invalid device pointer");
  }
  const char* lib_path = CHAR(STRING_ELT(filepath, 0));
  char* error_msg = NULL;
  
  void* lib_ptr = metal_load_library(device_pointer,
                                     lib_path,
                                     &error_msg);
  if (!lib_ptr) {
    if (error_msg) {
      char msg[512];
      strncpy(msg, error_msg, sizeof(msg) - 1);
      msg[sizeof(msg) - 1] = '\0';
      free(error_msg);
      Rf_error("failed to load library: %s", msg);
    }
    Rf_error("failed to load library: unknown error");
  }
  
  SEXP result = PROTECT(R_MakeExternalPtr(lib_ptr, R_NilValue, R_NilValue));
  R_RegisterCFinalizer(result, metal_library_finalizer);
  UNPROTECT(1);
  return result;
}

SEXP metal_get_function_pointers(SEXP lib_ptr,
                                 SEXP fun_names) {
  
  // standard pointer re-framing from R back into C
  void* library_pointer = R_ExternalPtrAddr(lib_ptr);
  if (!library_pointer) {
    Rf_error("invalid library pointer");
  }
  
  if (TYPEOF(fun_names) != STRSXP) {
    Rf_error("fun_names must be a character vector");
  }
  int n = LENGTH(fun_names);
  if (n == 0) {
    Rf_error("fun_names must have length > 0");
  }
  SEXP result = PROTECT(allocVector(VECSXP, n));
  
  int i;
  for (i = 0; i < n; i++) {
    const char* current_name = CHAR(STRING_ELT(fun_names, i));
    char* error_msg = NULL;
    
    void* function_pointer = metal_get_function_from_library(library_pointer,
                                                             current_name,
                                                             &error_msg);
    if (!function_pointer) {
      UNPROTECT(1);
      if (error_msg) {
        char msg[512];
        strncpy(msg, error_msg, sizeof(msg) - 1);
        msg[sizeof(msg) - 1] = '\0';
        free(error_msg);
        Rf_error("failed to get function '%s': %s", current_name, msg);
      }
      Rf_error("failed to get function '%s': unknown error", current_name);
    }
    
    SEXP ptr_res = PROTECT(R_MakeExternalPtr(function_pointer, R_NilValue, R_NilValue));
    R_RegisterCFinalizer(ptr_res, objc_inclusive_finalizer);
    SET_VECTOR_ELT(result, i, ptr_res);
    UNPROTECT(1);
  }
  
  UNPROTECT(1);
  return result;
}


