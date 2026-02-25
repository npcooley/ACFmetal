\name{metal_device_information}
\alias{metal_device_information}
\title{Metal Default Device Information}
\description{
Return information on the default metal Device.
}
\usage{
metal_device_information(device_ptr)
}
\arguments{
  \item{device_ptr}{
    A pointer to a container of device information.
  }
}
\value{
A list containing attributes of the indicated Metal device.
}
\details{
A helper function for finding information about the default Metal device.
}
\examples{
dft_dvc <- metal_devices_default()

# both metal device queries return a list, default returns a list of length 1
res <- metal_device_information(device_ptr = dft_dvc[[1]])
}
\seealso{
  \itemize{
    \item \code{\link{metal_is_available}}
    \item \code{\link{metal_get_all_devices}}
    \item \code{\link{metal_device_information}}
  }
}