
<!-- README.md is generated from README.Rmd. Please edit that file -->

# pineconer

<!-- badges: start -->
[![R-CMD-check](https://img.shields.io/badge/R--CMD--check-passing-brightgreen)](https://github.com/bob-rietveld/pineconer)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
<!-- badges: end -->

`pineconer` provides a comprehensive R interface to the [Pinecone Vector Database](https://www.pinecone.io/) API. Pinecone is a managed vector database designed for machine learning applications, enabling similarity search and retrieval augmented generation (RAG) workflows.

This package uses the **Pinecone Global API** (`api.pinecone.io`) introduced in April 2024.

## Features

- **Index Management**: Create, configure, describe, and delete indexes (serverless and pod-based)
- **Collection Operations**: Create snapshots of indexes for backup and restoration
- **Vector Operations**: Query, upsert, fetch, update, and delete vectors
- **Tidy Output**: Vector operations return clean tibble format by default
- **Metadata Filtering**: Filter queries using Pinecone's metadata query language

## Installation

You can install the development version of pineconer from GitHub:

``` r
# install.packages("remotes")
remotes::install_github("bob-rietveld/pineconer")
```

## Configuration

Before using `pineconer`, set your Pinecone API key as an environment variable. The easiest way is to add it to your `~/.Renviron` file:

``` r
# Open your .Renviron file
usethis::edit_r_environ()
```

Then add:

```
PINECONE_API_KEY=your_api_key_here
```

Restart R or reload the environment:

``` r
readRenviron("~/.Renviron")
```

**Note**: The `PINECONE_ENVIRONMENT` variable is no longer required with the new Global API.

## Quick Start

``` r
library(pineconer)

# List all indexes
list_indexes()

# Create a serverless index
create_index(
  name = "my-index",
  dimension = 1536,
  metric = "cosine",
  spec = list(serverless = list(cloud = "aws", region = "us-east-1"))
)

# Upsert vectors
vectors <- list(
  list(id = "vec1", values = runif(1536), metadata = list(category = "A")),
  list(id = "vec2", values = runif(1536), metadata = list(category = "B"))
)
vector_upsert("my-index", vectors = vectors)

# Query similar vectors
results <- vector_query(
  index = "my-index",
  vector = runif(1536),
  top_k = 5
)
print(results$content)
```

## API Overview

### Index Operations

Manage your Pinecone indexes:

``` r
# List all indexes
list_indexes()

# Create a serverless index (recommended)
create_index(
  name = "my-index",
  dimension = 1536,
  metric = "cosine",
  spec = list(serverless = list(cloud = "aws", region = "us-east-1"))
)

# Create a pod-based index
create_index(
  name = "my-pod-index",
  dimension = 1536,
  metric = "euclidean",
  spec = list(pod = list(
    environment = "us-east-1-aws",
    pod_type = "p1.x1",
    pods = 1
  ))
)

# Get index details (including host for data operations)
index_info <- describe_index("my-index")
print(index_info$content$host)

# Configure index (pod-based only)
configure_index("my-pod-index", replicas = 2, pod_type = "p1.x2")

# Enable deletion protection
configure_index("my-index", deletion_protection = "enabled")

# Delete an index
delete_index("my-index")
```

### Collection Operations

Collections are static snapshots of an index:

``` r
# List all collections
list_collections()

# Create a collection from an index
create_collection(name = "my-backup", source = "my-index")

# Get collection details
describe_collection("my-backup")

# Delete a collection
delete_collection("my-backup")
```

### Vector Operations

Work with vectors in your index:

``` r
# Get index statistics
stats <- describe_index_stats("my-index")
print(stats$content$totalVectorCount)

# Upsert vectors (insert or update)
vectors <- list(
  list(
    id = "doc1",
    values = runif(1536),
    metadata = list(
      title = "Introduction to ML",
      category = "tutorial",
      year = 2024
    )
  ),
  list(
    id = "doc2",
    values = runif(1536),
    metadata = list(
      title = "Advanced NLP",
      category = "research",
      year = 2024
    )
  )
)
vector_upsert("my-index", vectors = vectors)

# Query vectors by similarity
results <- vector_query(
  index = "my-index",
  vector = runif(1536),
  top_k = 10,
  include_metadata = TRUE
)
# Results returned as tidy tibble
print(results$content)

# Query with metadata filter
results <- vector_query(
  index = "my-index",
  vector = runif(1536),
  top_k = 5,
  filter = list(category = list(`$eq` = "tutorial"))
)

# Fetch specific vectors by ID
fetched <- vector_fetch("my-index", ids = c("doc1", "doc2"))
print(fetched$content)

# Update vector metadata
vector_update(
  index = "my-index",
  vector_id = "doc1",
  meta_data = list(category = "updated", reviewed = TRUE)
)

# Delete specific vectors
vector_delete("my-index", ids = c("doc1", "doc2"))

# Delete all vectors in a namespace
vector_delete("my-index", delete_all = TRUE, name_space = "old-data")
```

### Working with Namespaces

Namespaces partition vectors within an index:

``` r
# Upsert to a specific namespace
vector_upsert("my-index", vectors = vectors, name_space = "production")

# Query within a namespace
results <- vector_query(
  index = "my-index",
  vector = runif(1536),
  top_k = 5,
  name_space = "production"
)

# Fetch from a namespace
fetched <- vector_fetch("my-index", ids = c("doc1"), namespace = "production")
```

## Response Structure

All API functions return a consistent structure:

``` r
result <- list_indexes()

# HTTP response object
result$http

# Parsed content (NULL on error)
result$content

# HTTP status code
result$status_code
```

Common status codes:
- `200`: Success
- `201`: Created (for create operations)
- `202`: Accepted (for delete operations)
- `400`: Bad request
- `401`: Unauthorized (check API key)
- `404`: Not found
- `409`: Conflict (resource already exists)
- `500`: Internal server error

## Error Handling

``` r
result <- describe_index("non-existent-index")

if (result$status_code != 200) {
  message("Error: ", result$status_code)
  # Get detailed error from response
  error_detail <- httr::content(result$http)
  print(error_detail)
}
```

## Supported Metrics

When creating an index, you can choose from:
- `cosine` (default): Cosine similarity
- `euclidean`: Euclidean distance
- `dotproduct`: Dot product similarity

## Pod Types

For pod-based indexes, available pod types are:
- **s1**: Storage-optimized (`s1.x1`, `s1.x2`, `s1.x4`, `s1.x8`)
- **p1**: Performance-optimized (`p1.x1`, `p1.x2`, `p1.x4`, `p1.x8`)
- **p2**: Second-gen performance (`p2.x1`, `p2.x2`, `p2.x4`, `p2.x8`)

## Dependencies

- [httr](https://httr.r-lib.org/): HTTP requests
- [assertthat](https://github.com/hadley/assertthat): Input validation
- [glue](https://glue.tidyverse.org/): String interpolation
- [tibble](https://tibble.tidyverse.org/): Modern data frames
- [tidyr](https://tidyr.tidyverse.org/): Data tidying
- [jsonlite](https://jeroen.r-universe.dev/jsonlite): JSON encoding

## Additional Resources

- [Pinecone Documentation](https://docs.pinecone.io/)
- [Pinecone API Reference](https://docs.pinecone.io/reference/api/introduction)
- [Package Vignette](vignettes/getting-started.Rmd): Detailed tutorial with iris dataset example

## License

MIT
