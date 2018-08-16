---
title: "Using DataPackageR"
author: "Greg Finak <gfinak@fredhutch.org>"
date: "2018-07-31"
output: 
  rmarkdown::html_vignette:
    keep_md: TRUE
    toc: yes
vignette: >
  %\VignetteIndexEntry{A Guide to using DataPackageR}
  %\VignetteEngine{knitr::rmarkdown}
  \usepackage[utf8]{inputenc}
  \usepackage{graphicx}
---



## Purpose

This vignette demonstrates how to use DataPackageR to build a data package. 

DataPackageR aims to simplify data package construction.

It provides mechanisms for reproducibly preprocessing and tidying raw data into into documented, versioned, and packaged analysis-ready data sets. 

Long-running or computationally intensive data processing can be decoupled from the usual `R CMD build` process while maintinaing [data lineage](https://en.wikipedia.org/wiki/Data_lineage).

In this vignette we will subset and package the `mtcars` data set.

## Set up a new data package.

We'll set up a new data package based on `mtcars` example in the [README](https://github.com/RGLab/DataPackageR/blob/master/README.md).
The `datapackage_skeleton()` API is used to set up a new package. 
The user needs to provide:

- R or Rmd code files that do data processing.
- A list of R object names created by those code files.




```r
library(DataPackageR)

# Let's reproducibly package up
# the cars in the mtcars dataset
# with speed > 20.
# Our dataset will be called cars_over_20.

# Get the code file that turns the raw data
# to our packaged and processed analysis-ready dataset.
processing_code <-
  system.file("extdata", 
              "tests",
              "subsetCars.Rmd",
              package = "DataPackageR")

# Create the package framework.
DataPackageR::datapackage_skeleton(
  "mtcars20",
  force = TRUE,
  code_files = processing_code,
  r_object_names = "cars_over_20",
  path = tempdir()
  ) 
Adding DataVersion string to DESCRIPTION
Creating data and data-raw directories
configuring yaml file
```

### What's in the package skeleton structure?

This has created a datapackage source tree named "mtcars20" (in a temporary directory). 
For a real use case you would pick a `path` on your filesystem where you could then initialize a new github repository for the package.

The contents of `mtcars20` are:


```
                levelName
1  mtcars20              
2   ¦--data              
3   ¦--data-raw          
4   ¦   °--subsetCars.Rmd
5   ¦--datapackager.yml  
6   ¦--DESCRIPTION       
7   ¦--inst              
8   ¦   °--extdata       
9   ¦--man               
10  ¦--R                 
11  °--Read-and-delete-me
```

You should fill out the `DESCRIPTION` file to describe your data package. 
It contains a new `DataVersion` string that will be automatically incremented when the data package is built *if the packaged data has changed*. 

The user-provided code files reside in `data-raw`. They are executed during the data package build process.

### A few words abou the YAML config file

A `datapackager.yml` file is used to configure and control the build process.

The contents are:


```
configuration:
  files:
    subsetCars.Rmd:
      enabled: yes
  objects: cars_over_20
  render_root:
    tmp: '165231'
```

The two main pieces of information in the configuration are a list of the files to be processed and the data sets the package will store.

This example packages an R data set named `cars_over_20` (the name was passed in to `datapackage_skeleton()`).
It is created by the `subsetCars.Rmd` file. 


The objects must be listed in the yaml configuration file. `datapackage_skeleton()`  ensures this is done for you automatically. 

DataPackageR provides an API for modifying this file, so it does not need to be done by hand. 

Further information on the contents of the YAML configuration file, and the API are in the [YAML Configuration Details](YAML_CONFIG.md)

### Where do I put raw data?

Raw data (provided the size is not prohibitive) can be placed in `inst/extdata`.

In this example we are reading from `data(mtcars)` rather than from the file system.

#### An API to locate data sets within an R or Rmd file.

To locate the data to read from the filesystem:

- `DataPackageR::project_extdata_path()` to get the path to `inst/extdata` from inside an `Rmd` or `R` file. (e.g., /var/folders/jh/x0h3v3pd4dd497g3gtzsm8500000gn/T//RtmpBTcXNC/mtcars20/inst/extdata)

- `DataPackageR::project_path()`  to get the path to the datapackage root. (e.g., /var/folders/jh/x0h3v3pd4dd497g3gtzsm8500000gn/T//RtmpBTcXNC/mtcars20)

Raw data stored externally can be retreived relative to these paths.


## Build the data package.

Once the skeleton framework is set up, 


```r
# Run the preprocessing code to build cars_over_20
# and reproducibly enclose it in a package.
DataPackageR:::package_build(file.path(tempdir(),"mtcars20"))
INFO [2018-07-31 11:22:32] Logging to /private/var/folders/jh/x0h3v3pd4dd497g3gtzsm8500000gn/T/RtmpBTcXNC/mtcars20/inst/extdata/Logfiles/processing.log
INFO [2018-07-31 11:22:32] Processing data
INFO [2018-07-31 11:22:32] Reading yaml configuration
INFO [2018-07-31 11:22:32] Found /private/var/folders/jh/x0h3v3pd4dd497g3gtzsm8500000gn/T/RtmpBTcXNC/mtcars20/data-raw/subsetCars.Rmd
INFO [2018-07-31 11:22:32] Processing 1 of 1: /private/var/folders/jh/x0h3v3pd4dd497g3gtzsm8500000gn/T/RtmpBTcXNC/mtcars20/data-raw/subsetCars.Rmd


processing file: subsetCars.Rmd
  |                                                                         |                                                                 |   0%  |                                                                         |.........                                                        |  14%
  ordinary text without R code

  |                                                                         |...................                                              |  29%
label: unnamed-chunk-11 (with options) 
List of 1
 $ include: logi FALSE

  |                                                                         |............................                                     |  43%
  ordinary text without R code

  |                                                                         |.....................................                            |  57%
label: cars
  |                                                                         |..............................................                   |  71%
  ordinary text without R code

  |                                                                         |........................................................         |  86%
label: unnamed-chunk-12
  |                                                                         |.................................................................| 100%
  ordinary text without R code
output file: subsetCars.knit.md
/usr/local/bin/pandoc +RTS -K512m -RTS subsetCars.utf8.md --to html4 --from markdown+autolink_bare_uris+ascii_identifiers+tex_math_single_backslash+smart --output /private/var/folders/jh/x0h3v3pd4dd497g3gtzsm8500000gn/T/RtmpBTcXNC/mtcars20/inst/extdata/Logfiles/subsetCars.html --email-obfuscation none --self-contained --standalone --section-divs --template /Library/Frameworks/R.framework/Versions/3.5/Resources/library/rmarkdown/rmd/h/default.html --no-highlight --variable highlightjs=1 --variable 'theme:bootstrap' --include-in-header /var/folders/jh/x0h3v3pd4dd497g3gtzsm8500000gn/T//RtmpBTcXNC/rmarkdown-str1232e74080afc.html --mathjax --variable 'mathjax-url:https://mathjax.rstudio.com/latest/MathJax.js?config=TeX-AMS-MML_HTMLorMML' 

Output created: /private/var/folders/jh/x0h3v3pd4dd497g3gtzsm8500000gn/T/RtmpBTcXNC/mtcars20/inst/extdata/Logfiles/subsetCars.html
INFO [2018-07-31 11:22:32] 1 required data objects created by subsetCars.Rmd
INFO [2018-07-31 11:22:32] Saving to data
INFO [2018-07-31 11:22:32] Copied documentation to /private/var/folders/jh/x0h3v3pd4dd497g3gtzsm8500000gn/T/RtmpBTcXNC/mtcars20/R/mtcars20.R

✔ Creating 'vignettes/'
✔ Creating 'inst/doc/'
INFO [2018-07-31 11:22:32] Done
INFO [2018-07-31 11:22:32] DataPackageR succeeded
INFO [2018-07-31 11:22:32] Building documentation
First time using roxygen2. Upgrading automatically...
Updating roxygen version in /private/var/folders/jh/x0h3v3pd4dd497g3gtzsm8500000gn/T/RtmpBTcXNC/mtcars20/DESCRIPTION
Writing NAMESPACE
Loading mtcars20
Writing mtcars20.Rd
Writing cars_over_20.Rd
INFO [2018-07-31 11:22:33] Building package
'/Library/Frameworks/R.framework/Resources/bin/R' --no-site-file  \
  --no-environ --no-save --no-restore --quiet CMD build  \
  '/private/var/folders/jh/x0h3v3pd4dd497g3gtzsm8500000gn/T/RtmpBTcXNC/mtcars20'  \
  --no-resave-data --no-manual --no-build-vignettes 

Reloading installed mtcars20
[1] "/private/var/folders/jh/x0h3v3pd4dd497g3gtzsm8500000gn/T/RtmpBTcXNC/mtcars20_1.0.tar.gz"
```


### Why not just use R CMD build?

If the processing script is time consuming or the data set is particularly large, then `R CMD build` would run the code each time the package is installed. In such cases, raw data may not be available, or the environment to do the data processing may not be set up for each user of the data. DataPackageR decouples data processing from package building/installation for data consumers.

### A log of the build process

DataPackageR uses the `futile.logger` pagckage to log progress. 

If there are errors in the processing, the script will notify you via logging to console and to  `/private/tmp/Test/inst/extdata/Logfiles/processing.log`. Errors should be corrected and the build repeated.

If everything goes smoothly, you will have a new package built in the parent directory. 

In this case we have a new package 
`mtcars20_1.0.tar.gz`. 


### A note about the package source directory after building.

The pacakge source directory changes after the first build.


```
                         levelName
1  mtcars20                       
2   ¦--data                       
3   ¦   °--cars_over_20.rda       
4   ¦--data-raw                   
5   ¦   ¦--documentation.R        
6   ¦   °--subsetCars.Rmd         
7   ¦--DATADIGEST                 
8   ¦--datapackager.yml           
9   ¦--DESCRIPTION                
10  ¦--inst                       
11  ¦   ¦--doc                    
12  ¦   ¦   ¦--subsetCars.html    
13  ¦   ¦   °--subsetCars.Rmd     
14  ¦   °--extdata                
15  ¦       °--Logfiles           
16  ¦           ¦--processing.log 
17  ¦           °--subsetCars.html
18  ¦--man                        
19  ¦   ¦--cars_over_20.Rd        
20  ¦   °--mtcars20.Rd            
21  ¦--NAMESPACE                  
22  ¦--R                          
23  ¦   °--mtcars20.R             
24  ¦--Read-and-delete-me         
25  °--vignettes                  
26      °--subsetCars.Rmd         
```

#### Update the autogenerated documentation. 

After the first build, the `R` directory contains `mtcars.R` that has autogenerated `roxygen2` markup documentation for the data package and for the packaged data `cars_over20`. 

The processed `Rd` files can be found in `man`. 

#### Dont' forget to rebuild the package.

You should update the documentation in `R/mtcars.R`, then call `package_build()` again.


## Installing and using the new data package


### Accessing vignettes, data sets, and data set documentation. 

The package source also contains files in the `vignettes` and `inst/doc` directories that provide a log of the data processing. 

When the package is installed, these will be accessible via the `vignette()` API. 

The vignette will detail the processing performed by the `subsetCars.Rmd` processing script. 

The data set documentation will be accessible via `?cars_over_20`, and the data sets via `data()`. 


```r
# Let's use the package we just created.
install.packages(file.path(tempdir(),"mtcars20_1.0.tar.gz"), type = "source", repos = NULL)
if(!"package:mtcars20"%in%search())
  attachNamespace('mtcars20') #use library() in your code
data("cars_over_20") # load the data

cars_over_20 # now we can use it.
   speed dist
44    22   66
45    23   54
46    24   70
47    24   92
48    24   93
49    24  120
50    25   85
?cars_over_20 # See the documentation you wrote in data-raw/documentation.R.

vignettes = vignette(package="mtcars20")
vignettes$results
      Package   
Topic "mtcars20"
      LibPath                                                         
Topic "/Library/Frameworks/R.framework/Versions/3.5/Resources/library"
      Item         Title                                            
Topic "subsetCars" "A Test Document for DataPackageR (source, html)"
```


### Using the DataVersion

Your downstream data analysis can depend on a specific version of the data in your data package by tesing the DataVersion string in the DESCRIPTION file. 

We provide an API for this:


```r
# We can easily check the version of the data
DataPackageR::data_version("mtcars20")
[1] '0.1.0'

# You can use an assert to check the data version in  reports and
# analyses that use the packaged data.
assert_data_version(data_package_name = "mtcars20",
                    version_string = "0.1.0",
                    acceptable = "equal")  #If this fails, execution stops
                                           #and provides an informative error.
```


# Migrating old data packages.

Version 1.12.0 has moved away from controlling the build process using `datasets.R` and an additional `masterfile` argument. 

The build process is now controlled via a `datapackager.yml` configuration file located in the package root directory.  (see [YAML Configuration Details](YAML_CONFIG.md))

### Create a datapackager.yml file

You can migrate an old package by constructing such a config file using the `construct_yml_config()` API.


```r
# assume I have file1.Rmd and file2.R located in /data-raw, 
# and these create 'object1' and 'object2' respectively.
configuration:
  files:
    file1.Rmd:
      enabled: yes
    file2.R:
      enabled: yes
  objects:
  - object1
  - object2
  render_root:
    tmp: '39760'
```

`config` is a newly constructed yaml configuration object. It can be written to the package directory:


```r
path_to_package = tempdir() #e.g., if tempdir() was the root of our package.
yml_write(config, path = path_to_package)
```

Now the package at `path_to_package` will build with version 1.12.0 or greater.

### Reading data sets from Rmd files

In versions prior to 1.12.1 we would read data sets from `inst/extdata` in an `Rmd` script using paths relative to
`data-raw` in the data package source tree. 

For example:

#### The old way

```r
# read 'myfile.csv' from inst/extdata relative to data-raw where the Rmd is rendered.
read.csv(file.path("../inst/extdata","myfile.csv"))
```

Now `Rmd` and `R` scripts are processed in `render_root` defined in the yaml config.

To read a raw data set we can get the path to the package source directory using an API call:


#### The new way

```r
# DataPackageR::project_path() returns the path to the data package source directory.
read.csv(file.path(
    DataPackageR::project_path(), 
    "inst/extdata",
    "myfile.csv")
    )
```

# Partial builds

We can also perform partial builds of a subset of files in a package by toggling the `enabled` key in the config file.

This can be done with the following API:


```r
config = yml_disable_compile(config,filenames = "file2.R")
yml_write(config, path = path_to_package) # write modified yml to the package.
configuration:
  files:
    file1.Rmd:
      enabled: yes
    file2.R:
      enabled: no
  objects:
  - object1
  - object2
  render_root:
    tmp: '39760'
```

Note that the modified configuration needs to be written back to the package source directory in order for the 
changes to take effect. 

The consequence of toggling a file to `enable: no` is that it will be skipped when the package is rebuilt, 
but the data will still be retained in the package, and the documentation will not be altered. 

This is useful in situations where we have multiple data sets, and want to re-run one script to update a specific data set, but
not the other scripts because they may be too time consuming, for example.

# Multi-script pipelines.

We may have situations where we have mutli-script pipelines. There are two ways to share data among scripts. 

1. filesystem artifacts
2. data objects passed to subsequent scripts.

### File system artifacts

The yaml configuration property `render_root` specifies the working directory where scripts will be rendered.

If a script writes files to the working directory, that is where files will appear. These can be read by subsequent scripts.

### Passing data objects to subsequent scripts.

A script (e.g., `script2.Rmd`) running after `script1.Rmd` can access a stored data object named `script1_dataset` created by `script1.Rmd` by calling

`DataPackageR::datapackager_object_read("script1_dataset")`. 

Passing of data objects amongst scripts can be turned off via:

`package_build(deps = FALSE)`

# Next steps 

We recommend the following once your package is created.

## Place your package under source control

You now have a data package source tree. 

- **Place your package under version control**
    1. Call `git init` in the package source root to initialize a new git repository.
    2. [Create a new repository for your data package on github](https://help.github.com/articles/create-a-repo/).
    3. Push your local package repository to `github`. [see step 7](https://help.github.com/articles/adding-an-existing-project-to-github-using-the-command-line/)


This will let you version control your data processing code, and provide a mechanism for sharing your package with others.


For more details on using git and github with R, there is an excellent guide provided by Jenny Bryan: [Happy Git and GitHub for the useR](http://happygitwithr.com/) and Hadley Wickham's [book on R packages](http://r-pkgs.had.co.nz/).

# Additional Details

We provide some additional details for the interested.

### Fingerprints of stored data objects

DataPackageR calculates an md5 checksum of each data object it stores, and keeps track of them in a file
called `DATADIGEST`.

- Each time the package is rebuilt, the md5 sums of the new data objects are compared against the DATADIGEST.
- If they don't match, the build process checks that the `DataVersion` string has been incremented in the `DESCRIPTION` file.
- If it has not the build process will exit and produce an error message.

#### DATADIGEST


The `DATADIGEST` file contains the following:


```
DataVersion: 0.1.0
cars_over_20: 3ccb5b0aaa74fe7cfc0d3ca6ab0b5cf3
```


#### DESCRIPTION

The description file has the new `DataVersion` string.


```
Package: mtcars20
Version: 1.0
Title: What the Package Does (One Line, Title Case)
Description: What the package does (one paragraph).
Authors@R: person("First", "Last", email = "first.last@example.com", role = c("aut", "cre"))
License: What license is it under?
Encoding: UTF-8
LazyData: true
ByteCompile: true
DataVersion: 0.1.0
Date: 2018-07-31
Suggests: 
    knitr,
    rmarkdown
VignetteBuilder: knitr
RoxygenNote: 6.1.0
```




