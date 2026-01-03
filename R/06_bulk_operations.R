#' List Import Operations
#'
#' Lists all recent and ongoing import operations for an index.
#'
#' @param index Name of the index
#' @param limit Maximum number of operations to return (default: 100)
#' @param pagination_token Token for fetching the next page of results
#'
#' @return List with http response, content (import operations), and status_code.
#'   Content includes:
#'   - data: list of import operations with id, status, uri, etc.
#'   - pagination: list with next token if more results exist
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # List recent imports
#' result <- list_imports("my-index")
#'
#' # Paginate through results
#' result <- list_imports("my-index", limit = 10)
#' if (!is.null(result$content$pagination$next)) {
#'   next_page <- list_imports("my-index",
#'     pagination_token = result$content$pagination$next)
#' }
#' }
list_imports <- function(index, limit = 100, pagination_token = NULL) {

  # assertions
  assertthat::assert_that(!missing(index), msg = "Please provide an index name.")

  # get index host
  temp_index <- describe_index(index_name = index)
  host <- get_index_host(temp_index)

  # get URL using data plane
  pinecone_url <- get_data_plane_url(host, "bulk/imports")

  # get token
  pinecone_token <- get_api_key()

  # build query params
  query_params <- list(limit = limit)

  if (!is.null(pagination_token)) {
    query_params$paginationToken <- pagination_token
  }

  # get response
  response <- httr::GET(
    pinecone_url,
    query = query_params,
    httr::accept_json(),
    httr::add_headers(`Api-Key` = pinecone_token)
  )

  result <- handle_respons(response)

  return(result)

}


#' Start Bulk Import
#'
#' Starts an asynchronous import operation to load vectors from object storage
#' (S3 or GCS) into a Pinecone index.
#'
#' @param index Name of the index to import into
#' @param uri The URI of the data to import. Supported formats:
#'   - S3: "s3://bucket-name/path/to/data/"
#'   - GCS: "gs://bucket-name/path/to/data/"
#' @param integration_id Optional ID of the storage integration to use for authentication
#' @param error_mode How to handle errors during import:
#'   - "continue": Skip failed records and continue (default)
#'   - "abort": Stop the import on first error
#'
#' @return List with http response, content (import operation details), and status_code.
#'   Content includes:
#'   - id: Unique identifier for the import operation
#'   - status: Current status (e.g., "Pending", "InProgress")
#'
#' @details
#' The data files must be in Parquet format with the following schema:
#' - id (string): Unique vector ID
#' - values (list of floats): Vector values
#' - sparse_values (optional): Sparse vector data
#' - metadata (optional): Key-value metadata
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Import from S3
#' result <- start_import(
#'   index = "my-index",
#'   uri = "s3://my-bucket/vectors/"
#' )
#'
#' # Check the import ID
#' import_id <- result$content$id
#'
#' # Import with error handling
#' result <- start_import(
#'   index = "my-index",
#'   uri = "s3://my-bucket/vectors/",
#'   error_mode = "abort"
#' )
#' }
start_import <- function(index, uri, integration_id = NULL, error_mode = "continue") {

  # assertions
  assertthat::assert_that(!missing(index), msg = "Please provide an index name.")
  assertthat::assert_that(!missing(uri), msg = "Please provide a URI.")
  assertthat::assert_that(
    error_mode %in% c("continue", "abort"),
    msg = "error_mode must be 'continue' or 'abort'."
  )

  # get index host
  temp_index <- describe_index(index_name = index)
  host <- get_index_host(temp_index)

  # get URL using data plane
  pinecone_url <- get_data_plane_url(host, "bulk/imports")

  # get token
  pinecone_token <- get_api_key()

  # Build request body
  body <- list(
    uri = uri,
    errorMode = list(onError = error_mode)
  )

  # Add integration_id if provided
  if (!is.null(integration_id)) {
    body$integrationId <- integration_id
  }

  # get response
  response <- httr::POST(
    pinecone_url,
    body = jsonlite::toJSON(body, auto_unbox = TRUE),
    encode = "raw",
    httr::accept_json(),
    httr::content_type_json(),
    httr::add_headers(`Api-Key` = pinecone_token)
  )

  result <- handle_respons(response)

  return(result)

}


#' Describe Import Operation
#'
#' Retrieves details about a specific import operation.
#'
#' @param index Name of the index
#' @param import_id The ID of the import operation to describe
#'
#' @return List with http response, content (import details), and status_code.
#'   Content includes:
#'   - id: Import operation ID
#'   - uri: Source URI
#'   - status: Current status ("Pending", "InProgress", "Completed", "Failed", "Cancelled")
#'   - createdAt: Timestamp when import was created
#'   - finishedAt: Timestamp when import finished (if complete)
#'   - percentComplete: Progress percentage
#'   - recordsImported: Number of records successfully imported
#'   - error: Error message (if failed)
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Start an import
#' import_result <- start_import("my-index", "s3://bucket/data/")
#' import_id <- import_result$content$id
#'
#' # Check status
#' status <- describe_import("my-index", import_id)
#' print(status$content$status)
#' print(status$content$percentComplete)
#' }
describe_import <- function(index, import_id) {

  # assertions
  assertthat::assert_that(!missing(index), msg = "Please provide an index name.")
  assertthat::assert_that(!missing(import_id), msg = "Please provide an import ID.")

  # get index host
  temp_index <- describe_index(index_name = index)
  host <- get_index_host(temp_index)

  # get URL using data plane
  path <- glue::glue("bulk/imports/{import_id}")
  pinecone_url <- get_data_plane_url(host, path)

  # get token
  pinecone_token <- get_api_key()

  # get response
  response <- httr::GET(
    pinecone_url,
    httr::accept_json(),
    httr::add_headers(`Api-Key` = pinecone_token)
  )

  result <- handle_respons(response)

  return(result)

}


#' Cancel Import Operation
#'
#' Cancels an import operation if it has not yet completed.
#'
#' @param index Name of the index
#' @param import_id The ID of the import operation to cancel
#'
#' @return List with http response, content, and status_code.
#'   - 200: Import was successfully cancelled
#'   - 404: Import not found
#'   - 500: Internal error
#'
#' @details
#' Only imports with status "Pending" or "InProgress" can be cancelled.
#' Completed, failed, or already cancelled imports cannot be cancelled.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Start an import
#' import_result <- start_import("my-index", "s3://bucket/data/")
#' import_id <- import_result$content$id
#'
#' # Cancel it
#' cancel_import("my-index", import_id)
#' }
cancel_import <- function(index, import_id) {

  # assertions
  assertthat::assert_that(!missing(index), msg = "Please provide an index name.")
  assertthat::assert_that(!missing(import_id), msg = "Please provide an import ID.")

  # get index host
  temp_index <- describe_index(index_name = index)
  host <- get_index_host(temp_index)

  # get URL using data plane
  path <- glue::glue("bulk/imports/{import_id}")
  pinecone_url <- get_data_plane_url(host, path)

  # get token
  pinecone_token <- get_api_key()

  # get response
  response <- httr::DELETE(
    pinecone_url,
    httr::accept_json(),
    httr::add_headers(`Api-Key` = pinecone_token)
  )

  result <- handle_respons(response)

  return(result)

}
