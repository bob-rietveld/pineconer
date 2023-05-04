#' List Collections
#'
#' @return
#' @export
#'
#' @examples
list_collections <- function(){

  # get URL
  pinecone_url <- get_url("controller","collections")

  # get toke
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
#' @param name
#' @param source_collection
#'
#' @return
#' list with api call and content.
#' 201 The collection has been successfully created.
#' 400 Bad request. Request exceeds quota or collection name is invalid.
#' 409 A collection with the name provided already exists.
#' 500 Internal error. Can be caused by invalid parameters.
#' @export
create_collection <- function( name, source_collection){

  # get URL
  pinecone_url <- get_url("controller", "collections")

  # get toke
  pinecone_token <- get_api_key()

  # todo. implement check if index exists.

  # body
  body <- list( name = name,
                source = source_collection)

  # get response
  response <- httr::POST( pinecone_url,
                          body = body,
                          encode = "json",
                          httr::accept_json(),
                          httr::add_headers( `Api-Key`= pinecone_token )
  )

  result <- handle_respons(response)

  return(result)

}

#' Describe collection
#'
#' @param collection_name
#'
#' @return
#' @export
#'
#' @examples
describe_collection <- function(  collection_name, controller = "controller"  ){

  # get toke
  pinecone_token <- get_api_key()

  # path
  path <- glue::glue("collections/{collection_name}")

  # get url
  pinecone_url <- get_url(controller = controller, set_path = path )

  # get response
  response <- httr::GET( pinecone_url,
                         httr::accept_json(),
                         httr::add_headers( `Api-Key`= pinecone_token )
  )

  result <- handle_respons(response)

  return(result)


}

#' Delete collection
#'
#' @param collection_name
#'
#' @return
#' 202 The index has been successfully deleted.
#' 404 Collection not found.
#' 500 Internal error. Can be caused by invalid parameters.
#' @export
#'
#' @examples
delete_collection <- function(  collection_name, controller = "controller"  ){

  # get toke
  pinecone_token <- get_api_key()

  # get url
  pinecone_url <- get_url(controller = controller, set_path = glue::glue("collections/{collection_name}"))

  # get response
  response <- httr::DELETE( pinecone_url,
                            httr::accept_json(),
                            httr::add_headers( `Api-Key`= pinecone_token )
  )

  result <- handle_respons(response)

  return(result)


}
