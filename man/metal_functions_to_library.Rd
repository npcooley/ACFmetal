\name{metal_functions_to_library}
\alias{metal_functions_to_library}
\title{Simple Metal Library Compilation}
\description{
  Compile one or more .metal files containing functions into a single library.
}
\usage{
  metal_functions_to_library(metal_files,
                             library_file,
                             verbose = FALSE)
}
\arguments{
  \item{metal_files}{
    A character vector of length 1 of the absolute paths to Metal compliant (extension included) kernel files.
  }
  \item{library_file}{
    A character vector of length 1 of the absolute path for the metallib file to create. File extension is not automatically appended.
  }
  \item{verbose}{
    A logical that is \code{FALSE} by default to print out messages during compilation.
  }
}
\value{
  Invisibly returns a matrix of information of about the kernel(s) supplied to \code{kernel_files}.
}
\details{
  A lightweight wrapper for \code{xcrun} commands for kernel compilation and library information.
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

res <- metal_functions_to_library(metal_files = tmp01,
                                  library_file = tmp02,
                                  verbose = TRUE)
}
\seealso{
  \itemize{
    \item{\code{\link{metal_is_available}}}
    \item{\code{\link{metal_get_all_devices}}}
    \item{\code{\link{metal_devices_default}}}
  }
}