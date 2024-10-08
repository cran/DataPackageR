.validate_render_root <- function(x) {
  # catch an error if it doesn't exist, otherwise return normalized path
  # important for handling relative paths in a rmarkdown::render() context
  if (! dir.exists(x)){
    .multilog_error(paste0("render_root = ", x, " doesn't exist"))
    stop(paste0("render_root = ", x, " doesn't exist"))
  }
  normalizePath(x, winslash = "/")
  # old comments below have been retained:
  # try creating, even if it's an old temp dir.
  # This isn't ideal. Would like to rather say it's a temporary
  # directory and use the current one..
}


#' Process data generation code in 'data-raw'
#'
#' Assumes .R files in 'data-raw' generate rda files to be stored in 'data'.
#' Sources datasets.R which can source other R files.
#' R files sourced by datasets.R must invoke \code{sys.source('myRfile.R',env=topenv())}.
#' Meant to be called before R CMD build.
#' @name DataPackageR
#' @param arg \code{character} name of the package to build.
#' @param deps \code{logical} should scripts pass data objects to each other (default=TRUE)
#' @return logical TRUE if successful, FALSE, if not.
#' @importFrom desc desc
#' @importFrom rmarkdown render
#' @importFrom usethis proj_set proj_get
#' @noRd
DataPackageR <- function(arg = NULL, deps = TRUE) {
  if (! getOption('DataPackageR_verbose', TRUE)){
    old_usethis_quiet <- getOption('usethis.quiet')
    on.exit(options(usethis.quiet = old_usethis_quiet))
    options(usethis.quiet = TRUE)
  }
  pkg_dir <- arg
  if (getOption('DataPackageR_verbose', TRUE)) cat("\n")
  usethis::proj_set(path = pkg_dir)

  #set the option that DataPackageR is building the package. On exit ensures when it leaves, it will set it back to false
  options("DataPackageR_packagebuilding" = TRUE)
  on.exit(options("DataPackageR_packagebuilding" = FALSE), add = TRUE)

  # validate that render_root exists.
  # if it's an old temp dir, what then?

  logpath <- file.path(pkg_dir, "inst", "extdata", "Logfiles")
  dir.create(logpath, recursive = TRUE, showWarnings = FALSE)
  # open a log file
  LOGFILE <- file.path(logpath, "processing.log")
  .multilog_setup(LOGFILE)
  .multilog_thresold(console = INFO, logfile = TRACE)
  .multilog_trace(paste0("Logging to ", LOGFILE))
  # validate package
  validate_package_skeleton(pkg_dir)
  .multilog_trace("Processing data")
  # validate datapackager.yml
  ymlconf <- validate_yml(pkg_dir)
  # get vector of R and Rmd files from validated YAML
  r_files <- file.path(pkg_dir, 'data-raw', get_yml_r_files(ymlconf))
  objects_to_keep <- get_yml_objects(ymlconf)
  render_root <- .validate_render_root(.get_render_root(ymlconf))

  # The test for a valid DESCRIPTION here is no longer needed since
  # we use proj_set().

  # TODO Can we configure documentation in yaml?
  do_documentation <- FALSE
  # This flag indicates success
  can_write <- FALSE
  # environment for the data
  ENVS <- new.env(hash = TRUE, parent = .GlobalEnv)
  object_tally <- 0
  already_built <- NULL
  building <- NULL
  r_dir <- normalizePath(file.path(pkg_dir, "R" ), winslash = "/")
  r_dir_files <- list.files( r_dir )
  r_dir_files <- r_dir_files[ !grepl( validate_pkg_name(pkg_dir),
                                      r_dir_files ) ]
  for (i in seq_along(r_files)) {
    dataenv <- new.env(hash = TRUE, parent = .GlobalEnv)
    for( j in seq_along( r_dir_files ) ){
      curr_path <- normalizePath(file.path(pkg_dir,
                                           "R",
                                           r_dir_files[j] ),
                                 winslash = "/")
      source( curr_path,
              local = dataenv )
    }
    # assign ENVS into dataenv.
    # provide functions in the package to read from it (if deps = TRUE)
    if (deps) assign(x = "ENVS", value = ENVS, dataenv)
    .multilog_trace(paste0(
      "Processing ", i, " of ",
      length(r_files), ": ", r_files[i]
    ))
    # config file goes in the root render the r and rmd files
    ## First we spin then render if it's an R file
    flag <- FALSE
    .isRfile <- function(f) {
      grepl("\\.r$", tolower(f))
    }
    if (flag <- .isRfile(r_files[i])) {
      knitr::spin(r_files[i],
                  precious = TRUE,
                  knit = FALSE
      )
      r_files[i] <- paste0(tools::file_path_sans_ext(r_files[i]), ".Rmd")
      if (! file.exists(r_files[i])){
        stop(paste0("File: ", r_files[i], " does not exist!"))
      }
      lines <- readLines(r_files[i])
      # do we likely have a yaml header? If not, add one.
      if (lines[1] != "---") {
        lines <- c(
          "---",
          paste0("title: ", basename(r_files[i])),
          paste0("author: ", Sys.info()["user"]),
          paste0("date: ", Sys.Date()),
          "---",
          "",
          lines
        )
        con <- file(r_files[i])
        writeLines(lines, con = con, sep = "\n")
        close(con)
      }
    }
    rmarkdown::render(
      input = r_files[i], envir = dataenv,
      output_dir = logpath, clean = TRUE, knit_root_dir = render_root,
      quiet = TRUE
    )
    # The created objects
    object_names <- setdiff(ls(dataenv),
                            c("ENVS", already_built)) # ENVS is removed
    object_tally <- object_tally | objects_to_keep %in% object_names
    already_built <- unique(c(already_built,
                              objects_to_keep[objects_to_keep %in% object_names]))
    .multilog_trace(paste0(
      sum(objects_to_keep %in% object_names),
      " data set(s) created by ",
      basename(r_files[i])
    ))
    .done(paste0(
      sum(objects_to_keep %in% object_names),
      " data set(s) created by ",
      basename(r_files[i])
    ))
    if (sum(objects_to_keep %in% object_names) > 0) {
      .add_newlines_to_vector <- function(x) {
        x <- paste0(x, sep = "\n")
        x[length(x)] <- gsub("\n", "", x[length(x)])
        x
      }
      .bullet(
        .add_newlines_to_vector(
          objects_to_keep[which(objects_to_keep %in% object_names)]),
        cli::col_red("\u2022")
      )
    }
    .bullet(
      paste0(
        "Built ",
        ifelse(
          sum(object_tally) == length(object_tally),
          "all datasets!",
          paste0(sum(object_tally), " of ",
                 length(object_tally), " data sets.")
        )
      ),
      ifelse(
        sum(object_tally) == length(object_tally),
        cli::col_green("\u2618"),
        cli::col_green("\u2605")
      )
    )
    if (sum(objects_to_keep %in% object_names) > 0) {
      for (o in objects_to_keep[objects_to_keep %in% object_names]) {
        assign(o, get(o, dataenv), ENVS)
        # write the object to render_root
        o_instance <- get(o,dataenv)
        saveRDS(o_instance, file = paste0(file.path(render_root,o),".rds"),
                version = 2)
      }
    }
  }
  # currently environments for each file are independent.
  dataenv <- ENVS
  do_digests(pkg_dir, dataenv)
  do_doc(pkg_dir, dataenv)
  # copy html files to vignettes
  .ppfiles_mkvignettes(dir = pkg_dir)
  .multilog_trace("Done")
  return(TRUE)
}

#' Get R and Rmd files from YAML configuration
#'
#' @param ymlconf YAML configuration list produced by validate_yml()
#'
#' @return Character vector of enabled R and Rmd files specified in YAML file
#' @noRd
get_yml_r_files <- function(ymlconf) {
  r_files <- names(
    Filter(
      x = ymlconf[["configuration"]][["files"]],
      f = function(x) x$enabled
    )
  )
}

#' Get data objects from YAML configuration
#'
#' @param ymlconf YAML configuration list produced by validate_yml()
#'
#' @return Character vector of object names
#' @noRd
get_yml_objects <- function(ymlconf){
  ymlconf$configuration$objects
}

#' Validate YAML file, extracted out from big DataPackageR function
#'
#' @param pkg_dir Path of top level of data package
#'
#' @return List object from read_yaml(ymlfile)
#' @noRd
validate_yml <- function(pkg_dir){
  # read YAML
  ymlfile <- list.files(
    path = pkg_dir, pattern = "^datapackager.yml$",
    full.names = TRUE
  )
  if (length(ymlfile) == 0) {
    .multilog_fatal(paste0("Yaml configuration file not found at ", pkg_dir))
    stop("exiting", call. = FALSE)
  }
  ymlconf <- read_yaml(ymlfile)
  # test that the structure of the yaml file is correct!
  if (!"configuration" %in% names(ymlconf)) {
    .multilog_fatal("YAML is missing 'configuration:' entry")
    stop("exiting", call. = FALSE)
  }
  if (!all(c("files", "objects") %in% names(ymlconf$configuration))) {
    .multilog_fatal("YAML is missing files: and objects: entries")
    stop("exiting", call. = FALSE)
  }
  .multilog_trace("Reading yaml configuration")
  # files that have enable: TRUE
  stopifnot("configuration" %in% names(ymlconf))
  stopifnot("files" %in% names(ymlconf[["configuration"]]))
  stopifnot(!is.null(names(ymlconf[["configuration"]][["files"]])))

  # object with same name as package causes problems with
  # overwriting documentation files
  if (basename(pkg_dir) %in% ymlconf$configuration$objects){
    err_msg <- "Data object not allowed to have same name as data package"
    flog.fatal(err_msg, name = "console")
    stop(err_msg, call. = FALSE)
  }
  render_root <- .get_render_root(ymlconf)
  .validate_render_root(render_root)
  if (length(get_yml_objects(ymlconf)) == 0) {
    .multilog_fatal("You must specify at least one data object.")
    stop("exiting", call. = FALSE)
  }
  r_files <- get_yml_r_files(ymlconf)
  if (length(r_files) == 0) {
    .multilog_fatal("No files enabled for processing!")
    stop("error", call. = FALSE)
  }
  if (any(duplicated(r_files))){
    err_msg <- "Duplicate R files specified in YAML."
    .multilog_fatal(err_msg)
    stop(err_msg, call. = FALSE)
  }
  for (file in r_files){
    if (! file.exists(file.path(pkg_dir, 'data-raw', file))){
      err_msg <- paste("Missing R file specified in YAML:", file)
      .multilog_fatal(err_msg)
      stop(err_msg, call. = FALSE)
    }
  }
  .multilog_trace(paste0("Found ", r_files))
  return(ymlconf)
}


#' Validate data package skeleton, extracted out from big DataPackageR function
#'
#' @param pkg_dir Path of top level of data package
#'
#' @return Silently returns pkg_dir if no errors thrown
#' @noRd
validate_package_skeleton <- function(pkg_dir){
  # we know it's a proper package root, but we want to test if we have the
  # necessary subdirectories
  dirs <- file.path(pkg_dir, c("R", "inst", "data", "data-raw"))
  for (dir in dirs){
    if (! utils::file_test(dir, op = "-d")){
      err_msg <- paste("Missing required subdirectory", dir)
      .multilog_fatal(err_msg)
      stop(err_msg)
    }
  }
  # check we can read a DESCRIPTION file
  d <- desc::desc(pkg_dir)
  invisible(pkg_dir)
}

#' Validate data package description
#'
#' @param pkg_dir The top-level directory path for the data package
#'
#' @returns validated description object, cf. [desc::desc()]
#' @noRd
validate_description <- function(pkg_dir){
  d <- desc::desc(pkg_dir)
  dv <- d$get('DataVersion')
  if (is.na(dv)) {
    err_msg <- paste0(
      "DESCRIPTION file must have a DataVersion",
      " line. i.e. DataVersion: 0.2.0"
    )
    .multilog_fatal(err_msg)
    stop(err_msg, call. = FALSE)
  }
  validate_DataVersion(dv)
  d
}

#' Validate and return DataVersion
#'
#' @param DataVersion Character, e.g. '0.1.1', or a valid base R object of class 'package_version'
#'
#' @returns Class 'character', the validated DataVersion, e.g. '0.1.1'
#' @noRd
validate_DataVersion <- function(DataVersion){
  # allow input as package_version
  if (inherits(DataVersion, 'package_version')){
    DataVersion <- as.character(DataVersion)
  }
  stopifnot(! is.null(DataVersion),
            is.character(DataVersion),
            length(DataVersion) == 1,
            ! is.na(DataVersion)
  )
  # base::R_system_version enforces valid 3-number version (major, minor, patch)
  as.character(R_system_version(DataVersion))
}

#' do_digests() function extracted out from DataPackageR
#'
#' @param pkg_dir The top level file path of the data package
#' @param dataenv The data environment, from DataPackageR
#'
#' @returns TRUE if success
#' @noRd
do_digests <- function(pkg_dir, dataenv) {
  # Digest each object
  old_data_digest <- .parse_data_digest(pkg_dir = pkg_dir)
  pkg_desc <- validate_description(pkg_dir)
  new_data_digest <- .digest_data_env(
    ls(dataenv),
    dataenv,
    pkg_desc$get('DataVersion'))
  .newsfile()
  if (is.null(old_data_digest)){
    # first time data digest & early return
    .update_news_md(new_data_digest[["DataVersion"]],
                    interact = getOption(
                      "DataPackageR_interact",
                      interactive()))
    # this will write list of first time added objects to NEWS
    changed_objects <- .qualify_changes(new_data_digest, list())
    .update_news_changed_objects(changed_objects)
    .save_data(new_data_digest,
               pkg_desc$get('DataVersion'),
               ls(dataenv),
               dataenv,
               old_data_digest = NULL,
               pkg_path = pkg_dir)
    return(TRUE)
  }
  check_new_DataVersion <- .check_dataversion_string(
    new_data_digest,
    old_data_digest
  )
  can_write <- FALSE
  same_digests <- .compare_digests(old_data_digest, new_data_digest)
  if ((! same_digests) && check_new_DataVersion == "higher"){
    # not sure how this would actually happen
    err_msg <- 'Digest(s) differ but DataVersion had already been incremented'
    .multilog_fatal(err_msg)
    stop(err_msg, call. = FALSE)
  }
  if (same_digests && check_new_DataVersion == "equal") {
    can_write <- TRUE
    .multilog_trace(paste0(
      "Processed data sets match ",
      "existing data sets at version ",
      new_data_digest[["DataVersion"]]
    ))
  } else if ((! same_digests) && check_new_DataVersion == "equal") {
    updated_version <- .increment_data_version(
      pkg_desc,
      new_data_digest
    )
    #TODO what objects have changed?
    changed_objects <- .qualify_changes(new_data_digest,old_data_digest)

    .update_news_md(updated_version$new_data_digest[["DataVersion"]],
                    interact = getOption("DataPackageR_interact", interactive())
    )
    .update_news_changed_objects(changed_objects)
    pkg_desc <- updated_version$pkg_description
    new_data_digest <- updated_version$new_data_digest
    can_write <- TRUE
    .multilog_trace(paste0(
      "Data has been updated and DataVersion ",
      "string incremented automatically to ",
      new_data_digest[["DataVersion"]]
    ))
  } else if (same_digests && check_new_DataVersion == "higher") {
    # edge case that shouldn't happen
    # but we test for it in the test suite
    can_write <- TRUE
    .multilog_trace(paste0(
      "Data hasn't changed but the ",
      "DataVersion has been bumped."
    ))
  } else if (check_new_DataVersion == "lower" && same_digests) {
    # edge case that shouldn't happen but
    # we test for it in the test suite.
    .multilog_trace(paste0(
      "New DataVersion is less than ",
      "old but data are unchanged"
    ))
    new_data_digest <- old_data_digest
    pkg_desc$set('DataVersion',
                 validate_DataVersion(new_data_digest[["DataVersion"]])
    )
    can_write <- TRUE
  } else if (check_new_DataVersion == "lower" && ! same_digests) {
    updated_version <- .increment_data_version(
      pkg_desc,
      new_data_digest
    )
    # TODO what objects have changed?
    changed_objects <- .qualify_changes(new_data_digest,old_data_digest)
    .update_news_md(updated_version$new_data_digest[["DataVersion"]],
                    interact = getOption("DataPackageR_interact", interactive())
    )
    .update_news_changed_objects(changed_objects)

    pkg_desc <- updated_version$pkg_description
    new_data_digest <- updated_version$new_data_digest
    can_write <- TRUE
  }
  if (can_write) {
    .save_data(new_data_digest,
               pkg_desc$get('DataVersion'),
               ls(dataenv),
               dataenv,
               old_data_digest = old_data_digest,
               pkg_path = pkg_dir
    )
  }
  return(TRUE)
}

#' do_doc() function extracted out from end of DataPackageR
#'
#' @param pkg_dir The top level file path of the data package
#' @param dataenv The data environment, from DataPackageR
#' @returns TRUE if success
#' @noRd
do_doc <- function(pkg_dir, dataenv) {
  # Run .doc_autogen #needs to be run when we have a partial build..
  if (!file.exists(file.path(pkg_dir, 'data-raw', "documentation.R"))) {
    .doc_autogen(basename(pkg_dir),
                 ds2kp = ls(dataenv),
                 env = dataenv,
                 path = file.path(pkg_dir, 'data-raw')
    )
  }
  # parse documentation
  doc_parsed <- .doc_parse(file.path(pkg_dir, 'data-raw', "documentation.R"))
  # case where we add an object,
  # ensures we combine the documentation properly
  pkg_name <- validate_pkg_name(pkg_dir)
  missing_doc_for_autodoc <- setdiff(
    ls(dataenv),
    setdiff(names(doc_parsed), pkg_name)
  )
  if (length(missing_doc_for_autodoc) != 0) {
    tmptarget <- tempdir()
    file.info("Writing missing docs.")
    .doc_autogen(basename(pkg_dir),
                 ds2kp = missing_doc_for_autodoc,
                 env = dataenv,
                 path = tmptarget,
                 name = "missing_doc.R"
    )
    missing_doc <- .doc_parse(file.path(tmptarget, "missing_doc.R"))
    doc_parsed <- .doc_merge(
      old = doc_parsed,
      new = missing_doc
    )
    file.info("Writing merged docs.")
    writeLines(Reduce(c, doc_parsed),
               file.path(pkg_dir, 'data-raw', "documentation.R")
    )
  }
  # Partial build if enabled=FALSE for
  # any file We've disabled an object but don't
  # want to overwrite its documentation
  # or remove it The new approach just builds
  # all the docs independent of what's enabled.
  writeLines(Reduce(c, doc_parsed),
             file.path(pkg_dir, "R", paste0(pkg_name, ".R"))
  )
  .multilog_trace(
    paste0(
      "Copied documentation to ",
      file.path(pkg_dir, "R", paste0(pkg_name, ".R"))
    )
  )
  # TODO test that we have documented
  # everything successfully and that all files
  # have been parsed successfully
  return(TRUE)
}

.ppfiles_mkvignettes <- function(dir = NULL) {
  if (proj_get() != dir) {
    usethis::proj_set(dir) #nocov
  }
  pkg <- desc::desc(dir)
  pkg$set_dep("knitr", "Suggests")
  pkg$set_dep("rmarkdown", "Suggests")
  pkg$set("VignetteBuilder" = "knitr")
  pkg$write()
  usethis::use_directory("vignettes")
  usethis::use_directory("inst/doc")
  # TODO maybe copy only the files that have both html and Rmd.
  rmdfiles_for_vignettes <-
    list.files(
      path = file.path(dir, "data-raw"),
      pattern = "Rmd$",
      full.names = TRUE,
      recursive = FALSE
    )
  htmlfiles_for_vignettes <-
    list.files(
      path = file.path(dir, "inst/extdata/Logfiles"),
      pattern = "html$",
      full.names = TRUE,
      recursive = FALSE
    )
  pdffiles_for_vignettes <-
    list.files(
      path = file.path(dir, "inst/extdata/Logfiles"),
      pattern = "pdf$",
      full.names = TRUE,
      recursive = FALSE
    )
  lapply(htmlfiles_for_vignettes,
    function(x) {
      file.copy(x,
        file.path(
          dir,
          "inst/doc",
          basename(x)
        ),
        overwrite = TRUE
      )
    }
  )
  lapply(
    pdffiles_for_vignettes,
    function(x) {
      file.copy(x,
                file.path(
                  dir,
                  "inst/doc",
                  basename(x)
                ),
                overwrite = TRUE
      )
    }
  )
  lapply(
    rmdfiles_for_vignettes,
    function(x) {
      file.copy(x,
        file.path(
          dir,
          "vignettes",
          basename(x)
        ),
        overwrite = TRUE
      )
    }
  )
  vignettes_to_process <- list.files(
    path = file.path(dir, "vignettes"),
    pattern = "Rmd$",
    full.names = TRUE,
    recursive = FALSE
  )
  write_me_out <- lapply(vignettes_to_process, function(x) {
    title <- "Default Vignette Title. Add yaml title: to your document"
    thisfile <- read_file(x)
    stripped_yaml <- gsub("---\\s*\n.*\n---\\s*\n", "", thisfile)
    frontmatter <- gsub("(---\\s*\n.*\n---\\s*\n).*", "\\1", thisfile)
    con <- textConnection(frontmatter)
    fm <- rmarkdown::yaml_front_matter(con)
    if (is.null(fm[["vignette"]])) {
      # add boilerplate vignette yaml
      if (!is.null(fm$title)) {
        title <- fm$title
      }
      fm$vignette <- paste0("%\\VignetteIndexEntry{", title, "}
                           %\\VignetteEngine{knitr::rmarkdown}
                           \\usepackage[utf8]{inputenc}")
    } else {
      # otherwise leave it as is.
    }
    tmp <- fm$vignette
    tmp <- gsub(
      "  $",
      "",
      paste0(
        "vignette: >\n  ",
        gsub(
          "\\}\\s*",
          "\\}\n  ",
          tmp
        )
      )
    )
    fm$vignette <- NULL
    write_me_out <- paste0(
      "---\n",
      paste0(yaml::as.yaml(fm), tmp),
      "---\n\n",
      stripped_yaml
    )
    write_me_out
  })
  names(write_me_out) <- vignettes_to_process
  for (i in vignettes_to_process) {
    writeLines(write_me_out[[i]], con = i)
    writeLines(write_me_out[[i]],
      con = file.path(
        dir,
        "inst/doc",
        basename(i)
      )
    )
  }
}

#' Get DataPackageR Project Root Path
#'
#' @details Returns the path to the data package project root, or
#' constructs a path to a file in the project root from the
#' file argument.
#' @return \code{character}
#' @param file \code{character} or \code{NULL} (default).
#' @export
#'
#' @examples
#' if(rmarkdown::pandoc_available()){
#' project_path( file = "DESCRIPTION" )
#' }
project_path <- function(file = NULL) {
  if (is.null(file)) {
    return(usethis::proj_get())
  } else {
    return(normalizePath(file.path(usethis::proj_get(), file), winslash = "/",
                         mustWork = FALSE))
  }
}


#' Get DataPackageR extdata path
#'
#' @details Returns the path to the data package extdata subdirectory, or
#' constructs a path to a file in the extdata subdirectory from the
#' file argument.
#' @return \code{character}
#' @param file \code{character} or \code{NULL} (default).
#' @export
#'
#' @examples
#' if(rmarkdown::pandoc_available()){
#' project_extdata_path(file = "mydata.csv")
#' }
project_extdata_path <- function(file = NULL) {
  if (is.null(file)) {
    return(file.path(usethis::proj_get(), "inst", "extdata"))
  } else {
    return(normalizePath(
      file.path(
        usethis::proj_get(),
        "inst", "extdata", file
      ),
      winslash = "/",
      mustWork = FALSE
    ))
  }
}

#' Get DataPackageR data path
#'
#' @details Returns the path to the data package data subdirectory, or
#' constructs a path to a file in the data subdirectory from the
#' file argument.
#' @return \code{character}
#' @param file \code{character} or \code{NULL} (default).
#' @export
#'
#' @examples
#' if(rmarkdown::pandoc_available()){
#' project_data_path( file = "data.rda" )
#' }
project_data_path <- function(file = NULL) {
  if (is.null(file)) {
    return(file.path(usethis::proj_get(), "data"))
  } else {
    return(normalizePath(
      file.path(
        usethis::proj_get(),
        "data", file
      ),
      winslash = "/",
      mustWork = FALSE
    ))
  }
}

#' @name document
#' @rdname document
#' @title Build documentation for a data package using DataPackageR.
#' @param path \code{character} the path to the data package source root.
#' @param install \code{logical} install the package. (default FALSE)
#' @param ... additional arguments to \code{install}
#' @returns Called for side effects. Returns TRUE on successful exit.
#' @export
#' @examples
#' # A simple Rmd file that creates one data object
#' # named "tbl".
#' if(rmarkdown::pandoc_available()){
#' f <- tempdir()
#' f <- file.path(f,"foo.Rmd")
#' con <- file(f)
#' writeLines("```{r}\n tbl = data.frame(1:10) \n```\n",con=con)
#' close(con)
#' \donttest{
#' # construct a data package skeleton named "MyDataPackage" and pass
#' # in the Rmd file name with full path, and the name of the object(s) it
#' # creates.
#'
#' pname <- basename(tempfile())
#' datapackage_skeleton(name=pname,
#'    path=tempdir(),
#'    force = TRUE,
#'    r_object_names = "tbl",
#'    code_files = f)
#'
#' # call package_build to run the "foo.Rmd" processing and
#' # build a data package.
#' package_build(file.path(tempdir(), pname), install = FALSE)
#' document(path = file.path(tempdir(), pname), install = FALSE)
#' }
#' }
document <- function(path = ".", install = FALSE, ...) {
  if (getOption('DataPackageR_verbose', TRUE)) cat("\n")
  usethis::proj_set(path = path)
  path <- usethis::proj_get()
  stopifnot(file.exists(file.path(path, "data-raw", "documentation.R")))
  desc <- desc::desc(file.path(path, "DESCRIPTION"))
  docfile <- paste0(desc$get("Package"), ".R")
  file.copy(
    from = file.path(path, "data-raw", "documentation.R"),
    to = file.path(path, "R", docfile),
    overwrite = TRUE
  )
  .multilog_trace("Rebuilding data package documentation.")
  local({
    on.exit({
      if (basename(path) %in% names(utils::sessionInfo()$otherPkgs)){
        pkgload::unload(basename(path))
      }
    })
    roxygen2::roxygenize(package.dir = path)
  })
  location <- pkgbuild::build(
    path = path, dest_path = dirname(path),
    vignettes = FALSE, quiet = TRUE
  )
  # try to install and then reload the package in the current session
  if (install) {
    utils::install.packages(location, repos = NULL, type = "source", ...)
  }
  return(TRUE)
}
