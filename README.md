README
================

# DataPackageR

DataPackageR is used to reproducibly process raw data into packaged,
analysis-ready data sets.

<!-- badges: start -->

[![CRAN](https://www.r-pkg.org/badges/version/DataPackageR)](https://CRAN.R-project.org/package=DataPackageR)
[![R-CMD-check](https://github.com/ropensci/DataPackageR/workflows/R-CMD-check/badge.svg)](https://github.com/ropensci/DataPackageR/actions)
[![Coverage
status](https://codecov.io/gh/ropensci/DataPackageR/branch/master/graph/badge.svg)](https://codecov.io/github/ropensci/DataPackageR?branch=master)
[![Project Status: Active – The project has reached a stable, usable
state and is being actively
developed.](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)
[![](https://badges.ropensci.org/230_status.svg)](https://github.com/ropensci/software-review/issues/230)
[![DOI](https://zenodo.org/badge/29267435.svg)](https://doi.org/10.5281/zenodo.1292095)
<!-- badges: end -->

-   [yaml configuration
    guide](https://github.com/ropensci/DataPackageR/blob/main/vignettes/YAML_CONFIG.md)
-   [a more detailed technical
    vignette](https://github.com/ropensci/DataPackageR/blob/main/vignettes/usingDataPackageR.md)

> **Important Note**: [datapack](https://github.com/ropensci/datapack)
> is a *different package* that is used to “create, send and load data
> from common repositories such as DataONE into the R environment.”

> **This package** is for processing raw data into tidy data sets and
> bundling them into R packages.

## What problems does DataPackageR tackle?

You have diverse raw data sets that you need to preprocess and tidy in
order to:

-   Perform data analysis
-   Write a report
-   Publish a paper
-   Share data with colleagues and collaborators
-   Save time in the future when you return to this project but have
    forgotten all about what you did.

### Why package data sets?

**Definition:** A *data package* is a formal R package whose sole
purpose is to contain, access, and / or document data sets.

-   **Reproducibility.**

    As described [elsewhere](https://github.com/ropensci/rrrpkg),
    packaging your data promotes reproducibility. R’s packaging
    infrastructure promotes unit testing, documentation, a reproducible
    build system, and has many other benefits. Coopting it for packaging
    data sets is a natural fit.

-   **Collaboration.**

    A data set packaged in R is easy to distribute and share amongst
    collaborators, and is easy to install and use. All the hard work
    you’ve put into documenting and standardizing the tidy data set
    comes right along with the data package.

-   **Documentation.**

    R’s package system allows us to document data objects. What’s more,
    the `roxygen2` package makes this very easy to do with [markup
    tags](https://r-pkgs.org/data.html). That documentation is the
    equivalent of a data dictionary and can be extremely valuable when
    returning to a project after a period of time.

-   **Convenience.**

    Data pre-processing can be time consuming, depending on the data
    type and raw data sets may be too large to share conveniently in a
    packaged format. Packaging and sharing the small, tidied data saves
    the users computing time and time spent waiting for downloads.

## Challenges.

-   **Package size limits.**

    R packages have a 5MB size limit, at least on CRAN. BioConductor has
    explicit [data
    package](https://www.bioconductor.org/developers/package-guidelines/#package-types)
    types that can be larger and use git LFS for very large files.

    Sharing large volumes of raw data in an R package format is still
    not ideal, and there are public biological data repositories better
    suited for raw data: e.g., [GEO](https://www.ncbi.nlm.nih.gov/geo/),
    [SRA](https://www.ncbi.nlm.nih.gov/sra),
    [ImmPort](https://www.immport.org:443/shared/immport-open/public/home/home),
    [ImmuneSpace](https://immunespace.org/),
    [FlowRepository](https://flowrepository.org/).

    Tools like [datastorr](https://github.com/ropenscilabs/datastorr)
    can help with this and we hope to integrate the into DataPackageR in
    the future.

-   **Manual effort**

    There is still a substantial manual effort to set up the correct
    directory structures for an R data package. This can dissuade many
    individuals, particularly new users who have never built an R
    package, from going this route.

-   **Scale**

    Setting up and building R data packages by hand is a workable
    solution for a small project or a small number of projects, but when
    dealing with many projects each involving many data sets, tools are
    needed to help automate the process.

## DataPackageR

DataPackageR provides a number of benefits when packaging your data.

-   It aims to automate away much of the tedium of packaging data sets
    without getting too much in the way, and keeps your processing
    workflow reproducible.

-   It sets up the necessary package structure and files for a data
    package.

-   It allows you to keep the large, raw data and only ship the packaged
    tidy data, saving space and time consumers of your data set need to
    spend downloading and re-processing it.

-   It maintains a reproducible record (vignettes) of the data
    processing along with the package. Consumers of the data package can
    verify how the processing was done, increasing confidence in your
    data.

-   It automates construction of the documentation and maintains a data
    set version and an md5 fingerprint of each data object in the
    package. If the data changes and the package is rebuilt, the data
    version is automatically updated.

## Similar work

There are a number of tools out there that address similar and
complementary problems:

-   **datastorr** [github
    repo](https://github.com/ropenscilabs/datastorr)

    Simple data retrieval and versioning using GitHub to store data.

    -   Caches downloads and uses github releases to version data.
    -   Deal consistently with translating the file stored online into a
        loaded data object
    -   Access multiple versions of the data at once

    `datastorrr` could be used with DataPackageR to store / access
    remote raw data sets, remotely store / access tidied data that are
    too large to fit in the package itself.

-   **fst** [github repo](https://github.com/fstpackage/fst)

    `fst` provides lightning fast serialization of data frames.

-   **The modern data package**
    [pdf](https://github.com/noamross/2018-04-18-rstats-nyc/blob/master/Noam_Ross_ModernDataPkg_rstatsnyc_2018-04-20.pdf)

    A presentation from @noamross touching on modern tools for open
    science and reproducibility. Discusses `datastorr` and `fst` as well
    as standardized metadata and documentation.

-   **rrrpkg** [github repo](https://github.com/ropensci/rrrpkg)

    A document from ropensci describing using an R package as a research
    compendium. Based on ideas originally introduced by Robert Gentleman
    and Duncan Temple Lang (Gentleman and Lang
    (2004)<!--@Gentleman2004-oj-->)

-   **template** [github repo](https://github.com/ropensci/rrrpkg)

    An R package template for data packages.

See the [publication](#publication) for further discussion.

## Installation

You can install the latest version of DataPackageR from
[github](https://github.com/ropensci/DataPackageR) with:

``` r
library(devtools)
devtools::install_github("ropensci/DataPackageR")
```

## Blog Post - building packages interactively.

See this [rOpenSci blog
post](https://ropensci.org/blog/2018/09/18/datapackager/) on how to
build data packages interactively using DataPackageR. This uses several
new interfaces: `use_data_object()`, `use_processing_script()` and
`use_raw_dataset()` to build up a data package, rather than assuming the
user has all the code and data ready to go for `datapackage_skeleton()`.

## Example (assuming all code and data are available)

``` r
library(DataPackageR)

# Let's reproducibly package up
# the cars in the mtcars dataset
# with speed > 20.
# Our dataset will be called cars_over_20.
# There are three steps:

# 1. Get the code file that turns the raw data
# into our packaged and processed analysis-ready dataset.
# This is in a file called subsetCars.Rmd located in exdata/tests of the DataPackageR package.
# For your own projects you would write your own Rmd processing file.
processing_code <- system.file(
  "extdata", "tests", "subsetCars.Rmd", package = "DataPackageR"
)

# 2. Create the package framework.
# We pass in the Rmd file in the `processing_code` variable and the names of the data objects it creates (called "cars_over_20")
# The new package is called "mtcars20"
datapackage_skeleton(
  "mtcars20", force = TRUE, 
  code_files = processing_code, 
  r_object_names = "cars_over_20", 
  path = tempdir()) 

# 3. Run the preprocessing code to build the cars_over_20 data set 
# and reproducibly enclose it in the mtcars20 package.
# packageName is the full path to the package source directory created at step 2.
# You'll be prompted for a text description (one line) of the changes you're making.
# These will be added to the NEWS.md file along with the DataVersion in the package source directory.
# If the build is run in non-interactive mode, the description will read
# "Package built in non-interactive mode". You may update it later.
dir.create(file.path(tempdir(),"lib"))
package_build(packageName = file.path(tempdir(),"mtcars20"), install = TRUE, lib = file.path(tempdir(),"lib"))
#> Warning: package 'mtcars20' is in use and will not be installed

# Update the autogenerated roxygen documentation in data-raw/documentation.R. 
# edit(file.path(tempdir(),"mtcars20","R","mtcars20.R"))

# 4. Rebuild the documentation.
document(file.path(tempdir(),"mtcars20"), install = TRUE, lib = file.path(tempdir(),"lib"))
#> Warning: package 'mtcars20' is in use and will not be installed

# Let's use the package we just created.
install.packages(file.path(tempdir(),"mtcars20_1.0.tar.gz"), type = "source", repos = NULL)
#> Warning: package 'mtcars20' is in use and will not be installed
library(mtcars20)
data("cars_over_20") # load the data
cars_over_20  # Now we can use it.
?cars_over_20 # See the documentation you wrote in data-raw/documentation.R.

# We have our dataset!
# Since we preprocessed it,
# it is clean and under the 5 MB limit for data in packages.
cars_over_20

# We can easily check the version of the data
data_version("mtcars20")

# You can use an assert to check the data version in  reports and
# analyses that use the packaged data.
assert_data_version(data_package_name = "mtcars20",
                    version_string = "0.1.0",
                    acceptable = "equal")
```

### Reading external data from within R / Rmd processing scripts.

When creating a data package, your processing scripts will need to read
your raw data sets in order to process them. These data sets can be
stored in `inst/extdata` of the data package source tree, or elsewhere
outside the package source tree. In order to have portable and
reproducible code, you should not use absolute paths to the raw data.
Instead, `DataPackageR` provides several APIs to access the data package
project root directory, the `inst/extdata` subdirectory, and the `data`
subdirectory.

``` r
# This returns the datapackage source 
# root directory. 
# In an R or Rmd processing script this can be used to build a path to a directory that is exteral to the package, for 
# example if we are dealing with very large data sets where data cannot be packaged.
DataPackageR::project_path()

# This returns the   
# inst/extdata directory. 
# Raw data sets that are included in the package should be placed there.
# They can be read from that location, which is returned by: 
DataPackageR::project_extdata_path()

# This returns the path to the datapackage  
# data directory. This can be used to access 
# stored data objects already created and saved in `data` from 
# other processing scripts.
DataPackageR::project_data_path()
```

## Preprint and publication. <a id = "publication"></a>

The publication describing the package, (Finak *et* *al.,*
2018)<!--@10.12688/gatesopenres.12832.2-->, is now available at [Gates
Open Research](https://gatesopenresearch.org/articles/2-31/v1) .

The preprint is on [biorxiv](https://doi.org/10.1101/342907).

## Code of conduct

Please note that this project is released with a [Contributor Code of
Conduct](https://github.com/ropensci/DataPackageR/blob/main/CODE_OF_CONDUCT.md).
By participating in this project you agree to abide by its terms.

### References

1.  Gentleman, Robert, and Duncan Temple Lang. 2004. “Statistical
    Analyses and Reproducible Research.” Bioconductor Project Working
    Papers, Bioconductor project working papers,. bepress.

2.  Finak G, Mayer B, Fulp W et al. DataPackageR: Reproducible data
    preprocessing, standardization and sharing using R/Bioconductor for
    collaborative data analysis \[version 1; referees: 1 approved with
    reservations\]. Gates Open Res 2018, 2:31 (doi:
    10.12688/gatesopenres.12832.1)

[![ropensci\_footer](https://ropensci.org/public_images/ropensci_footer.png)](https://ropensci.org)
