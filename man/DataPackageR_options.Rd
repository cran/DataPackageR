% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/DataPackageR-package.R
\name{DataPackageR_options}
\alias{DataPackageR_options}
\title{Options consulted by DataPackageR}
\description{
User-configurable options consulted by DataPackageR, which
  provide a mechanism for setting default behaviors for various functions.

  If the built-in defaults don't suit you, set one or more of these options.
  Typically, this is done in the \code{.Rprofile} startup file, which you can open
  for editing with \code{usethis::edit_r_profile()} - this will set the specified
  options for all future R sessions. The following setting is recommended to
  not be prompted upon each package build for a NEWS update:

\code{options(DataPackageR_interact = FALSE)}
}
\section{Options for the DataPackageR package}{


- \code{DataPackageR_interact}: Upon package load, this defaults to the value of
  \code{interactive()}, unless the option has been previously set (e.g., in
  \code{.Rprofile}). TRUE prompts user interactively for a NEWS update on
  \code{package_build()}. See the example above and the
  \href{https://ropensci.org/blog/2018/09/18/datapackager/}{rOpenSci blog
  post} for more details on how to set this to FALSE, which will never prompt
  user for a NEWS update. FALSE is also the setting used for DataPackageR
  internal package tests.

- \code{DataPackageR_verbose}: Default upon package load is TRUE. FALSE suppresses
  all console output and is currently only used for automated
  unit tests of the DataPackageR package.

- \code{DataPackageR_packagebuilding}: Default upon package load is FALSE. This
  option is used internally for package operations and changing it is not
  recommended.
}

