# =============================================================================
# Pinecone Assistant API - Chat Operations
# =============================================================================
#
# This file implements the Pinecone Assistant API for chat operations.
# Chat with assistants to get responses that reference your uploaded documents.
#
# API Documentation: https://docs.pinecone.io/guides/assistant/chat-with-assistant
#
# Data Plane (assistant host, e.g., prod-1-data.ke.pinecone.io):
#   - POST /assistant/chat/{assistant_name}                  - Chat with assistant
#   - POST /assistant/chat/{assistant_name}/chat/completions - OpenAI-compatible chat
#   - POST /assistant/chat/{assistant_name}/context          - Retrieve context snippets
#
# =============================================================================


#' Chat with Assistant
#'
#' Sends messages to an assistant and receives responses with citations.
#' This is the recommended chat interface, offering more functionality than
#' the OpenAI-compatible interface.
#'
#' @param assistant_name Name of the assistant
#' @param messages List of message objects. Each message should have:
#'   - role: Either "user" or "assistant"
#'   - content: The message text
#' @param model Optional model to use (e.g., "gpt-4o"). Uses assistant default if not specified.
#' @param filter Optional metadata filter to limit which files are searched (list)
#' @param context_options Optional list of context options:
#'   - top_k: Number of context chunks to retrieve (default: 15)
#'   - snippet_size: Maximum size of each snippet in tokens
#'   - multimodal: Whether to include image context for PDFs (default: TRUE)
#'   - include_binary_content: Include base64 image data when multimodal is TRUE
#'
#' @return List with http response, content (chat response), and status_code.
#'   Content includes:
#'   - id: Response ID
#'   - model: Model used
#'   - message: Response message with role and content
#'   - finish_reason: Reason for completion ("stop", etc.)
#'   - citations: List of citations referencing source documents
#'   - usage: Token usage statistics
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Simple chat
#' assistant_chat(
#'   assistant_name = "my-assistant",
#'   messages = list(
#'     list(role = "user", content = "What is the main topic of the document?")
#'   )
#' )
#'
#' # Chat with conversation history
#' assistant_chat(
#'   assistant_name = "my-assistant",
#'   messages = list(
#'     list(role = "user", content = "Who is the CEO?"),
#'     list(role = "assistant", content = "The CEO is John Smith."),
#'     list(role = "user", content = "When did they start?")
#'   )
#' )
#'
#' # Chat with metadata filter
#' assistant_chat(
#'   assistant_name = "my-assistant",
#'   messages = list(list(role = "user", content = "Summarize the 2023 report")),
#'   filter = list(year = 2023)
#' )
#'
#' # Chat with context options
#' assistant_chat(
#'   assistant_name = "my-assistant",
#'   messages = list(list(role = "user", content = "Describe the images")),
#'   context_options = list(
#'     multimodal = TRUE,
#'     include_binary_content = TRUE,
#'     top_k = 10
#'   )
#' )
#' }
assistant_chat <- function(assistant_name, messages, model = NULL, filter = NULL, context_options = NULL) {

  # assertions
  assertthat::assert_that(!missing(assistant_name), msg = "Please provide an assistant name.")
  assertthat::assert_that(!missing(messages), msg = "Please provide messages.")
  assertthat::assert_that(is.list(messages) && length(messages) > 0, msg = "messages must be a non-empty list.")

  # get token
  pinecone_token <- get_api_key()

  # Get assistant host
  assistant_info <- describe_assistant(assistant_name)
  host <- get_assistant_host(assistant_info)

  # set path
  path <- glue::glue("assistant/chat/{assistant_name}")

  # get url
  pinecone_url <- get_assistant_data_url(host, set_path = path)

  # Build body
  body <- list(
    messages = messages,
    stream = FALSE
  )

  if (!is.null(model)) {
    body$model <- model
  }

  if (!is.null(filter)) {
    body$filter <- filter
  }

  if (!is.null(context_options)) {
    body$context_options <- context_options
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

  return(result)

}


#' Chat Completions with Assistant (OpenAI-compatible)
#'
#' Sends messages to an assistant using the OpenAI-compatible chat completions interface.
#' This interface is useful for OpenAI-compatible responses but has limited functionality
#' compared to the standard chat interface.
#'
#' @param assistant_name Name of the assistant
#' @param messages List of message objects. Each message should have:
#'   - role: Either "user" or "assistant"
#'   - content: The message text (cannot be empty)
#' @param model Optional model to use (e.g., "gpt-4o")
#'
#' @return List with http response, content (OpenAI-style response), and status_code.
#'   Content includes:
#'   - id: Response ID
#'   - model: Model used
#'   - choices: List of choice objects with message and finish_reason
#'
#' @export
#'
#' @examples
#' \dontrun{
#' assistant_chat_completions(
#'   assistant_name = "my-assistant",
#'   messages = list(
#'     list(role = "user", content = "What is the maximum height of a red pine?")
#'   )
#' )
#' }
assistant_chat_completions <- function(assistant_name, messages, model = NULL) {

  # assertions
  assertthat::assert_that(!missing(assistant_name), msg = "Please provide an assistant name.")
  assertthat::assert_that(!missing(messages), msg = "Please provide messages.")
  assertthat::assert_that(is.list(messages) && length(messages) > 0, msg = "messages must be a non-empty list.")

  # get token
  pinecone_token <- get_api_key()

  # Get assistant host
  assistant_info <- describe_assistant(assistant_name)
  host <- get_assistant_host(assistant_info)

  # set path
  path <- glue::glue("assistant/chat/{assistant_name}/chat/completions")

  # get url
  pinecone_url <- get_assistant_data_url(host, set_path = path)

  # Build body
  body <- list(messages = messages)

  if (!is.null(model)) {
    body$model <- model
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

  return(result)

}


#' Retrieve Context from Assistant
#'
#' Retrieves context snippets from an assistant's documents without generating
#' a chat response. Useful for RAG pipelines or agentic flows where you want
#' to handle the context yourself.
#'
#' @param assistant_name Name of the assistant
#' @param query The query text to find relevant context for
#' @param filter Optional metadata filter to limit which files are searched (list)
#' @param top_k Number of context snippets to retrieve (default: 15)
#' @param snippet_size Maximum size of each snippet in tokens (optional)
#'
#' @return List with http response, content (context snippets), and status_code.
#'   Content includes a "snippets" list where each snippet has:
#'   - type: Snippet type (e.g., "text")
#'   - content: The text content of the snippet
#'   - score: Relevance score
#'   - reference: Reference information including:
#'     - type: Document type (e.g., "pdf")
#'     - file: File information
#'     - pages: Page numbers referenced
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Get context for a query
#' assistant_context(
#'   assistant_name = "my-assistant",
#'   query = "Who is the CFO?"
#' )
#'
#' # Get context with filter
#' assistant_context(
#'   assistant_name = "my-assistant",
#'   query = "What are the revenue figures?",
#'   filter = list(document_type = "financial"),
#'   top_k = 10
#' )
#' }
assistant_context <- function(assistant_name, query, filter = NULL, top_k = NULL, snippet_size = NULL) {

  # assertions
  assertthat::assert_that(!missing(assistant_name), msg = "Please provide an assistant name.")
  assertthat::assert_that(!missing(query), msg = "Please provide a query.")

  # get token
  pinecone_token <- get_api_key()

  # Get assistant host
  assistant_info <- describe_assistant(assistant_name)
  host <- get_assistant_host(assistant_info)

  # set path
  path <- glue::glue("assistant/chat/{assistant_name}/context")

  # get url
  pinecone_url <- get_assistant_data_url(host, set_path = path)

  # Build body
  body <- list(query = query)

  if (!is.null(filter)) {
    body$filter <- filter
  }

  if (!is.null(top_k)) {
    body$top_k <- top_k
  }

  if (!is.null(snippet_size)) {
    body$snippet_size <- snippet_size
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

  return(result)

}


#' Evaluate Assistant Answer
#'
#' Evaluates the correctness and completeness of a response from an assistant
#' or RAG system by comparing it against a ground truth answer.
#'
#' @param question The original question that was asked
#' @param answer The answer to evaluate (from assistant or RAG system)
#' @param ground_truth_answer The correct/expected answer to compare against
#'
#' @return List with http response, content (evaluation metrics), and status_code.
#'   Content includes:
#'   - correctness: Precision of the answer (0 to 1)
#'   - completeness: Recall of the answer (0 to 1)
#'   - alignment: Harmonic mean of correctness and completeness
#'
#' @details
#' This endpoint evaluates answers based on:
#' - Correctness: How precise is the answer? (Are the facts stated correct?)
#' - Completeness: How complete is the answer? (Are all expected facts present?)
#' - Alignment: Combined score (harmonic mean of correctness and completeness)
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Evaluate an answer
#' assistant_evaluate(
#'   question = "What are the capital cities of France, England and Spain?",
#'   answer = "Paris is the capital of France and London is the capital of England.",
#'   ground_truth_answer = "Paris is the capital of France, London is the capital of England, and Madrid is the capital of Spain."
#' )
#' }
assistant_evaluate <- function(question, answer, ground_truth_answer) {

  # assertions
  assertthat::assert_that(!missing(question), msg = "Please provide a question.")
  assertthat::assert_that(!missing(answer), msg = "Please provide an answer.")
  assertthat::assert_that(!missing(ground_truth_answer), msg = "Please provide a ground truth answer.")

  # get token
  pinecone_token <- get_api_key()

  # get url - evaluation uses a different endpoint
  pinecone_url <- get_assistant_control_url("assistant/evaluation/metrics/alignment")

  # Build body
  body <- list(
    question = question,
    answer = answer,
    ground_truth_answer = ground_truth_answer
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

  return(result)

}
