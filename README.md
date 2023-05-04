
<!-- README.md is generated from README.Rmd. Please edit that file -->

# Pineconer

<!-- badges: start -->
<!-- badges: end -->

The goal of pineconer is to provide a way to store and access vectors
using the Pincone API

## Installation

You can install the development version of pineconer like so:

``` r
# FILL THIS IN! HOW CAN PEOPLE INSTALL YOUR DEV PACKAGE?
```

## Configuration

You can set the API key and region in your env file.
usethis::edit_r\_environ() is a convenient way to open the file. Next
set the following two variables.

PINECONE_API_KEY = “YOUR API KEY” PINECONE_ENVIRONMENT = “PINECONE
Region”

## Collection Operations

Pincone API support the following index operations, the are implemented
like for like in the pineconer package.

``` r

# list collections
  list_collections()

# create collection
  create_collection("xxx","xxx")
  
# describe collection
  describe_collection(collection_name = "xxx")
  
# delete collection
  delete_collection("xxx")
```

## Index Operations

``` r
  # list indexes
    list_indexes()
  
  # create index
    create_index("xxx")
  
  # describe index
    describe_index("help")
  
  # delete index
    delete_index("xxx")
    
  # configure index
    configure_index(index_name = "xxx", 
                    replica  = 1, 
                    pod_type = "s1.x2")
  
```

## Vector Operations

``` r
 # describe index stats
     stats <- describe_index_stats( index_name = "help", 
                                    project_name = "xxx",
                                    filter = list( language = "english")
                                   )
 # query

 # delete

 # fetch

 # update

 # upsert
```
