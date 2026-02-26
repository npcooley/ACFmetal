Alternative Compute Framework: Metal 0.0.1
================
Nicholas Cooley
2026-02-26

- [Introduction](#introduction)
  - [Brief Metal API introduction](#brief-metal-api-introduction)
  - [General design philosophy](#general-design-philosophy)
- [Example](#example)
  - [Package startup](#package-startup)
  - [Device discovery](#device-discovery)
  - [Library, kernel function, and context
    management](#library-kernel-function-and-context-management)
  - [Function execution](#function-execution)
  - [GPU performance](#gpu-performance)

**Infrastructure for calling Apple’s Metal framework from R**

# Introduction

Metal is [Apple’s builtin framework for GPU
compute](https://developer.apple.com/documentation/metal?language=objc),
similar to CUDA (NVIDIA), or OpenCL (cross-platform). It can give us
access to the GPU side of Apple Silicon processors, and the discrete
GPUs present on some older Macs. The Metal API is accessible through
ObjC, meaning that access through R will require a mix of C and ObjC.
This package is currently still under construction.

## Brief Metal API introduction

A small list of Metal API objects in Objective C:

- **MTLDevice** - physical hardware. R level accessors in `ACFmetal`
  expose API access to available devices for information, and
  construction of compute pipelines.
- **MTLCommandQueue** — the persistent submission channel to the device.
  A communication route to the device
- **MTLLibrary** — a compiled collection of functions loaded from a
  .metallib file. A container, not executable by itself.
- **MTLFunction** — a single named kernel function extracted from a
  library.
- **MTLComputePipelineState** — the compiled, GPU-executable form of a
  function. Created with an **MTLFunction**, after which the
  **MTLFunction** can be released.
- **MTLCommandBuffer** — a transient container for encoded GPU work.
  Created per dispatch, committed, waited on, discarded.
- **MTLComputeCommandEncoder** — the object used to bind a pipeline and
  its arguments inside a command buffer.
- **MTLBuffer** — memory shared between CPU and GPU. Container for data.

## General design philosophy

`ACFmetal` itself is relatively bare on R functions, with an emphasis of
providing C level functions that can be used to divert intensive compute
steps to non-CPU hardware. Library and function compilation, device
discovery, and context construction are exposed in R; while pipeline
construction and execution, commandbuffer assembly and transit, and
general buffer management are currently bundled into C level runner
functions. A simple R wrapper is present, but it’s almost solely
overhead checking to ensure argument compliance.

Users should expect to interact with Metal devices through R’s `.Call`
and `.External` tools, with an emphasis being placed on maintability and
reliability for the time being.

# Example

A brief code example for package usage is included below.

## Package startup

Being designed for Apple’s Metal API, this package is only supported on
macOS. `ACFmetal`’s package hooks specifically look for available Metal
devices through the Metal API, but `R`’s system level information can
also be used as another check for environment appropriateness.

``` r
library(microbenchmark)
if (Sys.info()["sysname"] == "Darwin") {
  library(ACFmetal)
} else {
  print("wrong OS")
}
# ACFmetal 0.0.1 - Metal GPU acceleration is available
```

## Device discovery

Both `metal_devices_default` and `metal_get_all_devices` return a list
of `Externalptr`s.

``` r
# get the default device only
devices01 <- metal_devices_default()
# get all devices
devices02 <- metal_get_all_devices()
```

## Library, kernel function, and context management

Some Metal objects are meant to be persistent, while others are
transient. ‘context’ in this case is more a term of convenience. The
pointer to the device and the pointer to the MTLCommandQueue are bundled
together because they are both generally persistent across compute
tasks. All other metal objects are transient and function execution
specific.

``` r
# write out a kernel function
metal_mm_naive <- '
kernel void metal_mm_naive(device float* output [[buffer(0)]],
                           constant uint& M [[buffer(1)]],
                           constant uint& K [[buffer(2)]],
                           constant uint& N [[buffer(3)]],
                           device const float* A [[buffer(4)]],
                           device const float* B [[buffer(5)]],
                           uint2 id [[thread_position_in_grid]])
{
    uint row = id.x;
    uint col = id.y;

    if (row < M && col < N) {
        float sum = 0.0f;
        for (uint k = 0; k < K; k++) {
            sum += A[row + k * M] * B[k + col * K];
        }
        output[row + col * M] = sum;
    }
}
'
# write out our kernel function to a temporary file
# and compile it to a library
tmp01 <- tempfile(fileext = ".metal")
writeLines(text = metal_mm_naive,
           con = tmp01)
tmp02 <- tempfile()
metal_functions_to_library(metal_files = tmp01,
                           library_file = tmp02)
# extract our function to a pointer that Metal API accessors can use
fun_ptr <- metal_functions_from_library(library_filepath = tmp02,
                                        device_ptr = devices01[[1]],
                                        fun_names = "metal_mm_naive")
# 'context' in this case is a container of the device pointer and a pointer to
# the command queue
metal_ctx <- metal_make_context(device_ptr = devices01[[1]])
```

## Function execution

`ACFmetal` currently only contains one runner function that wraps up
pipeline management, function execution, and buffer chaperoning into one
round-trip excursion to the GPU. This isn’t necessarily the most
efficient way to perform compute on devices with discrete on-board
memory, but it was the most straightforward place to start. In the
future, additional runner functions may provide a wider array of
function execution strategies, though no future R wrapper functions are
planned.

We can incorporate the direct C level function:

<details>

<summary>

<strong>Incorporate C level accessors into an R function</strong>
</summary>

``` r
# wrap the runner function
example_fun_01 <- function(metal_ctx,
                           metal_fun,
                           input1,
                           input2) {
  # get matrix dims
  dim1 <- nrow(input1)
  dim2 <- ncol(input2)
  
  dim3 <- nrow(input2)
  dim4 <- ncol(input2)
  
  if (dim2 != dim3) {
    stop("matrices must have a shared inner dimension")
  }
  output_template <- vector(mode = "numeric",
                            length = dim1 * dim4)
  arg_types = c("float", # buffer(0): output
                "uint", # buffer(1): M (scalar)
                "uint", # buffer(2): K (scalar)
                "uint", # buffer(3): N (scalar)
                "float", # buffer(4): A
                "float", # buffer(5): B
                "WORKDIMS")
  
  # 2D grid: one thread per output cell
  res <- .External("metal_simple_runner",
                   metal_ctx,
                   metal_fun,
                   arg_types,
                   output_template,
                   dim1, # input 1 unique dim
                   dim2, # shared inner dimension, could also be dim3
                   dim4, # input 2 unique dim
                   as.vector(input1),
                   as.vector(input2),
                   as.integer(c(dim1, dim4, 1L)),
                   PACKAGE = "ACFmetal")
  
  res <- matrix(data = res,
                nrow = dim1,
                ncol = dim4)
  
  return(res)
}
```

</details>

Or we can incorporate the generic wrapper function:

<details>

<summary>

<strong>Incorporating the example R wrapper into another R
function</strong>
</summary>

``` r
# wrap the wrapper function
example_fun_02 <- function(metal_ctx,
                           metal_fun,
                           input1,
                           input2) {
  
  # get matrix dims
  dim1 <- nrow(input1)
  dim2 <- ncol(input2)
  
  dim3 <- nrow(input2)
  dim4 <- ncol(input2)
  
  if (dim2 != dim3) {
    stop("matrices must have a shared inner dimension")
  }
  output_template <- vector(mode = "numeric",
                            length = dim1 * dim4)
  
  # 2D grid: one thread per output cell
  res <- simple_metal_wrapper(metal_context = metal_ctx,
                              fun_ptr = metal_fun,
                              arg_types = c("float", # buffer(0): output
                                            "uint", # buffer(1): M (scalar)
                                            "uint", # buffer(2): K (scalar)
                                            "uint", # buffer(3): N (scalar)
                                            "float", # buffer(4): A
                                            "float", # buffer(5): B
                                            "WORKDIMS"),
                              output_template,
                              dim1, # input 1 unique dim
                              dim2, # shared inner dimension, could also be dim3
                              dim4, # input 2 unique dim
                              as.vector(input1),
                              as.vector(input2),
                              as.integer(c(dim1, dim4, 1L)))
  
  res <- matrix(data = res,
                nrow = dim1,
                ncol = dim4)
  
  return(res)
}
```

</details>

## GPU performance

Use `microbenchmark` to get some performance benchmarks.

``` r
set.seed(1986)
dim_set <- c(100, 250, 500, 1000, 2500)
res_vals <- vector(mode = "list",
                   length = length(dim_set))
fun_vec <- c("internal",
             "fun01",
             "fun02")
for (a1 in seq_along(dim_set)) {
  dim_size <- dim_set[a1]
  var1 <- matrix(data = runif(dim_size^2),
                 nrow = dim_size,
                 ncol = dim_size)
  var2 <- matrix(data = runif(dim_size^2),
                 nrow = dim_size,
                 ncol = dim_size)
  
  # suppress the nanosecond timings warning...
  timing_res <- suppressMessages(microbenchmark("internal" = var1 %*% var2,
                                                "fun01" = example_fun_01(metal_ctx = metal_ctx,
                                                                         metal_fun = fun_ptr[[1]],
                                                                         input1 = var1,
                                                                         input2 = var2),
                                                "fun02" = example_fun_02(metal_ctx = metal_ctx,
                                                                         metal_fun = fun_ptr[[1]],
                                                                         input1 = var1,
                                                                         input2 = var2),
                                                times = 5))
  res_vals[[a1]] <- vapply(X = c("internal",
                                 "fun01",
                                 "fun02"),
                           FUN = function(x) {
                             mean(timing_res$time[timing_res$expr == x])
                           },
                           FUN.VALUE = vector(mode = "numeric",
                                              length = 1))
}
# Warning in microbenchmark(internal = var1 %*% var2, fun01 =
# example_fun_01(metal_ctx = metal_ctx, : less accurate nanosecond times to avoid
# potential integer overflows
res_vals <- do.call(rbind,
                    res_vals)
colset <- c("black",
              "red",
              "blue")

par(mar = c(3,2.5,2,1),
    mgp = c(1.45, .55, 0))
plot(x = 1e-100,
     y = 1e-100,
     xlim = range(dim_set),
     ylim = range(unlist(res_vals)),
     xlab = "dim size (log)",
     ylab = "nanoseconds (log)",
     type = "n",
     log = "xy",
     main = "Matrix Multiplication")

for (a1 in seq(ncol(res_vals))) {
  points(x = dim_set,
         y = res_vals[, a1],
         pch = 20,
         col = colset[a1],
         cex = 2)
}
legend("topleft",
       legend = c("internal",
                  "metal v1",
                  "metal v2"),
       col = colset,
       pch = 20,
       cex = 1.5)
```

![](README_files/figure-gfm/wrapper%20performance-1.png)<!-- -->
