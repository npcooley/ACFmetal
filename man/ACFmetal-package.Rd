\name{ACFmetal-package}
\alias{ACFmetal-package}
\alias{ACFmetal}
\docType{package}
\title{
  Infrastructure for calling Apple's Metal Framework from R
}
\description{
  ACFmetal provides simple accessors for incorporating Metal accelerated mathematical operations into larger R code bases.
}
\details{
  \tabular{ll}{
    Package: \tab ACFMetal\cr
    Type: \tab Package\cr
    Version: \tab 0.0.1\cr
    License: \tab MIT\cr
  }

  Index:
  \preformatted{
    metal_device_information        Helper function to return information about a Metal device
    metal_devices_default           Helper function to return all available Metal devices
    metal_functions_from_library    Get \code{externalptr}s for functions from a compiled \code{.metallib} file
    metal_functions_to_library      Compile metal functions into a \code{.metallib} file
    metal_get_all_devices           Helper function to return the default Metal device
    metal_is_available              Helper function for determining Metal availability
    metal_make_context              Bundle a device pointer and queue pointer into a single convenience object
    simple_metal_wrapper            A simple R wrapper around a simple metal function execution workflow
  }
  This package attempts to provide simple bindings to Apple's Metal Framework API.

  Performance benefits for most adhoc examples are going to be unimpressive as the data transfer overhead for most tasks is non-trivial. However, some tasks, particularly matrix multiplication or complex compute pipelines can see considerable performance improvements.
}
\author{
  Nicholas Cooley
}
\references{
  Apple Metal Framework: https://developer.apple.com/metal/

  Metal Performance Shaders: https://developer.apple.com/documentation/metalperformanceshaders
}
\keyword{package}
