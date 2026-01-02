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
#' @param response
#' @param tidy
#'
#' @return
#'
#' @examples
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

#' Tidy vectors
#'
#' @param input
#'
#' @return
#'
#' @examples
handle_vectors <- function(input){

  tibble::tibble(data = input$vectors) %>%
  tidyr::unnest_wider(data) %>%
  tidyr::unnest_wider(metadata)

}
