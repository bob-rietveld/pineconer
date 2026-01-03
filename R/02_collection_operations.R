#' List Collections
#'
#' Lists all collections in your Pinecone project.
#'
#' @return List with http response, content (list of collections), and status_code
#' @export
#'
#' @examples
#' \dontrun{
#' list_collections()
#' }
list_collections <- function(){

  # get URL (new global API endpoint)
  pinecone_url <- get_control_plane_url("collections")

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

#' Create Collection
#'
#' Creates a collection from an existing index. Collections are static copies
#' of an index that can be used to create new indexes.
#'
#' @param name Name for the new collection
#' @param source Name of the source index to create the collection from
#'
#' @return List with http response, content, and status_code
#' - 201: The collection has been successfully created
#' - 400: Bad request (quota exceeded or invalid name)
#' - 409: A collection with this name already exists
#' - 500: Internal error
#'
#' @export
#'
#' @examples
#' \dontrun{
#' create_collection("my-collection", source = "my-index")
#' }
create_collection <- function(name, source){

  # get URL (new global API endpoint)
  pinecone_url <- get_control_plane_url("collections")

  # get token
  pinecone_token <- get_api_key()

  # body
  body <- list(
    name = name,
    source = source
  )

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

#' Describe Collection
#'
#' Returns information about a collection.
#'
#' @param collection_name Name of the collection to describe
#'
#' @return List with http response, content (collection details), and status_code
#' @export
#'
#' @examples
#' \dontrun{
#' describe_collection("my-collection")
#' }
describe_collection <- function(collection_name){

  # get token
  pinecone_token <- get_api_key()

  # path
  path <- glue::glue("collections/{collection_name}")

  # get url (new global API)
  pinecone_url <- get_control_plane_url(set_path = path)

  # get response
  response <- httr::GET( pinecone_url,
                         httr::accept_json(),
                         httr::add_headers( `Api-Key`= pinecone_token )
  )

  result <- handle_respons(response)

  return(result)

}

#' Delete Collection
#'
#' Deletes an existing collection.
#'
#' @param collection_name Name of the collection to delete
#'
#' @return List with http response, content, and status_code
#' - 202: The collection has been successfully deleted
#' - 404: Collection not found
#' - 500: Internal error
#'
#' @export
#'
#' @examples
#' \dontrun{
#' delete_collection("my-collection")
#' }
delete_collection <- function(collection_name){

  # get token
  pinecone_token <- get_api_key()

  # get url (new global API)
  pinecone_url <- get_control_plane_url(set_path = glue::glue("collections/{collection_name}"))

  # get response
  response <- httr::DELETE( pinecone_url,
                            httr::accept_json(),
                            httr::add_headers( `Api-Key`= pinecone_token )
  )

  result <- handle_respons(response)

  return(result)

}
