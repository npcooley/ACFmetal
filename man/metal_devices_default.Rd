\name{metal_devices_default}
\alias{metal_devices_default}
\title{Metal Default Device Information}
\description{
Return information on the default metal Device.
}
\usage{
metal_devices_default()
}
\value{
A list containing information on the default Metal device.
}
\details{
A helper function for finding information about the default Metal device.
}
\examples{
res <- metal_devices_default()
}
\seealso{
\code{\link{metal_is_available}}, \code{\link{metal_get_all_devices}}
}