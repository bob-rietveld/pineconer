#' Descrive Index stats
#'
#' @param controller
#'
#' @return
#' @export
#'
#' @examples
describe_index_stats <- function( controller ){

  # get toke
  pinecone_token <- get_api_key()

  # get url
  pinecone_url <- get_url(controller = controller, set_path = "databases/describe_index_stats")

  # get response
  response <- httr::GET( pinecone_url,
                         httr::accept_json(),
                         httr::add_headers( `Api-Key`= pinecone_token )
  )

  result <- handle_respons(response)

  return(result)


}

#' Query Vectors
#'
#' @param index
#' @param vector
#' @param top_k
#' @param filter
#' @param name_space
#' @param include_metadata
#' @param include_values
#' @param tidy
#'
#' @return
#' @export
#'
#' @examples
vector_query <- function( index,
                          vector,
                          top_k = 5,
                          filter = list(),
                          name_space = "",
                          include_metadata = TRUE,
                          include_values = FALSE ,
                          tidy = TRUE ){

  # get controller
  temp_index <- describe_index( index_name = index )
  controller <- extract_vector_controller( temp_index )

  # get URL
  pinecone_url <- get_url(controller,"query")

  print(pinecone_url)

  # get toke
  pinecone_token <- get_api_key()

  # body
  body <- list(
    vector          = vector,
    topK            = top_k,
    filter          = filter,
    includeMetadata = include_metadata,
    includeValues   = include_values,
    namespace       = name_space
  )



  # get response
  response <- httr::POST( pinecone_url,
                          body = body,
                          encode = "json",
                          httr::add_headers( `Api-Key`= pinecone_token )
  )

  result <- handle_respons(response)

  if(tidy){

    result$content <-  tibble::tibble(data = result$content$matches) %>%
      tidyr::unnest_wider(data) %>%
      tidyr::unnest_wider(metadata)
  }

  return(result)

}

#' Title
#'
#' @param index
#' @param ids
#' @param delete_all
#' @param name_space
#' @param filter
#'
#' @return
#' @export
#'
#' @examples
vector_delete <- function( index, ids = NULL, delete_all = FALSE, name_space = "", filter = NULL){

  # get controller
  temp_index <- describe_index( index_name = index )
  controller <- extract_vector_controller( temp_index )

  # get URL
  pinecone_url <- get_url(controller,"vectors/delete")

  print(pinecone_url)

  # get toke
  pinecone_token <- get_api_key()

  # body
  body <- list( ids       = ids,
                deleteAll = delete_all,
                namespace = name_space,
                filter    = filter
  )

  # remove values if undefined
  if(is.null(filter)){

    body <-   body[names(body) != "filter"]
  }

  body <- jsonlite::toJSON( body, auto_unbox = TRUE)

  print(body)

  # get response
  response <- httr::POST( pinecone_url,
                          body = body,
                          encode = "raw",
                          httr::add_headers( `Api-Key`= pinecone_token )
  )

  result <- handle_respons(response)

  return(result)

}

#' Fetch
#'
#' @param index
#' @param ids
#'
#' @return
#' @export
#'
#' @examples
vector_fetch <- function( index, ids , namespace , tidy = TRUE){

  # get controller
  temp_index <- describe_index( index_name = index )
  controller <- extract_vector_controller( temp_index )

  # get URL
  pinecone_url <- get_url(controller,"vectors/fetch")

  print(pinecone_url)

  # get toke
  pinecone_token <- get_api_key()

  # prep query params
  list_temp <- list()
  list_temp <- purrr::lmap( ids, ~list_modify(list_temp, ids = .x))
  query_id <- purrr::list_modify(list_temp, namespace = namespace)

  # get response
  response <- httr::GET( pinecone_url,
                         query = query_id,
                         httr::add_headers( `Api-Key`= pinecone_token )
  )

  result <- handle_respons(response)

  # tidy content
  if(tidy && result$status_code == 200){

    result$content <- handle_vectors(result$content)
  }

  return(result)

}

#' Update Vectors
#'
#' @param index
#' @param embeddings
#' @param vector_id
#' @param meta_data
#' @param name_space
#'
#' @return
#' @export
#'
#' @examples
vector_update  <- function( index, embeddings = NULL, vector_id,  meta_data = "" , name_space = ""){

  # get controller
  temp_index <- describe_index( index_name = index )
  controller <- extract_vector_controller( temp_index )

  # get URL
  pinecone_url <- get_url(controller,"vectors/update")

  print(pinecone_url)

  # get toke
  pinecone_token <- get_api_key()

  # body
  body <- list(
    id        = vector_id,
    setMetadata = meta_data,
    namespace = name_space
  )

  # remove values if undefined
  if(is.null(embeddings)){
    body <- body[names(body) != "values"]
  }

  body <- jsonlite::toJSON(body, auto_unbox = TRUE)

  print(body)

  # get response
  response <- httr::POST( pinecone_url,
                          body = body,
                          encode = "raw",
                          httr::add_headers( `Api-Key`= pinecone_token )
  )

  result <- handle_respons(response)

  return(result)

}



#' Upsert
#'
#' @param index
#' @param embeddings
#' @param vector_id
#' @param meta_data
#' @param name_space
#'
#' @return
#' @export
#'
vector_upsert  <- function( index, embeddings, vector_id,  meta_data = "" , name_space = ""){

    # get controller
    temp_index <- describe_index( index_name = index )
    controller <- extract_vector_controller( temp_index )

    # get URL
    pinecone_url <- get_url(controller,"vectors/upsert")

    print(pinecone_url)

    # get toke
    pinecone_token <- get_api_key()

    # body
    body <- list(
                  vectors   = list(list(
                                   id        = vector_id,
                                   values    = embeddings,
                                   metadata = meta_data
                                   )
                                   ),
                  namespace = name_space
                  )

    body <- jsonlite::toJSON(body, auto_unbox = TRUE)

    print(body)

    # get response
    response <- httr::POST( pinecone_url,
                            body = body,
                            encode = "raw",
                            httr::add_headers( `Api-Key`= pinecone_token )
    )

    result <- handle_respons(response)

    return(result)

}


