% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/skeleton.R
\name{datapackage_skeleton}
\alias{datapackage_skeleton}
\title{Create a Data Package skeleton for use with DataPackageR.}
\usage{
datapackage_skeleton(
  name = NULL,
  path = ".",
  force = FALSE,
  code_files = character(),
  r_object_names = character(),
  raw_data_dir = character(),
  dependencies = character()
)
}
\arguments{
\item{name}{\code{character} name of the package to create.}

\item{path}{A \code{character} path where the package is located. See \code{\link[utils]{package.skeleton}}}

\item{force}{\code{logical} Force the package skeleton to be recreated even if it exists. see \code{\link[utils]{package.skeleton}}}

\item{code_files}{Optional \code{character} vector of paths to Rmd files that process raw data
into R objects.}

\item{r_object_names}{\code{vector} of quoted r object names , tables, etc. created when the files in \code{code_files} are run.}

\item{raw_data_dir}{\code{character} pointing to a raw data directory. Will be moved with all its subdirectories to "inst/extdata"}

\item{dependencies}{\code{vector} of \code{character}, paths to R files that will be moved to "data-raw" but not included in the yaml config file. e.g., dependency scripts.}
}
\value{
No return value, called for side effects
}
\description{
Creates a package skeleton directory structure for use with DataPackageR.
Adds the DataVersion string to DESCRIPTION, creates the DATADIGEST file, and the data-raw directory.
Updates the Read-and-delete-me file to reflect the additional necessary steps.
}
\examples{
if(rmarkdown::pandoc_available()){
f <- tempdir()
f <- file.path(f,"foo.Rmd")
con <- file(f)
writeLines("```{r}\n tbl = data.frame(1:10) \n```\n",con=con)
close(con)
pname <- basename(tempfile())
datapackage_skeleton(name = pname,
   path = tempdir(),
   force = TRUE,
   r_object_names = "tbl",
   code_files = f)
   }
}
