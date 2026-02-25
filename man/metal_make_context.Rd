\name{metal_make_context}
\alias{metal_make_context}
\title{Device and Queue bundling}
\description{
  Bundle the pointers for a Metal \code{MTLdevice} and a Metal \code{MTLcommandQueue}
}
\usage{
  metal_make_context(device_ptr)
}
\arguments{
  \item{device_ptr}{
    An \code{externalptr} for a Metal device.
  }
}
\value{
  A list containing the input pointer in the first position, and a pointer to a Metal \code{MTLcommandQueue} in the second position.
}
\details{
  Given a valid pointer to a Metal device, return a list containing the pointer to that Metal device, and a pointer to the queue that Metal creates for that device. The device pointer and the queue pointer have similar instantiation lifetimes, so storing them together in a list is performed for convenience.
}
\examples{

tmp01 <- metal_devices_default()
tmp02 <- tmp01[[1]]

res <- metal_make_context(device_ptr = tmp02)
}
\seealso{
  \itemize{
    \item{\code{\link{metal_get_all_devices}}}
    \item{\code{\link{metal_devices_default}}}
  }
}