#' Upsert Records (Integrated Inference)
#'
#' Upserts records with text that gets automatically embedded using the index's
#' integrated embedding model. This is only available for indexes created with
#' `create_index_for_model()`.
#'
#' @param index Name of the index (must have integrated embedding model)
#' @param records A list of records to upsert. Each record should be a named list with:
#'   - `_id`: Unique identifier for the record
#'   - Additional fields including the text field specified in the index's field_map
#' @param namespace Namespace to upsert into (default: "")
#'
#' @return List with http response, content (upserted count), and status_code
#'
#' @details
#' The index must be created with `create_index_for_model()` which configures
#' an integrated embedding model. The text field specified in the index's
#' `field_map` will be automatically embedded.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # First create an index with integrated embedding
#' create_index_for_model(
#'   name = "my-index",
#'   cloud = "aws",
#'   region = "us-east-1",
#'   embed = list(
#'     model = "multilingual-e5-large",
#'     field_map = list(text = "chunk_text")
#'   )
#' )
#'
#' # Then upsert records with text (automatically embedded)
#' records_upsert(
#'   index = "my-index",
#'   records = list(
#'     list(`_id` = "rec1", chunk_text = "The quick brown fox"),
#'     list(`_id` = "rec2", chunk_text = "jumps over the lazy dog")
#'   )
#' )
#'
#' # With additional metadata
#' records_upsert(
#'   index = "my-index",
#'   records = list(
#'     list(
#'       `_id` = "doc1",
#'       chunk_text = "Machine learning is transforming industries",
#'       category = "tech",
#'       source = "article"
#'     )
#'   )
#' )
#' }
records_upsert <- function(index, records, namespace = "") {

  # assertions
  assertthat::assert_that(!missing(index), msg = "Please provide an index name.")
  assertthat::assert_that(!missing(records), msg = "Please provide records to upsert.")
  assertthat::assert_that(is.list(records), msg = "records must be a list.")

  # get index host
 temp_index <- describe_index(index_name = index)
  host <- get_index_host(temp_index)

  # Build path with namespace
  if (namespace == "") {
    path <- "records/namespaces/upsert"
  } else {
    path <- glue::glue("records/namespaces/{namespace}/upsert")
  }

  # get URL using data plane
  pinecone_url <- get_data_plane_url(host, path)

  # get token
  pinecone_token <- get_api_key()

  # Build request body
  body <- list(records = records)

  # get response
  response <- httr::POST(
    pinecone_url,
    body = jsonlite::toJSON(body, auto_unbox = TRUE),
    encode = "raw",
    httr::accept_json(),
    httr::content_type_json(),
    httr::add_headers(`Api-Key` = pinecone_token)
  )

  result <- handle_respons(response)

  return(result)

}


#' Search Records (Integrated Inference)
#'
#' Searches records using text queries that get automatically embedded, with
#' optional reranking. This is only available for indexes created with
#' `create_index_for_model()`.
#'
#' @param index Name of the index (must have integrated embedding model)
#' @param query The search input. Can be:
#'   - A character string (text query to embed)
#'   - A numeric vector (raw embedding vector)
#'   - A list with `id` field to search by record ID
#' @param namespace Namespace to search in (default: "")
#' @param top_k Number of results to return (default: 10)
#' @param filter Metadata filter (list)
#' @param fields Character vector of metadata fields to return (default: all)
#' @param rerank Optional reranking configuration. A list with:
#'   - model: Reranking model name (e.g., "pinecone-rerank-v0")
#'   - top_n: Number of results after reranking
#'   - rank_fields: Fields to use for reranking
#' @param tidy Whether to return tidy tibble format (default: TRUE)
#'
#' @return List with http response, content (search results), and status_code.
#'   When tidy = TRUE, content is a tibble with columns for id, score, and fields.
#'
#' @details
#' The index must be created with `create_index_for_model()`. Text queries are
#' automatically embedded using the index's configured model.
#'
#' Reranking improves result quality by re-scoring results based on semantic
#' relevance to the query.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Simple text search
#' results <- records_search(
#'   index = "my-index",
#'   query = "What does the fox do?",
#'   top_k = 5
#' )
#'
#' # Search with metadata filter
#' results <- records_search(
#'   index = "my-index",
#'   query = "machine learning applications",
#'   filter = list(category = list(`$eq` = "tech")),
#'   top_k = 10
#' )
#'
#' # Search with reranking for better results
#' results <- records_search(
#'   index = "my-index",
#'   query = "How does AI impact healthcare?",
#'   top_k = 100,
#'   rerank = list(
#'     model = "pinecone-rerank-v0",
#'     top_n = 10,
#'     rank_fields = c("chunk_text")
#'   )
#' )
#'
#' # Search by vector
#' results <- records_search(
#'   index = "my-index",
#'   query = my_embedding_vector,
#'   top_k = 5
#' )
#'
#' # Search by record ID (find similar)
#' results <- records_search(
#'   index = "my-index",
#'   query = list(id = "rec1"),
#'   top_k = 5
#' )
#' }
records_search <- function(index, query, namespace = "", top_k = 10, filter = NULL,
                           fields = NULL, rerank = NULL, tidy = TRUE) {

  # assertions
  assertthat::assert_that(!missing(index), msg = "Please provide an index name.")
  assertthat::assert_that(!missing(query), msg = "Please provide a query.")

  # get index host
  temp_index <- describe_index(index_name = index)
  host <- get_index_host(temp_index)

  # Build path with namespace
  if (namespace == "") {
    path <- "records/namespaces/search"
  } else {
    path <- glue::glue("records/namespaces/{namespace}/search")
  }

  # get URL using data plane
  pinecone_url <- get_data_plane_url(host, path)

  # get token
  pinecone_token <- get_api_key()

  # Build query object based on input type
  if (is.character(query) && length(query) == 1) {
    # Text query
    query_obj <- list(top_k = top_k, inputs = list(text = query))
  } else if (is.numeric(query)) {
    # Vector query
    query_obj <- list(top_k = top_k, vector = list(values = as.list(query)))
  } else if (is.list(query) && !is.null(query$id)) {
    # ID-based query
    query_obj <- list(top_k = top_k, id = query$id)
  } else {
    stop("query must be a character string (text), numeric vector, or list with 'id' field.")
  }

  # Add filter if provided
  if (!is.null(filter)) {
    query_obj$filter <- filter
  }

  # Build request body
  body <- list(query = query_obj)

  # Add fields if provided
  if (!is.null(fields)) {
    body$fields <- as.list(fields)
  }

  # Add rerank if provided
  if (!is.null(rerank)) {
    assertthat::assert_that(
      is.list(rerank) && !is.null(rerank$model),
      msg = "rerank must be a list with at least a 'model' field."
    )
    body$rerank <- rerank
  }

  # get response
  response <- httr::POST(
    pinecone_url,
    body = jsonlite::toJSON(body, auto_unbox = TRUE),
    encode = "raw",
    httr::accept_json(),
    httr::content_type_json(),
    httr::add_headers(`Api-Key` = pinecone_token)
  )

  result <- handle_respons(response)

  # tidy output
  if (tidy && result$status_code == 200 && !is.null(result$content$result$hits)) {
    hits <- result$content$result$hits
    if (length(hits) > 0) {
      tidy_result <- tibble::tibble(data = hits)
      tidy_result <- tidyr::unnest_wider(tidy_result, "data")
      if ("fields" %in% names(tidy_result)) {
        tidy_result <- tidyr::unnest_wider(tidy_result, "fields", names_sep = "_")
      }
      result$content <- tidy_result
    } else {
      result$content <- tibble::tibble()
    }
  }

  return(result)

}
