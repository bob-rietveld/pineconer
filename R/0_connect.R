#' Get Api Key
#'
#' @return
#' @export
#'
#' @examples
get_api_key <- function() {

  # check for credentials
  pinecone_token = Sys.getenv('PINECONE_API_KEY')

  # check for path
  if (pinecone_token == '') stop(sprintf('variable %s missing from file ~/.Renviron', 'PINECONE_API_KEY'))

  return(pinecone_token)

}


#' Get Pinecone index url
#'
#' @param controller
#' @param set_path
#'
#' @return
#' @export
#'
#' @examples
get_url <- function( controller , set_path = NA) {

  # check for credentials
  pinecone_environment = Sys.getenv('PINECONE_ENVIRONMENT')

  # check for path
  if (pinecone_environment == '') stop(sprintf('variable %s missing from file ~/.Renviron', 'PINECONE_ENVIRONMENT'))

  # set url
   pinecone_api_url <- glue::glue("https://{controller}.{pinecone_environment}.pinecone.io/")

  if(!is.na(set_path)){

    # create url
    pinecone_api_url <- httr::modify_url(pinecone_api_url, path = set_path)

    # print
    print(pinecone_api_url)
  }

  return(pinecone_api_url)

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

#' Get controller
#'
#' @param index
#' @param vector
#'
#' @return
extract_vector_controller <- function( index, vector = "svc"){


  controller <- index$content$status$host
  response <- glue::glue_collapse(stringr::str_split_1(controller, "\\.")[1:2],".")

  return(response)
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
