# =============================================================================
# Pinecone Assistant API - File Operations
# =============================================================================
#
# This file implements the Pinecone Assistant API for file management.
# Files can be uploaded to an assistant for RAG (retrieval-augmented generation).
#
# API Documentation: https://docs.pinecone.io/guides/assistant/manage-files
#
# Data Plane (assistant host, e.g., prod-1-data.ke.pinecone.io):
#   - POST   /assistant/files/{assistant_name}           - Upload file
#   - GET    /assistant/files/{assistant_name}           - List files
#   - GET    /assistant/files/{assistant_name}/{file_id} - Describe file
#   - DELETE /assistant/files/{assistant_name}/{file_id} - Delete file
#
# =============================================================================


#' List Files in Assistant
#'
#' Lists all files uploaded to an assistant.
#'
#' @param assistant_name Name of the assistant
#' @param filter Optional metadata filter to limit results (list).
#'   Uses MongoDB-style query operators ($eq, $ne, $in, $nin, etc.)
#'
#' @return List with http response, content (list of files), and status_code.
#'   Content includes a "files" list where each file has:
#'   - id: File UUID
#'   - name: File name
#'   - status: File status ("Processing", "Available", "Failed")
#'   - size: File size in bytes
#'   - metadata: File metadata (if set)
#'   - created_on: Creation timestamp
#'   - updated_on: Last update timestamp
#'   - percent_done: Processing progress (0.0 to 1.0)
#'   - error_message: Error message (if status is "Failed")
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # List all files
#' assistant_list_files("my-assistant")
#'
#' # List files with metadata filter
#' assistant_list_files("my-assistant", filter = list(document_type = "manuscript"))
#' }
assistant_list_files <- function(assistant_name, filter = NULL) {

  # assertions
  assertthat::assert_that(!missing(assistant_name), msg = "Please provide an assistant name.")

  # get token
  pinecone_token <- get_api_key()

  # Get assistant host
  assistant_info <- describe_assistant(assistant_name)
  host <- get_assistant_host(assistant_info)

  # set path
  path <- glue::glue("assistant/files/{assistant_name}")

  # get url
  pinecone_url <- get_assistant_data_url(host, set_path = path)

  # Build query params for filter
  query_params <- list()
  if (!is.null(filter)) {
    # URL encode the filter JSON
    query_params$filter <- jsonlite::toJSON(filter, auto_unbox = TRUE)
  }

  # get response
  if (length(query_params) > 0) {
    response <- httr::GET(
      pinecone_url,
      query = query_params,
      httr::accept_json(),
      httr::add_headers(`Api-Key` = pinecone_token)
    )
  } else {
    response <- httr::GET(
      pinecone_url,
      httr::accept_json(),
      httr::add_headers(`Api-Key` = pinecone_token)
    )
  }

  result <- handle_respons(response)

  return(result)

}


#' Upload File to Assistant
#'
#' Uploads a file from the local filesystem to an assistant for processing.
#' The assistant will process the file for use in RAG operations.
#'
#' @param assistant_name Name of the assistant
#' @param file_path Path to the local file to upload
#' @param metadata Optional metadata to attach to the file (named list)
#' @param multimodal Optional flag to enable multimodal processing (PDFs only).
#'   When TRUE, images in PDFs are processed for visual context.
#'
#' @return List with http response, content (file details), and status_code.
#'   Content includes:
#'   - id: File UUID
#'   - name: File name
#'   - status: File status ("Processing" initially, then "Available" or "Failed")
#'   - size: File size in bytes
#'   - metadata: File metadata
#'   - created_on: Creation timestamp
#'   - updated_on: Last update timestamp
#'   - percent_done: Processing progress
#'
#' @details
#' Supported file types include: PDF, TXT, MD, JSON, and more.
#' File processing may take several minutes depending on file size.
#' Use \code{assistant_describe_file()} to check processing status.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Upload a file
#' assistant_upload_file("my-assistant", "/path/to/document.pdf")
#'
#' # Upload with metadata
#' assistant_upload_file(
#'   assistant_name = "my-assistant",
#'   file_path = "/path/to/document.pdf",
#'   metadata = list(company = "acme", document_type = "report")
#' )
#'
#' # Upload PDF with multimodal processing (for images in PDF)
#' assistant_upload_file(
#'   assistant_name = "my-assistant",
#'   file_path = "/path/to/document.pdf",
#'   multimodal = TRUE
#' )
#' }
assistant_upload_file <- function(assistant_name, file_path, metadata = NULL, multimodal = NULL) {

  # assertions
  assertthat::assert_that(!missing(assistant_name), msg = "Please provide an assistant name.")
  assertthat::assert_that(!missing(file_path), msg = "Please provide a file path.")
  assertthat::assert_that(file.exists(file_path), msg = "File does not exist at the specified path.")

  # get token
  pinecone_token <- get_api_key()

  # Get assistant host
  assistant_info <- describe_assistant(assistant_name)
  host <- get_assistant_host(assistant_info)

  # set path
  path <- glue::glue("assistant/files/{assistant_name}")

  # get url
  pinecone_url <- get_assistant_data_url(host, set_path = path)

  # Build query params
  query_params <- list()
  if (!is.null(metadata)) {
    query_params$metadata <- jsonlite::toJSON(metadata, auto_unbox = TRUE)
  }
  if (!is.null(multimodal)) {
    query_params$multimodal <- tolower(as.character(multimodal))
  }

  # Add query params to URL if present
  if (length(query_params) > 0) {
    pinecone_url <- httr::modify_url(pinecone_url, query = query_params)
  }

  # get response - multipart form upload
  response <- httr::POST(
    pinecone_url,
    body = list(file = httr::upload_file(file_path)),
    encode = "multipart",
    httr::add_headers(`Api-Key` = pinecone_token)
  )

  result <- handle_respons(response)

  return(result)

}


#' Describe File in Assistant
#'
#' Gets the status and metadata of a file uploaded to an assistant.
#'
#' @param assistant_name Name of the assistant
#' @param file_id UUID of the file to describe
#' @param include_url Whether to include a signed URL for the file (default: FALSE)
#'
#' @return List with http response, content (file details), and status_code.
#'   Content includes:
#'   - id: File UUID
#'   - name: File name
#'   - status: File status ("Processing", "Available", "Failed")
#'   - size: File size in bytes
#'   - metadata: File metadata
#'   - created_on: Creation timestamp
#'   - updated_on: Last update timestamp
#'   - percent_done: Processing progress
#'   - signed_url: Signed URL for download (if include_url = TRUE)
#'   - error_message: Error message (if status is "Failed")
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Get file status
#' assistant_describe_file("my-assistant", "070513b3-022f-4966-b583-a9b12e0290ff")
#'
#' # Get file with signed download URL
#' assistant_describe_file(
#'   "my-assistant",
#'   "070513b3-022f-4966-b583-a9b12e0290ff",
#'   include_url = TRUE
#' )
#' }
assistant_describe_file <- function(assistant_name, file_id, include_url = FALSE) {

  # assertions
  assertthat::assert_that(!missing(assistant_name), msg = "Please provide an assistant name.")
  assertthat::assert_that(!missing(file_id), msg = "Please provide a file ID.")

  # get token
  pinecone_token <- get_api_key()

  # Get assistant host
  assistant_info <- describe_assistant(assistant_name)
  host <- get_assistant_host(assistant_info)

  # set path
  path <- glue::glue("assistant/files/{assistant_name}/{file_id}")

  # get url
  pinecone_url <- get_assistant_data_url(host, set_path = path)

  # Build query params
  query_params <- list()
  if (include_url) {
    query_params$include_url <- "true"
  }

  # get response
  if (length(query_params) > 0) {
    response <- httr::GET(
      pinecone_url,
      query = query_params,
      httr::accept_json(),
      httr::add_headers(`Api-Key` = pinecone_token)
    )
  } else {
    response <- httr::GET(
      pinecone_url,
      httr::accept_json(),
      httr::add_headers(`Api-Key` = pinecone_token)
    )
  }

  result <- handle_respons(response)

  return(result)

}


#' Delete File from Assistant
#'
#' Deletes a file from an assistant.
#'
#' @param assistant_name Name of the assistant
#' @param file_id UUID of the file to delete
#'
#' @return List with http response, content, and status_code.
#'   - 200: The file has been successfully deleted
#'   - 404: File not found
#'   - 500: Internal error
#'
#' @export
#'
#' @examples
#' \dontrun{
#' assistant_delete_file("my-assistant", "070513b3-022f-4966-b583-a9b12e0290ff")
#' }
assistant_delete_file <- function(assistant_name, file_id) {

  # assertions
  assertthat::assert_that(!missing(assistant_name), msg = "Please provide an assistant name.")
  assertthat::assert_that(!missing(file_id), msg = "Please provide a file ID.")

  # get token
  pinecone_token <- get_api_key()

  # Get assistant host
  assistant_info <- describe_assistant(assistant_name)
  host <- get_assistant_host(assistant_info)

  # set path
  path <- glue::glue("assistant/files/{assistant_name}/{file_id}")

  # get url
  pinecone_url <- get_assistant_data_url(host, set_path = path)

  # get response
  response <- httr::DELETE(
    pinecone_url,
    httr::add_headers(`Api-Key` = pinecone_token)
  )

  result <- handle_respons(response)

  return(result)

}
