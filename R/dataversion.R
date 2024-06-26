


#' Get the DataVersion for a package
#'
#' Retrieves the DataVersion of a package if available
#' @param pkg \code{character} the package name
#' @param lib.loc \code{character} path to library location.
#' @seealso \code{\link[utils]{packageVersion}}
#' @rdname data_version
#' @returns Object of class 'package_version' and 'numeric_version' specifying the DataVersion of the package
#' @export
#' @examples
#' if(rmarkdown::pandoc_available()){
#' f <- tempdir()
#' f <- file.path(f,"foo.Rmd")
#' con <- file(f)
#' writeLines("```{r}\n vec = 1:10 \n```\n",con=con)
#' close(con)
#' pname <- basename(tempfile())
#' datapackage_skeleton(name = pname,
#'    path=tempdir(),
#'    force = TRUE,
#'    r_object_names = "vec",
#'    code_files = f)
#'
#'    package_build(file.path(tempdir(),pname), install = FALSE)
#'
#'    pkgload::load_all(file.path(tempdir(),pname))
#'    data_version(pname)
#' }
data_version <- function(pkg, lib.loc = NULL) {
  res <- suppressWarnings(utils::packageDescription(pkg,
    lib.loc = lib.loc,
    fields = "DataVersion"
  ))
  if (!is.na(res)) {
    package_version(res)
  } else {
    stop(gettextf(
      paste0(
        "package %s not found ",
        "or has no DataVersion string"
      ),
      sQuote(pkg)
    ),
    domain = NA
    )
  }
}

.increment_data_version <-
  function(pkg_desc, new_data_digest, which = "patch") {
    which_options <- c("major", "minor", "patch")
    if (!which %in% which_options) {
      stop(
        paste0(
          "version component to increment",
          "is misspecified in ",
          ".increment_data_version, ",
          "package DataPackageR"
        )
      )
    }
    verstring <- validate_DataVersion(pkg_desc$get('DataVersion'))
    # convert back into package_version after validation
    # to be able to use base R subsetting facilities
    verstring <- as.package_version(verstring)
    m <- match(which, which_options)
    verstring[1, m] <- as.integer(verstring[1, m]) + 1L
    verstring <- validate_DataVersion(verstring)
    pkg_desc$set('DataVersion', verstring)
    new_data_digest[["DataVersion"]] <- verstring
    list(pkg_description = pkg_desc, new_data_digest = new_data_digest)
  }

#' Assert that a data version in a data package matches an expectation.
#'
#' @param data_package_name \code{character} Name of the package.
#' @param version_string \code{character} Version string in "x.y.z" format.
#' @param acceptable  \code{character} one of "equal", "equal_or_greater", describing what version match is acceptable.
#' @param ... additional arguments passed to data_version (such as lib.loc)
#' @details Tests the DataVersion string in \code{data_package_name} against \code{version_string} testing the major, minor and revision portion.
#' @return invisible \code{logical} TRUE if success, otherwise stop on mismatch.
#' @details
#' Tests "data_package_name version equal version_string" or "data_package_name version equal_or_greater version_string".
#' @export
#' @examples
#' if(rmarkdown::pandoc_available()){
#' f <- tempdir()
#' f <- file.path(f, "foo.Rmd")
#' con <- file(f)
#' writeLines("```{r}\n vec = 1:10 \n```\n",con = con)
#' close(con)
#' pname <- basename(tempfile())
#' datapackage_skeleton(name = pname,
#'    path=tempdir(),
#'    force = TRUE,
#'    r_object_names = "vec",
#'    code_files = f)
#' package_build(file.path(tempdir(),pname), install = FALSE)
#'
#' pkgload::load_all(file.path(tempdir(),pname))
#'
#' assert_data_version(data_package_name = pname,version_string = "0.1.0",acceptable = "equal")
#' }
assert_data_version <-
  function(data_package_name = NULL,
             version_string = NULL,
             acceptable = "equal",
           ...) {
    acceptable <- match.arg(acceptable, c("equal", "equal_or_greater"))
    pkg_version <- data_version(pkg = data_package_name,...)
    required_version <- as.numeric_version(version_string)
    base <-
      max(10, max(
        .find_base(pkg_version),
        .find_base(required_version)
      )) + 1
    if ((acceptable == "equal_or_greater") &
      (
        .mk_version_numeric(pkg_version, base = base) >=
          .mk_version_numeric(required_version, base = base)
      )) {
      invisible(TRUE)
    } else if ((acceptable == "equal") &
      (
        .mk_version_numeric(pkg_version, base = base) ==
          .mk_version_numeric(required_version, base = base)
      )) {
      invisible(TRUE)
    } else {
      stop(
        paste0(
          "Found ",
          data_package_name,
          " ",
          pkg_version,
          " but ",
          ifelse(acceptable == "equal", " == ", " >= "),
          required_version,
          " is required."
        )
      )
    }
  }

.find_base <- function(v) {
  max(
    as.numeric(v[1, 1]),
    as.numeric(v[1, 2]),
    as.numeric(v[1, 3])
  )
}

.mk_version_numeric <- function(x, base = 10) {
  as.numeric(x[1, 1]) * base^2 +
    as.numeric(x[1, 2]) * base^1 +
    as.numeric(x[1, 3]) * base^
      0
}
