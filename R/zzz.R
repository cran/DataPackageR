.onLoad <- function(libname, pkgname) {
  # keeping this first option hardcoded on load for now
  options("DataPackageR_packagebuilding" = FALSE)
  options("DataPackageR_verbose" = TRUE)
  # respect previous user setting for 'DataPackageR_interact' if set
  op <- options()
  op.DataPackageR <- list(
    DataPackageR_interact = interactive()
  )
  toset <- !(names(op.DataPackageR) %in% names(op))
  if (any(toset)) options(op.DataPackageR[toset])
  invisible()
}