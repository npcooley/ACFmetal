/* ============================================================================
 * buffers.c
 * author: nicholas cooley
 * maintainer: nicholas cooley
 *
 * C functions for accessing and using metal buffers
 * ========================================================================= */

#include <Rinternals.h>
#include <string.h>
#include <stdlib.h>
#include "ACFmetal.h"

/* ============================================================================
 * SECTION: conversions
 * ========================================================================= */

// convert R numerics to buffer by type
void metal_convert_r_numeric_to_buffer(const double* r_data,
                                       void* metal_buffer,
                                       size_t length,
                                       MetalType type) {
  switch (type) {
  // half is not implemented currently
  //case METAL_TYPE_HALF: {
  //  metal_convert_double_to_half(r_data, metal_buffer, length);
  //  break;
  //}
  case METAL_TYPE_FLOAT: {
    float* buf = (float*)metal_buffer;
    for (size_t i = 0; i < length; i++) {
      buf[i] = (float)r_data[i];
    }
    break;
  }
  case METAL_TYPE_DOUBLE: {
    memcpy(metal_buffer, r_data, length * sizeof(double));
    break;
  }
  case METAL_TYPE_INT8: {
    int8_t* buf = (int8_t*)metal_buffer;
    for (size_t i = 0; i < length; i++) {
      buf[i] = (int8_t)r_data[i];
    }
    break;
  }
  case METAL_TYPE_UINT8: {
    uint8_t* buf = (uint8_t*)metal_buffer;
    for (size_t i = 0; i < length; i++) {
      buf[i] = (uint8_t)r_data[i];
    }
    break;
  }
  case METAL_TYPE_INT16: {
    int16_t* buf = (int16_t*)metal_buffer;
    for (size_t i = 0; i < length; i++) {
      buf[i] = (int16_t)r_data[i];
    }
    break;
  }
  case METAL_TYPE_UINT16: {
    uint16_t* buf = (uint16_t*)metal_buffer;
    for (size_t i = 0; i < length; i++) {
      buf[i] = (uint16_t)r_data[i];
    }
    break;
  }
  case METAL_TYPE_INT: {
    int* buf = (int*)metal_buffer;
    for (size_t i = 0; i < length; i++) {
      buf[i] = (int)r_data[i];
    }
    break;
  }
  case METAL_TYPE_UINT: {
    unsigned int* buf = (unsigned int*)metal_buffer;
    for (size_t i = 0; i < length; i++) {
      buf[i] = (unsigned int)r_data[i];
    }
    break;
  }
  case METAL_TYPE_INT64: {
    int64_t* buf = (int64_t*)metal_buffer;
    for (size_t i = 0; i < length; i++) {
      buf[i] = (int64_t)r_data[i];
    }
    break;
  }
  case METAL_TYPE_UINT64: {
    uint64_t* buf = (uint64_t*)metal_buffer;
    for (size_t i = 0; i < length; i++) {
      buf[i] = (uint64_t)r_data[i];
    }
    break;
  }
  }
}

// convert r integers to metal buffers
void metal_convert_r_int_to_buffer(const int* r_data,
                                   void* metal_buffer,
                                   size_t length,
                                   MetalType type) {
  // For integer input, convert through doubles for simplicity
  // (could optimize by direct conversion for integer types)
  double* temp = (double*)malloc(length * sizeof(double));
  if (!temp) {
    Rf_error("Failed to allocate temporary buffer for integer conversion");
  }
  
  for (size_t i = 0; i < length; i++) {
    temp[i] = (double)r_data[i];
  }
  
  metal_convert_r_numeric_to_buffer(temp, metal_buffer, length, type);
  free(temp);
}

// convert a buffer back to an R vector
void metal_convert_buffer_to_r(const void* metal_buffer,
                               double* r_data,
                               size_t length,
                               MetalType type) {
  switch (type) {
  // half is not implemented
  //case METAL_TYPE_HALF: {
  //  metal_convert_half_to_double(metal_buffer, r_data, length);
  //  break;
  //}
  case METAL_TYPE_FLOAT: {
    const float* buf = (const float*)metal_buffer;
    for (size_t i = 0; i < length; i++) {
      r_data[i] = (double)buf[i];
    }
    break;
  }
  case METAL_TYPE_DOUBLE: {
    memcpy(r_data, metal_buffer, length * sizeof(double));
    break;
  }
  case METAL_TYPE_INT8: {
    const int8_t* buf = (const int8_t*)metal_buffer;
    for (size_t i = 0; i < length; i++) {
      r_data[i] = (double)buf[i];
    }
    break;
  }
  case METAL_TYPE_UINT8: {
    const uint8_t* buf = (const uint8_t*)metal_buffer;
    for (size_t i = 0; i < length; i++) {
      r_data[i] = (double)buf[i];
    }
    break;
  }
  case METAL_TYPE_INT16: {
    const int16_t* buf = (const int16_t*)metal_buffer;
    for (size_t i = 0; i < length; i++) {
      r_data[i] = (double)buf[i];
    }
    break;
  }
  case METAL_TYPE_UINT16: {
    const uint16_t* buf = (const uint16_t*)metal_buffer;
    for (size_t i = 0; i < length; i++) {
      r_data[i] = (double)buf[i];
    }
    break;
  }
  case METAL_TYPE_INT: {
    const int* buf = (const int*)metal_buffer;
    for (size_t i = 0; i < length; i++) {
      r_data[i] = (double)buf[i];
    }
    break;
  }
  case METAL_TYPE_UINT: {
    const unsigned int* buf = (const unsigned int*)metal_buffer;
    for (size_t i = 0; i < length; i++) {
      r_data[i] = (double)buf[i];
    }
    break;
  }
  case METAL_TYPE_INT64: {
    const int64_t* buf = (const int64_t*)metal_buffer;
    for (size_t i = 0; i < length; i++) {
      r_data[i] = (double)buf[i];
    }
    break;
  }
  case METAL_TYPE_UINT64: {
    const uint64_t* buf = (const uint64_t*)metal_buffer;
    for (size_t i = 0; i < length; i++) {
      r_data[i] = (double)buf[i];
    }
    break;
  }
  }
}

