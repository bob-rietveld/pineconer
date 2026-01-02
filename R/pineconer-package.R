#' pineconer: R Interface to the Pinecone Vector Database
#'
#' @description
#' The pineconer package provides a comprehensive R interface to the
#' Pinecone Vector Database API. Pinecone is a managed vector database
#' designed for machine learning applications, enabling similarity search
#' and retrieval augmented generation (RAG) workflows.
#'
#' This package uses the Pinecone Global API (api.pinecone.io) introduced
#' in April 2024.
#'
#' @section Setup:
#' Before using this package, you must set your Pinecone API key as an
#' environment variable. Add the following line to your `~/.Renviron` file:
#'
#' \preformatted{
#' PINECONE_API_KEY=your_api_key
#' }
#'
#' Then restart R or run \code{readRenviron("~/.Renviron")}.
#'
#' @section API Architecture:
#' The Pinecone API has two planes:
#'
#' \strong{Control Plane} (api.pinecone.io):
#' Used for management operations including index and collection CRUD operations.
#'
#' \strong{Data Plane} (index-specific host):
#' Used for vector operations. The host URL is returned when creating or
#' describing an index.
#'
#' @section Index Operations:
#' \itemize{
#'   \item \code{\link{list_indexes}}: List all indexes
#'   \item \code{\link{create_index}}: Create a new index (serverless or pod-based)
#'   \item \code{\link{describe_index}}: Get index configuration and host
#'   \item \code{\link{delete_index}}: Delete an index
#'   \item \code{\link{configure_index}}: Update index configuration
#' }
#'
#' @section Collection Operations:
#' \itemize{
#'   \item \code{\link{list_collections}}: List all collections
#'   \item \code{\link{create_collection}}: Create collection from index
#'   \item \code{\link{describe_collection}}: Get collection details
#'   \item \code{\link{delete_collection}}: Delete a collection
#' }
#'
#' @section Vector Operations:
#' \itemize{
#'   \item \code{\link{vector_query}}: Query vectors by similarity
#'   \item \code{\link{vector_upsert}}: Insert or update vectors
#'   \item \code{\link{vector_fetch}}: Fetch vectors by ID
#'   \item \code{\link{vector_update}}: Update vector values or metadata
#'   \item \code{\link{vector_delete}}: Delete vectors
#'   \item \code{\link{describe_index_stats}}: Get index statistics
#' }
#'
#' @section Response Structure:
#' All API functions return a list with three components:
#' \describe{
#'   \item{http}{Raw httr response object}
#'   \item{content}{Parsed response content (NULL on error)}
#'   \item{status_code}{HTTP status code}
#' }
#'
#' Vector operations support \code{tidy = TRUE} (default) to return
#' cleaned tibble output.
#'
#' @examples
#' \dontrun{
#' # List all indexes
#' indexes <- list_indexes()
#' indexes$content
#'
#' # Create a serverless index
#' create_index(
#'   name = "my-index",
#'   dimension = 1536,
#'   metric = "cosine",
#'   spec = list(serverless = list(cloud = "aws", region = "us-east-1"))
#' )
#'
#' # Query vectors
#' results <- vector_query(
#'   index = "my-index",
#'   vector = rep(0.1, 1536),
#'   top_k = 10
#' )
#' }
#'
#' @importFrom httr GET POST DELETE PATCH modify_url status_code content
#'   accept_json content_type_json add_headers
#' @importFrom assertthat assert_that
#' @importFrom tibble tibble
#' @importFrom tidyr unnest_wider
#' @importFrom jsonlite toJSON
#'
#' @keywords internal
"_PACKAGE"
