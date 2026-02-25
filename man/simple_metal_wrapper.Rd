\name{simple_metal_wrapper}
\alias{simple_metal_wrapper}
\title{Execute a Metal Kernel}
\description{
  Run a Metal function on a Metal device. This function requires every argument present in the kernel function declaration to have an R representative passed to the \code{ellipses}. Order must be preserved. This function assumes that the first argument passed to the kernel is the (or a dummy version of the) output buffer.
}
\usage{
  simple_metal_wrapper(metal_context,
                       fun_ptr,
                       arg_types,
                       ...)
}
\arguments{
  \item{metal_context}{
    A \code{metalContext} object created by \code{\link{metal_make_context}}. A container for pointers for the Metal device and commandQueue.
  }
  \item{fun_ptr}{
    An \code{Externalptr} for a kernel function returned by \code{\link{metal_functions_from_library}}.
  }
  \item{arg_types}{
    A character vector serving as a key for the Metal types each argument passed to the ellipses must be converted to.
  }
  \item{...}{
    Vectors matching the arguments required by the kernel function declaration.
  }
}
\value{
  A vector type matching the dummy input vector's type.
}
\details{
  An example execution function, thematically similar to oclRun in the OpenCL package. This R function serves as a wrapper for the C function \code{metal_simple_runner}, which itself is a wrapper for an Objective C function \code{create_and_commit_commandbuffer}.
  
  The arguments passed to the \code{ellipses} need to match the order that they're declared in the kernel function.}
\examples{
tmp01 <- tempfile(fileext = ".metal")
y <- "
// Vector addition: out[i] = a[i] + b[i]
// Buffer layout:
// buffer(0) = output
// buffer(1) = output_length
// buffer(2+) = inputs

kernel void vector_add(
    device float* out [[buffer(0)]],
    constant uint& n [[buffer(1)]],
    device const float* a [[buffer(2)]],
    device const float* b [[buffer(3)]],
    uint id [[thread_position_in_grid]])
{
    if (id < n) {
        out[id] = a[id] + b[id];
    }
}
"
writeLines(text = y,
           con = tmp01)
tmp02 <- tempfile()

tmp03 <- metal_functions_to_library(metal_files = tmp01,
                                    library_file = tmp02,
                                    verbose = TRUE)
tmp04 <- metal_devices_default()
tmp05 <- metal_functions_from_library(library_filepath = tmp02,
                                      device_ptr = tmp04[[1]],
                                      fun_names = "vector_add")

tmp06 <- metal_make_context(device_ptr = tmp04[[1]])

set.seed(1986)
n <- 100L
val01 <- vector(mode = "numeric",
                length = n)
val02 <- runif(n)
val03 <- runif(n)

res <- simple_metal_wrapper(metal_context = tmp06,
                            fun_ptr = tmp05[[1]],
                            arg_types = c("float", 
                                          "uint",
                                          "float",
                                          "float"),
                            val01,
                            n,
                            val02,
                            val03)
}
\seealso{
  \itemize{
    \item \code{\link{metal_functions_from_library}}
    \item \code{\link{metal_make_context}}
    \item \code{\link{metal_devices_default}}
  }
}
