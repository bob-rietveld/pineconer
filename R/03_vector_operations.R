#' Describe Index Stats
#'
#' Returns statistics about an index, such as vector count and index fullness.
#'
#' @param index_name Name of the index
#' @param filter Optional metadata filter (list)
#'
#' @return List with http response, content (index statistics), and status_code
#' @export
#'
#' @examples
#' \dontrun{
#' describe_index_stats("my-index")
#' }
describe_index_stats <- function(index_name, filter = NULL){

  # assertions
  assertthat::assert_that(!is.na(index_name), msg = "Please provide an index name.")

  # get token
  pinecone_token <- get_api_key()

  # Get index host from describe_index
  index_info <- describe_index(index_name)
  host <- get_index_host(index_info)

  # get url using data plane
  pinecone_url <- get_data_plane_url(host = host, set_path = "describe_index_stats")

  # Build body if filter provided
  body <- NULL
  if (!is.null(filter)) {
    body <- list(filter = filter)
  }

  # get response (POST for data plane)
  if (is.null(body)) {
    response <- httr::POST( pinecone_url,
                            httr::accept_json(),
                            httr::content_type_json(),
                            httr::add_headers( `Api-Key`= pinecone_token )
    )
  } else {
    response <- httr::POST( pinecone_url,
                            body = body,
                            encode = "json",
                            httr::accept_json(),
                            httr::content_type_json(),
                            httr::add_headers( `Api-Key`= pinecone_token )
    )
  }

  result <- handle_respons(response)

  return(result)

}

#' Query Vectors
#'
#' Searches an index using a query vector. Returns the most similar vectors.
#'
#' @param index Name of the index to query
#' @param vector Query vector (numeric vector)
#' @param top_k Number of results to return (default: 5)
#' @param filter Metadata filter (list)
#' @param name_space Namespace to query (default: "")
#' @param include_metadata Whether to include metadata in results (default: TRUE)
#' @param include_values Whether to include vector values in results (default: FALSE)
#' @param tidy Whether to return tidy tibble format (default: TRUE)
#'
#' @return List with http response, content (matches), and status_code
#' @export
#'
#' @examples
#' \dontrun{
#' vector_query("my-index", vector = rep(0.1, 1536), top_k = 10)
#' }
vector_query <- function( index,
                          vector,
                          top_k = 5,
                          filter = list(),
                          name_space = "",
                          include_metadata = TRUE,
                          include_values = FALSE ,
                          tidy = TRUE ){

  # get index host
  temp_index <- describe_index(index_name = index)
  host <- get_index_host(temp_index)

  # get URL using data plane
  pinecone_url <- get_data_plane_url(host, "query")

  # get token
  pinecone_token <- get_api_key()

  # body
  body <- list(
    vector          = vector,
    topK            = top_k,
    includeMetadata = include_metadata,
    includeValues   = include_values,
    namespace       = name_space
  )

  # Only add filter if not empty
  if (length(filter) > 0) {
    body$filter <- filter
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

  if(tidy && result$status_code == 200 && !is.null(result$content$matches)){
    tidy_result <- tibble::tibble(data = result$content$matches)
    tidy_result <- tidyr::unnest_wider(tidy_result, "data")
    tidy_result <- tidyr::unnest_wider(tidy_result, "metadata", names_sep = "_")
    result$content <- tidy_result
  }

  return(result)

}

#' Delete Vectors
#'
#' Deletes vectors from an index by ID, filter, or all vectors.
#'
#' @param index Name of the index
#' @param ids Vector IDs to delete (character vector)
#' @param delete_all Whether to delete all vectors (default: FALSE)
#' @param name_space Namespace to delete from (default: "")
#' @param filter Metadata filter for selective deletion (list)
#'
#' @return List with http response, content, and status_code
#' @export
#'
#' @examples
#' \dontrun{
#' # Delete specific vectors
#' vector_delete("my-index", ids = c("vec1", "vec2"))
#'
#' # Delete all vectors in namespace
#' vector_delete("my-index", delete_all = TRUE, name_space = "my-namespace")
#' }
vector_delete <- function(index, ids = NULL, delete_all = FALSE, name_space = "", filter = NULL){

  # get index host
  temp_index <- describe_index(index_name = index)
  host <- get_index_host(temp_index)

  # get URL using data plane
  pinecone_url <- get_data_plane_url(host, "vectors/delete")

  # get token
  pinecone_token <- get_api_key()

  # body
  body <- list(
    deleteAll = delete_all,
    namespace = name_space
  )

  # Add ids if provided
  if (!is.null(ids)) {
    body$ids <- ids
  }

  # Add filter if provided
  if (!is.null(filter)) {
    body$filter <- filter
  }

  # make body
  body <- jsonlite::toJSON(body, auto_unbox = TRUE)

  # get response
  response <- httr::POST( pinecone_url,
                          body = body,
                          encode = "raw",
                          httr::accept_json(),
                          httr::content_type_json(),
                          httr::add_headers( `Api-Key`= pinecone_token )
  )

  result <- handle_respons(response)

  return(result)

}

#' Fetch Vectors
#'
#' Retrieves vectors by ID from an index.
#'
#' @param index Name of the index
#' @param ids Vector IDs to fetch (character vector)
#' @param namespace Namespace to fetch from (default: "")
#' @param tidy Whether to return tidy tibble format (default: TRUE)
#'
#' @return List with http response, content (vectors), and status_code
#' @export
#'
#' @examples
#' \dontrun{
#' vector_fetch("my-index", ids = c("vec1", "vec2"), namespace = "")
#' }
vector_fetch <- function(index, ids, namespace = "", tidy = TRUE){

  # get index host
  temp_index <- describe_index(index_name = index)
  host <- get_index_host(temp_index)

  # get URL using data plane
  pinecone_url <- get_data_plane_url(host, "vectors/fetch")

  # get token
  pinecone_token <- get_api_key()

  # prep query params (multiple ids need to be passed as repeated params)
  query_params <- list()
  for (id in ids) {
    query_params <- c(query_params, list(ids = id))
  }
  if (namespace != "") {
    query_params$namespace <- namespace
  }

  # get response
  response <- httr::GET( pinecone_url,
                         query = query_params,
                         httr::accept_json(),
                         httr::add_headers( `Api-Key`= pinecone_token )
  )

  result <- handle_respons(response)

  # tidy content
  if(tidy && result$status_code == 200 && !is.null(result$content$vectors)){
    result$content <- handle_vectors(result$content)
  }

  return(result)

}

#' Update Vector
#'
#' Updates a vector's values or metadata.
#'
#' @param index Name of the index
#' @param vector_id ID of the vector to update
#' @param values New vector values (numeric vector, optional)
#' @param meta_data New metadata (list, optional)
#' @param name_space Namespace of the vector (default: "")
#'
#' @return List with http response, content, and status_code
#' @export
#'
#' @examples
#' \dontrun{
#' # Update metadata only
#' vector_update("my-index", vector_id = "vec1", meta_data = list(category = "new"))
#'
#' # Update values and metadata
#' vector_update("my-index", vector_id = "vec1", values = rep(0.1, 1536),
#'               meta_data = list(category = "new"))
#' }
vector_update <- function(index, vector_id, values = NULL, meta_data = NULL, name_space = ""){

  # get index host
  temp_index <- describe_index(index_name = index)
  host <- get_index_host(temp_index)

  # get URL using data plane
  pinecone_url <- get_data_plane_url(host, "vectors/update")

  # get token
  pinecone_token <- get_api_key()

  # body
  body <- list(
    id = vector_id,
    namespace = name_space
  )

  # Add values if provided
  if (!is.null(values)) {
    body$values <- values
  }

  # Add metadata if provided
  if (!is.null(meta_data)) {
    body$setMetadata <- meta_data
  }

  body <- jsonlite::toJSON(body, auto_unbox = TRUE)

  # get response
  response <- httr::POST( pinecone_url,
                          body = body,
                          encode = "raw",
                          httr::accept_json(),
                          httr::content_type_json(),
                          httr::add_headers( `Api-Key`= pinecone_token )
  )

  result <- handle_respons(response)

  return(result)

}



#' Upsert Vectors
#'
#' Inserts or updates vectors in an index. If a vector with the same ID exists,
#' it will be overwritten.
#'
#' @param index Name of the index
#' @param vectors List of vectors to upsert. Each vector should be a list with:
#'   - id: Vector ID (character)
#'   - values: Vector values (numeric vector)
#'   - metadata: Optional metadata (list)
#' @param name_space Namespace to upsert into (default: "")
#'
#' @return List with http response, content (upserted count), and status_code
#' @export
#'
#' @examples
#' \dontrun{
#' # Upsert a single vector
#' vector_upsert("my-index", vectors = list(
#'   list(id = "vec1", values = rep(0.1, 1536), metadata = list(category = "A"))
#' ))
#'
#' # Upsert multiple vectors
#' vector_upsert("my-index", vectors = list(
#'   list(id = "vec1", values = rep(0.1, 1536)),
#'   list(id = "vec2", values = rep(0.2, 1536))
#' ))
#' }
vector_upsert <- function(index, vectors, name_space = ""){

  # get index host
  temp_index <- describe_index(index_name = index)
  host <- get_index_host(temp_index)

  # get URL using data plane
  pinecone_url <- get_data_plane_url(host, "vectors/upsert")

  # get token
  pinecone_token <- get_api_key()

  # body
  body <- list(
    vectors = vectors,
    namespace = name_space
  )

  body <- jsonlite::toJSON(body, auto_unbox = TRUE)

  # get response
  response <- httr::POST( pinecone_url,
                          body = body,
                          encode = "raw",
                          httr::accept_json(),
                          httr::content_type_json(),
                          httr::add_headers( `Api-Key`= pinecone_token )
  )

  result <- handle_respons(response)

  return(result)

}


