
#' List Indexes
#'
#' Lists all indexes in your Pinecone project.
#'
#' @return List with http response, content (list of indexes), and status_code
#' @export
#'
#' @examples
#' \dontrun{
#' list_indexes()
#' }
list_indexes <- function(){

  # get URL (new global API endpoint)
  pinecone_url <- get_control_plane_url("indexes")

  # get token
  pinecone_token <- get_api_key()

  # get response
  response <- httr::GET( pinecone_url,
                         httr::accept_json(),
                         httr::add_headers( `Api-Key`= pinecone_token )
                         )

  result <- handle_respons(response)

  return(result)

}

#' Create Index
#'
#' Creates a new Pinecone index. Supports both serverless and pod-based indexes.
#'
#' @param name Name of the index (must be unique within project)
#' @param dimension Dimension of vectors to be stored
#' @param metric Distance metric: "cosine", "euclidean", or "dotproduct" (default: "cosine")
#' @param spec Index specification - either serverless or pod configuration (see details)
#' @param deletion_protection Whether to enable deletion protection ("enabled" or "disabled")
#'
#' @details
#' The `spec` parameter should be a list containing either:
#'
#' For serverless indexes:
#' \code{list(serverless = list(cloud = "aws", region = "us-east-1"))}
#'
#' For pod-based indexes:
#' \code{list(pod = list(environment = "us-east-1-aws", pod_type = "p1.x1", pods = 1))}
#'
#' @return List with http response, content (index details including host), and status_code
#' @export
#'
#' @examples
#' \dontrun{
#' # Create a serverless index
#' create_index(
#'   name = "my-index",
#'   dimension = 1536,
#'   metric = "cosine",
#'   spec = list(serverless = list(cloud = "aws", region = "us-east-1"))
#' )
#'
#' # Create a pod-based index
#' create_index(
#'   name = "my-pod-index",
#'   dimension = 1536,
#'   metric = "cosine",
#'   spec = list(pod = list(environment = "us-east-1-aws", pod_type = "p1.x1", pods = 1))
#' )
#' }
create_index <- function(name, dimension, metric = "cosine", spec = NULL, deletion_protection = "disabled"){

  # get URL (new global API endpoint)
  pinecone_url <- get_control_plane_url("indexes")

  # get token
  pinecone_token <- get_api_key()

  # Build request body according to new API spec
  body <- list(
    name = name,
    dimension = dimension,
    metric = metric
  )

  # Add spec if provided
  if (!is.null(spec)) {
    body$spec <- spec
  }

  # Add deletion protection if specified
  if (!is.null(deletion_protection)) {
    body$deletion_protection <- deletion_protection
  }

  # get response
  response <- httr::POST( pinecone_url,
                          body = body,
                          encode = "json",
                          httr::accept_json(),
                          httr::content_type_json(),
                          httr::add_headers( `Api-Key`= pinecone_token )
  )

  result <- handle_respons(response)

  return(result)

}


#' Describe Index
#'
#' Returns configuration information and deployment status of an index.
#'
#' @param index_name Name of the index to describe
#'
#' @return List with http response, content (index configuration including host), and status_code
#'
#' The content includes:
#' - name: Index name
#' - dimension: Vector dimension
#' - metric: Distance metric
#' - host: Data plane host URL for vector operations
#' - status: Index status (ready, etc.)
#' - spec: Index specification (serverless or pod config)
#'
#' @export
#'
#' @examples
#' \dontrun{
#' describe_index("my-index")
#' }
describe_index <- function(index_name){

  # get token
  pinecone_token <- get_api_key()

  # set path (new API uses "indexes" not "databases")
  path <- glue::glue("indexes/{index_name}")

  # get url (new global API)
  pinecone_url <- get_control_plane_url(set_path = path)

  # get response
  response <- httr::GET( pinecone_url,
                         httr::accept_json(),
                         httr::add_headers( `Api-Key`= pinecone_token ) )

  # parse result
  result <- handle_respons(response)

  return(result)

}

#' Delete Index
#'
#' Deletes an existing index.
#'
#' @param index_name Name of the index to delete
#'
#' @return List with http response, content, and status_code
#' - 202: The index has been successfully deleted
#' - 404: Index not found
#' - 500: Internal error
#'
#' @export
#'
#' @examples
#' \dontrun{
#' delete_index("my-index")
#' }
delete_index <- function(index_name){

  # get token
  pinecone_token <- get_api_key()

  # set path (new API uses "indexes" not "databases")
  path <- glue::glue("indexes/{index_name}")

  # get url (new global API)
  pinecone_url <- get_control_plane_url(set_path = path)

  # get response
  response <- httr::DELETE( pinecone_url,
                            httr::add_headers( `Api-Key`= pinecone_token ) )

  # parse result
  result <- handle_respons(response)

  return(result)

}

#' Configure Index
#'
#' Updates index configuration. For pod-based indexes, can change replicas and pod type.
#' For all indexes, can update deletion protection.
#'
#' @param index_name Name of the index to configure
#' @param replicas Integer. The desired number of replicas for the index (pod-based only)
#' @param pod_type The new pod type. One of s1, p1, or p2 appended with . and one of x1, x2, x4, or x8 (pod-based only)
#' @param deletion_protection Whether to enable deletion protection ("enabled" or "disabled")
#'
#' @return List with http response, content, and status_code
#' @export
#'
#' @examples
#' \dontrun{
#' # Update pod configuration
#' configure_index("my-index", replicas = 2, pod_type = "p1.x2")
#'
#' # Enable deletion protection
#' configure_index("my-index", deletion_protection = "enabled")
#' }
configure_index <- function(index_name, replicas = NULL, pod_type = NULL, deletion_protection = NULL){

  # assertions
  if (!is.null(replicas)) {
    assertthat::assert_that(is.numeric(replicas), msg = "Replicas must be numeric")
  }

  if (!is.null(pod_type)) {
    pod_list <- c("s1.x1","p1.x1","p2.x1","s1.x2","p1.x2","p2.x2","s1.x4","p1.x4","p2.x4","s1.x8","p1.x8","p2.x8")
    error_msg <- glue::glue("Pod type must be one of: {paste(pod_list, collapse = ', ')}")
    assertthat::assert_that(pod_type %in% pod_list, msg = error_msg)
  }

  # get token
  pinecone_token <- get_api_key()

  # set path (new API uses "indexes" not "databases")
  path <- glue::glue("indexes/{index_name}")

  # get url (new global API)
  pinecone_url <- get_control_plane_url(set_path = path)

  # Build body according to new API spec
  body <- list()

  # Pod-specific configuration
  if (!is.null(replicas) || !is.null(pod_type)) {
    spec <- list(pod = list())
    if (!is.null(replicas)) spec$pod$replicas <- replicas
    if (!is.null(pod_type)) spec$pod$pod_type <- pod_type
    body$spec <- spec
  }

  # Deletion protection (applies to all index types)
  if (!is.null(deletion_protection)) {
    body$deletion_protection <- deletion_protection
  }

  # get response
  response <- httr::PATCH( pinecone_url,
                           body = body,
                           encode = "json",
                           httr::accept_json(),
                           httr::content_type_json(),
                           httr::add_headers( `Api-Key`= pinecone_token ) )

  # parse result
  result <- handle_respons(response)

  return(result)

}
