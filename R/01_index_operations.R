
#' List Index
#'
#' @return
#' @export
#'
#' @examples
list_indexes <- function(){

  # get URL
  pinecone_url <- get_url("controller","databases")

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

#' Create Index
#'
#' @param name
#' @param dimension
#' @param metric
#' @param pods
#' @param replicas
#' @param pod_type
#' @param metadata_config
#' @param source_collection
#'
#' @return
#' @export
#'
#' @examples
create_index <- function( name, dimension, metric, pods, replicas, pod_type, metadata_config, source_collection){

  # get URL
  pinecone_url <- get_url("controller", "databases")

  # get toke
  pinecone_token <- get_api_key()

  # body
  body <- list( name = name,
                dimension = dimension)

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


#' Describe Index
#'
#' @param controller
#' @param index_name
#' @param return_controller
#'
#' @return
#' 200 Configuration information and deployment status of the index
#' 404 Index not found
#' 500 Internal error. Can be caused by invalid parameters.
#' @export
describe_index <- function(  index_name , controller = "controller"  ){

  # get toke
  pinecone_token <- get_api_key()

  # set path
  path <- glue::glue("databases/{index_name}")

  #get url
  pinecone_url <- get_url(controller = controller, set_path = path)

  # get response
  response <- httr::GET( pinecone_url,
                         httr::add_headers( `Api-Key`= pinecone_token ) )

  # parse result
  result <- handle_respons(response)


  return(result)


}

#' Delete index
#'
#' @param index_name
#' @param controller
#'
#' @return
#'202 The index has been successfully deleted.
#'404 Index not found.
#'500 Internal error. Can be caused by invalid parameters.
#' @export
delete_index <- function(  index_name , controller = "controller"  ){

  # get toke
  pinecone_token <- get_api_key()

  # set path
  path <- glue::glue("databases/{index_name}")

  #get url
  pinecone_url <- get_url(controller = controller, set_path = path)

  # get response
  response <- httr::DELETE( pinecone_url,
                            httr::add_headers( `Api-Key`= pinecone_token ) )

  # parse result
  result <- handle_respons(response)


  return(result)


}

#' Configure index in terms of replicas and pod size
#'
#' @param index_name
#' @param replicas integer
#' The desired number of replicas for the index.
#' @param pod_type
#' The new pod type for the index. One of s1, p1, or p2 appended with . and one of x1, x2, x4, or x8.
#' @param controller
#'
#' @return
#' @export
#'
#' @examples
configure_index <- function(  index_name , replicas, pod_type, controller = "controller"  ){

  # assertions
  ## check if replicas is int
  assertthat::assert_that(is.numeric(replicas), msg = "Replicas must be integers")

  ## check is pod_type is in one of the allowed values
  # create podlist = expand.grid(c("s1","p1","p2"),c("x1","x2","x4","x8")) |> tidyr::unite("z",c("Var1","Var2"), sep =".") |> dplyr::pull(z)
  pod_list <- c("s1.x1","p1.x1","p2.x1","s1.x2","p1.x2","p2.x2","s1.x4","p1.x4","p2.x4","s1.x8","p1.x8","p2.x8")
  error_msg <- glue::glue("Pod type must be one of predefined by Pinecone. Please see the docs at https://docs.pinecone.io/reference/configure_index")
  assertthat::assert_that(pod_type %in% pod_list, msg = error_msg )

  # get token
  pinecone_token <- get_api_key()

  # set path
  path <- glue::glue("databases/{index_name}")

  #get url
  pinecone_url <- get_url(controller = controller, set_path = path)

  # body
  body <- list( replicas = replicas,
                pod_type = pod_type)

  # get response
  response <- httr::PATCH( pinecone_url,
                           body = body,
                           httr::accept_json(),
                           httr::add_headers( `Api-Key`= pinecone_token ) )

  # parse result
  result <- handle_respons(response)


  return(result)


}
