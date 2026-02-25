\name{metal_functions_from_library}
\alias{metal_functions_from_library}
\title{Simple Metal Function Access}
\description{
  Get pointers for one or more Metal functions from a compiled metal library.
}
\usage{
  metal_functions_from_library(library_filepath,
                               device_ptr,
                               fun_names)
}
\arguments{
  \item{library_filepath}{
    A character vector of length 1 of the absolute path to a Metal compliant \code{.metallib} file.
  }
  \item{device_ptr}{
    An \code{externalptr} for a Metal device.
  }
  \item{fun_names}{
    A character vector of function names for indicating which functions to extract pointers for.
  }
}
\value{
  A named list of \code{externalptr}s.
}
\details{
  Returns a named list of pointers for one or more Metal functions from a compiled metal library.
}
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
res <- metal_functions_from_library(library_filepath = tmp02,
                                    device_ptr = tmp04[[1]],
                                    fun_names = "vector_add")
}
\seealso{
  \itemize{
    \item{\code{\link{metal_is_available}}}
    \item{\code{\link{metal_get_all_devices}}}
    \item{\code{\link{metal_devices_default}}}
  }
}