#' Generate Embeddings
#'
#' Generate vector embeddings for input data using Pinecone's hosted embedding models.
#'
#' @param model The embedding model to use. Available models include:
#'   - "multilingual-e5-large" (1024 dimensions)
#'   - "pinecone-sparse-english-v0" (sparse vectors)
#'   See Pinecone documentation for the full list of available models.
#' @param inputs A character vector of texts to embed.
#' @param input_type The type of input. Either "passage" for documents to be indexed,
#'   or "query" for search queries. Default is "passage".
#' @param truncate How to handle inputs longer than the model's max token length.
#'   Options: "END" (truncate from end), "NONE" (error if too long). Default is "END".
#' @param tidy Whether to return a tidy tibble format (default: TRUE).
#'   If FALSE, returns the raw API response structure.
#'
#' @return List with http response, content (embeddings), and status_code.
#'   When tidy = TRUE, content is a tibble with columns:
#'   - values: list column containing the embedding vectors
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Embed documents for indexing
#' result <- embed(
#'   model = "multilingual-e5-large",
#'   inputs = c("The quick brown fox", "jumps over the lazy dog"),
#'   input_type = "passage"
#' )
#'
#' # Embed a query for searching
#' query_embedding <- embed(
#'   model = "multilingual-e5-large",
#'   inputs = "What does the fox do?",
#'   input_type = "query"
#' )
#'
#' # Use the embedding for a vector query
#' vector_query("my-index", vector = query_embedding$content$values[[1]], top_k = 10)
#' }
embed <- function(model, inputs, input_type = "passage", truncate = "END", tidy = TRUE) {


  # assertions

  assertthat::assert_that(!missing(model), msg = "Please provide a model name.")
  assertthat::assert_that(!missing(inputs), msg = "Please provide inputs to embed.")
  assertthat::assert_that(is.character(inputs), msg = "Inputs must be a character vector.")
  assertthat::assert_that(
    input_type %in% c("passage", "query"),
    msg = "input_type must be either 'passage' or 'query'."
  )
  assertthat::assert_that(
    truncate %in% c("END", "NONE"),
    msg = "truncate must be either 'END' or 'NONE'."
  )

  # get URL
  pinecone_url <- get_inference_url("embed")

  # get token
  pinecone_token <- get_api_key()

  # Build request body
  body <- list(
    model = model,
    inputs = lapply(inputs, function(x) list(text = x)),
    parameters = list(
      input_type = input_type,
      truncate = truncate
    )
  )

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
  if (tidy && result$status_code == 200 && !is.null(result$content$data)) {
    embeddings <- lapply(result$content$data, function(x) x$values)
    result$content <- tibble::tibble(values = embeddings)
  }

  return(result)

}


#' Rerank Results
#'
#' Rerank documents according to their relevance to a query using Pinecone's
#' hosted reranking models.
#'
#' @param model The reranking model to use. Available models include:
#'   - "pinecone-rerank-v0"
#'   See Pinecone documentation for the full list of available models.
#' @param query The query string to rank documents against.
#' @param documents A character vector of documents to rerank, or a list of
#'   named lists where each contains a "text" field (and optionally an "id" field).
#' @param top_n The number of top results to return. Default is to return all documents.
#' @param return_documents Whether to include the document text in the response.
#'   Default is TRUE.
#' @param tidy Whether to return a tidy tibble format (default: TRUE).
#'
#' @return List with http response, content (reranked results), and status_code.
#'   When tidy = TRUE, content is a tibble with columns:
#'   - index: original position of the document
#'   - score: relevance score (higher is more relevant)
#'   - document: the document text (if return_documents = TRUE)
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Rerank search results
#' documents <- c(
#'   "The quick brown fox jumps over the lazy dog",
#'   "A fast auburn fox leaps above a sleepy canine",
#'   "The weather is nice today"
#' )
#'
#' result <- rerank(
#'   model = "pinecone-rerank-v0",
#'   query = "What did the fox do?",
#'   documents = documents,
#'   top_n = 2
#' )
#'
#' # View reranked results
#' result$content
#'
#' # Rerank with document IDs
#' docs_with_ids <- list(
#'   list(id = "doc1", text = "The quick brown fox jumps over the lazy dog"),
#'   list(id = "doc2", text = "A fast auburn fox leaps above a sleepy canine"),
#'   list(id = "doc3", text = "The weather is nice today")
#' )
#'
#' result <- rerank(
#'   model = "pinecone-rerank-v0",
#'   query = "What did the fox do?",
#'   documents = docs_with_ids
#' )
#' }
rerank <- function(model, query, documents, top_n = NULL, return_documents = TRUE, tidy = TRUE) {

  # assertions
  assertthat::assert_that(!missing(model), msg = "Please provide a model name.")
  assertthat::assert_that(!missing(query), msg = "Please provide a query.")
  assertthat::assert_that(!missing(documents), msg = "Please provide documents to rerank.")
  assertthat::assert_that(
    is.character(query) && length(query) == 1,
    msg = "Query must be a single character string."
  )

  # get URL
  pinecone_url <- get_inference_url("rerank")

  # get token
  pinecone_token <- get_api_key()

  # Format documents - handle both character vector and list of lists

if (is.character(documents)) {
    formatted_docs <- lapply(documents, function(x) list(text = x))
  } else if (is.list(documents)) {
    # Assume it's already in the correct format (list of lists with text field)
    formatted_docs <- documents
  } else {
    stop("Documents must be a character vector or a list of named lists.")
  }

  # Build request body
  body <- list(
    model = model,
    query = query,
    documents = formatted_docs,
    return_documents = return_documents
  )

  # Add top_n if specified
  if (!is.null(top_n)) {
    assertthat::assert_that(
      is.numeric(top_n) && top_n > 0,
      msg = "top_n must be a positive number."
    )
    body$top_n <- as.integer(top_n)
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
  if (tidy && result$status_code == 200 && !is.null(result$content$data)) {
    tidy_result <- tibble::tibble(data = result$content$data)
    tidy_result <- tidyr::unnest_wider(tidy_result, "data")

    # Unnest document if present
    if ("document" %in% names(tidy_result) && return_documents) {
      tidy_result <- tidyr::unnest_wider(tidy_result, "document", names_sep = "_")
    }

    result$content <- tidy_result
  }

  return(result)

}
