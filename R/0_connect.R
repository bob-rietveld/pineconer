#' Get Api Key
#'
#' @return API key string
#' @export
#'
#' @examples
#' \dontrun{
#' get_api_key()
#' }
get_api_key <- function() {

  # check for credentials
  pinecone_token = Sys.getenv('PINECONE_API_KEY')

  # check for path
  if (pinecone_token == '') stop(sprintf('variable %s missing from file ~/.Renviron', 'PINECONE_API_KEY'))

  return(pinecone_token)

}


#' Get Pinecone Control Plane URL
#'
#' Constructs URLs for Pinecone's global control plane API (api.pinecone.io).
#' This is used for index and collection management operations.
#'
#' @param set_path API path (e.g., "indexes", "collections")
#'
#' @return Full URL string for the control plane API
#' @export
#'
#' @examples
#' \dontrun{
#' get_control_plane_url("indexes")
#' }
get_control_plane_url <- function(set_path = NA) {

 # Base URL for global API (no environment needed)
  pinecone_api_url <- "https://api.pinecone.io/"

  if(!is.na(set_path)){
    # create url
    pinecone_api_url <- httr::modify_url(pinecone_api_url, path = set_path)
  }

  return(pinecone_api_url)

}


#' Get Pinecone Inference API URL
#'
#' Constructs URLs for Pinecone's Inference API (api.pinecone.io).
#' This is used for embedding and reranking operations.
#'
#' @param set_path API path (e.g., "embed", "rerank")
#'
#' @return Full URL string for the inference API
#' @export
#'
#' @examples
#' \dontrun{
#' get_inference_url("embed")
#' get_inference_url("rerank")
#' }
get_inference_url <- function(set_path = NA) {

  # Base URL for inference API (same host as control plane)
  pinecone_api_url <- "https://api.pinecone.io/"

  if(!is.na(set_path)){
    # create url
    pinecone_api_url <- httr::modify_url(pinecone_api_url, path = set_path)
  }

  return(pinecone_api_url)

}


#' Get Pinecone Assistant Control Plane URL
#'
#' Constructs URLs for Pinecone's Assistant control plane API (api.pinecone.io).
#' This is used for assistant management operations (create, list, describe, delete, update).
#'
#' @param set_path API path (e.g., "assistant/assistants", "assistant/assistants/my-assistant")
#'
#' @return Full URL string for the assistant control plane API
#' @export
#'
#' @examples
#' \dontrun{
#' get_assistant_control_url("assistant/assistants")
#' get_assistant_control_url("assistant/assistants/my-assistant")
#' }
get_assistant_control_url <- function(set_path = NA) {

  # Base URL for assistant control plane API
  pinecone_api_url <- "https://api.pinecone.io/"

  if(!is.na(set_path)){
    # create url
    pinecone_api_url <- httr::modify_url(pinecone_api_url, path = set_path)
  }

  return(pinecone_api_url)

}


#' Get Pinecone Assistant Data Plane URL
#'
#' Constructs URLs for Pinecone's Assistant data plane API.
#' This is used for file operations and chat operations.
#' The data plane host is typically returned when creating/describing an assistant.
#'
#' @param host The assistant data plane host (e.g., "prod-1-data.ke.pinecone.io")
#' @param set_path API path (e.g., "assistant/files/my-assistant", "assistant/chat/my-assistant")
#'
#' @return Full URL string for the assistant data plane API
#' @export
#'
#' @examples
#' \dontrun{
#' get_assistant_data_url("prod-1-data.ke.pinecone.io", "assistant/files/my-assistant")
#' get_assistant_data_url("prod-1-data.ke.pinecone.io", "assistant/chat/my-assistant")
#' }
get_assistant_data_url <- function(host, set_path = NA) {

  # Remove https:// prefix if present
  host <- gsub("^https://", "", host)

  # Construct base URL from host
  pinecone_api_url <- glue::glue("https://{host}/")

  if(!is.na(set_path)){
    # create url
    pinecone_api_url <- httr::modify_url(pinecone_api_url, path = set_path)
  }

  return(pinecone_api_url)

}


#' Get Assistant Host
#'
#' Extracts the data plane host from an assistant description for data plane operations.
#'
#' @param assistant Assistant description object from describe_assistant()
#'
#' @return Host string for assistant data plane API calls
#' @export
#'
#' @examples
#' \dontrun{
#' assistant <- describe_assistant("my-assistant")
#' host <- get_assistant_host(assistant)
#' }
get_assistant_host <- function(assistant) {

  # Assistant API returns host directly in the response

  host <- assistant$content$host

  if (is.null(host)) {
    stop("Could not extract host from assistant description. Ensure the assistant exists.")
  }

  # Remove https:// prefix if present
  host <- gsub("^https://", "", host)

  return(host)
}


#' Get Pinecone Data Plane URL
#'
#' Constructs URLs for Pinecone's data plane API using the index host.
#' This is used for vector operations (query, upsert, fetch, delete).
#'
#' @param host The index host (e.g., "index-name-abc123.svc.region.pinecone.io")
#' @param set_path API path (e.g., "query", "vectors/upsert")
#'
#' @return Full URL string for the data plane API
#' @export
#'
#' @examples
#' \dontrun{
#' get_data_plane_url("my-index-abc123.svc.us-east-1.pinecone.io", "query")
#' }
get_data_plane_url <- function(host, set_path = NA) {

  # Construct base URL from host
  pinecone_api_url <- glue::glue("https://{host}/")

  if(!is.na(set_path)){
    # create url
    pinecone_api_url <- httr::modify_url(pinecone_api_url, path = set_path)
  }

  return(pinecone_api_url)

}


#' Get Pinecone index url (DEPRECATED)
#'
#' @param controller Controller name (ignored in new API)
#' @param set_path API path
#'
#' @return Full URL string
#' @export
#'
#' @description
#' This function is deprecated. Use `get_control_plane_url()` for control plane
#' operations or `get_data_plane_url()` for vector operations.
#'
#' @examples
#' \dontrun{
#' # Old usage (deprecated):
#' get_url("controller", "databases")
#'
#' # New usage:
#' get_control_plane_url("indexes")
#' }
get_url <- function(controller, set_path = NA) {

  .Deprecated("get_control_plane_url")

  # Map old paths to new paths
  if (!is.na(set_path)) {
    # databases -> indexes
    set_path <- gsub("^databases", "indexes", set_path)
  }

  return(get_control_plane_url(set_path))

}

#' Handle the API Response
#'
#' Parses and standardizes API responses from Pinecone into a consistent format.
#'
#' @param response An httr response object from a Pinecone API call.
#' @param tidy Logical. If TRUE, returns only the parsed content instead of
#'   the full response structure. Default is FALSE.
#'
#' @return A list with three components:
#' \describe{
#'   \item{http}{The raw httr response object}
#'   \item{content}{Parsed response content (NULL if status code is not 200)}
#'   \item{status_code}{HTTP status code of the response}
#' }
#' If \code{tidy = TRUE}, returns only the parsed content directly.
#'
#' @keywords internal
#' @export
#'
#' @examples
#' \dontrun{
#' response <- httr::GET("https://api.pinecone.io/indexes")
#' result <- handle_respons(response)
#' result$status_code
#' result$content
#' }
handle_respons <- function( response , tidy = FALSE ){

  # set response object
  result <- structure( list( http = response,
                             content = NULL,
                             status_code = NULL))

  # handle result
  result$status_code <- httr::status_code(response)

  if (result$status_code != 200) {

    return(result)
  }
  else {

    # set the results
    result$content <- httr::content(response, as = "parsed")
  }

  # simple_results
  if(tidy)
  {
    result <- result$content
  }

  return(result)
}

### UTILS

#' Get Index Host
#'
#' Extracts the full host from an index description for data plane operations.
#'
#' @param index Index description object from describe_index()
#'
#' @return Full host string for data plane API calls
#' @export
#'
#' @examples
#' \dontrun{
#' index <- describe_index("my-index")
#' host <- get_index_host(index)
#' }
get_index_host <- function(index) {

  # New API returns host directly in the response
  host <- index$content$host

  if (is.null(host)) {
    stop("Could not extract host from index description. Ensure the index exists.")
  }

  return(host)
}


#' Get controller (DEPRECATED)
#'
#' @param index Index description object
#' @param vector Ignored
#'
#' @return Host string
#'
#' @description
#' This function is deprecated. Use `get_index_host()` instead.
extract_vector_controller <- function(index, vector = "svc") {

  .Deprecated("get_index_host")

  # Try new API format first
  host <- index$content$host

  # Fall back to old format for compatibility

  if (is.null(host)) {
    host <- index$content$status$host
  }

  if (is.null(host)) {
    stop("Could not extract host from index description.")
  }

  return(host)
}

#' Tidy Vector Data
#'
#' Transforms raw vector data from Pinecone API responses into a tidy tibble format.
#'
#' @param input A list containing a \code{vectors} element from a Pinecone
#'   fetch or query response.
#'
#' @return A tibble with columns for vector IDs, values, and any metadata fields.
#'   Metadata columns are prefixed with their field names.
#'
#' @keywords internal
#' @export
#'
#' @examples
#' \dontrun{
#' result <- vector_fetch("my-index", ids = c("vec1", "vec2"), tidy = FALSE)
#' tidy_vectors <- handle_vectors(result$content)
#' }
handle_vectors <- function(input){

  result <- tibble::tibble(data = input$vectors)
  result <- tidyr::unnest_wider(result, "data")
  result <- tidyr::unnest_wider(result, "metadata")
  result

}
