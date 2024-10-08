## ----echo = FALSE-------------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "",
  eval = TRUE
)

## ----minimal_example, results='hide', eval = rmarkdown::pandoc_available()----
library(DataPackageR)

# Let's reproducibly package the cars in the mtcars dataset with speed
# > 20. Our dataset will be called `cars_over_20`.

# Get the code file that turns the raw data to our packaged and
# processed analysis-ready dataset.
processing_code <-
    system.file("extdata", "tests", "subsetCars.Rmd", package = "DataPackageR")

# Create the package framework.
DataPackageR::datapackage_skeleton(name = "mtcars20",
                                   force = TRUE,
                                   code_files = processing_code,
                                   r_object_names = "cars_over_20",
                                   path = tempdir()
                                   #dependencies argument is empty
                                   #raw_data_dir argument is empty.
                                   )


## ----dirstructure,echo=FALSE, eval = rmarkdown::pandoc_available()------------
library(data.tree)
df <- data.frame(
  pathString = file.path(
    "mtcars20",
    list.files(
      file.path(tempdir(), "mtcars20"),
      include.dirs = TRUE,
      recursive = TRUE
    )
  )
)
as.Node(df)

## ----echo=FALSE, eval = rmarkdown::pandoc_available()-------------------------
cat(yaml::as.yaml(yaml::yaml.load_file(file.path(tempdir(),"mtcars20","datapackager.yml"))))

## ----eval = rmarkdown::pandoc_available()-------------------------------------
DataPackageR::package_build(file.path(tempdir(),"mtcars20"))

## ----echo=FALSE, eval = rmarkdown::pandoc_available()-------------------------
df <- data.frame(
  pathString = file.path(
    "mtcars20",
    list.files(
      file.path(tempdir(), "mtcars20"),
      include.dirs = TRUE,
      recursive = TRUE
    )
  )
)

as.Node(df)

## ----rebuild_docs, eval = rmarkdown::pandoc_available()-----------------------
DataPackageR::document(file.path(tempdir(),"mtcars20"))

## ----eval = rmarkdown::pandoc_available()-------------------------------------
# Create a temporary library to install into.
dir.create(file.path(tempdir(),"lib"))

# Let's install the package we just created.
# This can also be done with with `install = TRUE` in package_build() or document().

install.packages(file.path(tempdir(),"mtcars20_1.0.tar.gz"),
                 type = "source", repos = NULL,
                 lib = file.path(tempdir(),"lib"))
lns <- loadNamespace
if (!"package:mtcars20"%in%search())
  attachNamespace(lns('mtcars20',lib.loc = file.path(tempdir(),"lib"))) #use library() in your code
data("cars_over_20") # load the data

cars_over_20 # now we can use it.
?cars_over_20 # See the documentation you wrote in data-raw/documentation.R.

vignettes <- vignette(package = "mtcars20", lib.loc = file.path(tempdir(),"lib"))
vignettes$results

## ----eval = rmarkdown::pandoc_available()-------------------------------------
# We can easily check the version of the data.
DataPackageR::data_version("mtcars20", lib.loc = file.path(tempdir(),"lib"))

# You can use an assert to check the data version in  reports and
# analyses that use the packaged data.
assert_data_version(data_package_name = "mtcars20",
                    version_string = "0.1.0", acceptable = "equal",
                    lib.loc = file.path(tempdir(),"lib"))  #If this fails, execution stops
                                           #and provides an informative error.

## ----construct_config, eval = rmarkdown::pandoc_available()-------------------
# Assume I have file1.Rmd and file2.R located in /data-raw, and these
# create 'object1' and 'object2' respectively.

config <- construct_yml_config(code = c("file1.Rmd", "file2.R"),
                               data = c("object1", "object2"))
cat(yaml::as.yaml(config))

## ----eval = rmarkdown::pandoc_available()-------------------------------------
path_to_package <- tempdir() # e.g., if tempdir() was the root of our package.
yml_write(config, path = path_to_package)

## ----echo=1:2, eval = rmarkdown::pandoc_available()---------------------------
config <- yml_disable_compile(config,filenames = "file2.R")
yml_write(config, path = path_to_package) # write modified yml to the package.
cat(yaml::as.yaml(config))

## ----echo=FALSE, eval = rmarkdown::pandoc_available()-------------------------
cat(readLines(file.path(tempdir(),"mtcars20","DATADIGEST")),sep="\n")

## ----echo=FALSE, eval = rmarkdown::pandoc_available()-------------------------
cat(readLines(file.path(tempdir(),"mtcars20","DESCRIPTION")),sep="\n")

