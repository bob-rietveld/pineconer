# =============================================================================
# Pinecone Assistant API - Assistant Operations
# =============================================================================
#
# This file implements the Pinecone Assistant API for assistant management.
# The Assistant API enables RAG (retrieval-augmented generation) by allowing
# you to upload documents, ask questions, and receive responses that reference
# your documents.
#
# API Documentation: https://docs.pinecone.io/reference/api/assistant/introduction
#
# Control Plane (api.pinecone.io):
#   - POST   /assistant/assistants              - Create assistant
#   - GET    /assistant/assistants              - List assistants
#   - GET    /assistant/assistants/{name}       - Describe assistant
#   - PATCH  /assistant/assistants/{name}       - Update assistant
#   - DELETE /assistant/assistants/{name}       - Delete assistant
#
# =============================================================================


#' List Assistants
#'
#' Lists all assistants in your Pinecone project.
#'
#' @return List with http response, content (list of assistants), and status_code.
#'   Content includes an "assistants" list where each assistant has:
#'   - name: Assistant name
#'   - instructions: Custom instructions (if set)
#'   - metadata: Metadata dictionary
#'   - status: Assistant status ("Initializing", "Ready", "Terminating", "Failed")
#'   - host: Data plane host URL
#'   - created_at: Creation timestamp
#'   - updated_at: Last update timestamp
#'
#' @export
#'
#' @examples
#' \dontrun{
#' list_assistants()
#' }
list_assistants <- function() {

  # get URL
  pinecone_url <- get_assistant_control_url("assistant/assistants")

  # get token
  pinecone_token <- get_api_key()

  # get response
  response <- httr::GET(
    pinecone_url,
    httr::accept_json(),
    httr::add_headers(`Api-Key` = pinecone_token)
  )

  result <- handle_respons(response)

  return(result)

}


#' Create Assistant
#'
#' Creates a new Pinecone assistant for RAG (retrieval-augmented generation).
#'
#' @param name Name of the assistant (must be unique within project)
#' @param instructions Optional instructions/directive for the assistant to apply to all responses
#' @param metadata Optional named list of metadata key-value pairs
#' @param region Region to deploy assistant. Options: "us" (default) or "eu"
#'
#' @return List with http response, content (assistant details), and status_code.
#'   Content includes:
#'   - name: Assistant name
#'   - instructions: Custom instructions (if set)
#'   - metadata: Metadata dictionary
#'   - status: Assistant status
#'   - host: Data plane host URL for file and chat operations
#'   - created_at: Creation timestamp
#'   - updated_at: Last update timestamp
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Create a basic assistant
#' create_assistant(name = "my-assistant")
#'
#' # Create with instructions and metadata
#' create_assistant(
#'   name = "my-assistant",
#'   instructions = "Use American English for spelling and grammar.",
#'   metadata = list(team = "research", version = "1.0"),
#'   region = "us"
#' )
#' }
create_assistant <- function(name, instructions = NULL, metadata = NULL, region = "us") {

  # assertions
  assertthat::assert_that(!missing(name), msg = "Please provide an assistant name.")
  assertthat::assert_that(
    region %in% c("us", "eu"),
    msg = "region must be either 'us' or 'eu'."
  )

  # get URL
  pinecone_url <- get_assistant_control_url("assistant/assistants")

  # get token
  pinecone_token <- get_api_key()

  # Build request body
  body <- list(name = name)

  if (!is.null(instructions)) {
    body$instructions <- instructions
  }

  if (!is.null(metadata)) {
    body$metadata <- metadata
  }

  body$region <- region

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


#' Describe Assistant
#'
#' Returns configuration information and status of an assistant.
#'
#' @param assistant_name Name of the assistant to describe
#'
#' @return List with http response, content (assistant configuration), and status_code.
#'   Content includes:
#'   - name: Assistant name
#'   - instructions: Custom instructions (if set)
#'   - metadata: Metadata dictionary
#'   - status: Assistant status ("Initializing", "Ready", "Terminating", "Failed")
#'   - host: Data plane host URL for file and chat operations
#'   - created_at: Creation timestamp
#'   - updated_at: Last update timestamp
#'
#' @export
#'
#' @examples
#' \dontrun{
#' describe_assistant("my-assistant")
#' }
describe_assistant <- function(assistant_name) {

  # assertions
  assertthat::assert_that(!missing(assistant_name), msg = "Please provide an assistant name.")

  # get token
  pinecone_token <- get_api_key()

  # set path
  path <- glue::glue("assistant/assistants/{assistant_name}")

  # get url
  pinecone_url <- get_assistant_control_url(set_path = path)

  # get response
  response <- httr::GET(
    pinecone_url,
    httr::accept_json(),
    httr::add_headers(`Api-Key` = pinecone_token)
  )

  # parse result
  result <- handle_respons(response)

  return(result)

}


#' Update Assistant
#'
#' Updates an existing assistant's instructions and/or metadata.
#'
#' @param assistant_name Name of the assistant to update
#' @param instructions New instructions for the assistant (optional).
#'   These will be applied to all future chat interactions.
#' @param metadata New metadata dictionary (optional).
#'   If provided, completely replaces existing metadata.
#'
#' @return List with http response, content (updated assistant details), and status_code
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Update instructions only
#' update_assistant(
#'   assistant_name = "my-assistant",
#'   instructions = "Use Australian English spelling and vocabulary."
#' )
#'
#' # Update metadata only
#' update_assistant(
#'   assistant_name = "my-assistant",
#'   metadata = list(version = "2.0", updated = "2024-01-01")
#' )
#'
#' # Update both
#' update_assistant(
#'   assistant_name = "my-assistant",
#'   instructions = "Be concise in responses.",
#'   metadata = list(team = "support")
#' )
#' }
update_assistant <- function(assistant_name, instructions = NULL, metadata = NULL) {

  # assertions
  assertthat::assert_that(!missing(assistant_name), msg = "Please provide an assistant name.")

  # get token
  pinecone_token <- get_api_key()

  # set path
  path <- glue::glue("assistant/assistants/{assistant_name}")

  # get url
  pinecone_url <- get_assistant_control_url(set_path = path)

  # Build body
  body <- list()

  if (!is.null(instructions)) {
    body$instructions <- instructions
  }

  if (!is.null(metadata)) {
    body$metadata <- metadata
  }

  # get response
  response <- httr::PATCH(
    pinecone_url,
    body = jsonlite::toJSON(body, auto_unbox = TRUE),
    encode = "raw",
    httr::accept_json(),
    httr::content_type_json(),
    httr::add_headers(`Api-Key` = pinecone_token)
  )

  # parse result
  result <- handle_respons(response)

  return(result)

}


#' Delete Assistant
#'
#' Deletes an existing assistant. This also deletes all files uploaded to the assistant.
#'
#' @param assistant_name Name of the assistant to delete
#'
#' @return List with http response, content, and status_code.
#'   - 200: The assistant has been successfully deleted
#'   - 404: Assistant not found
#'   - 500: Internal error
#'
#' @export
#'
#' @examples
#' \dontrun{
#' delete_assistant("my-assistant")
#' }
delete_assistant <- function(assistant_name) {

  # assertions
  assertthat::assert_that(!missing(assistant_name), msg = "Please provide an assistant name.")

  # get token
  pinecone_token <- get_api_key()

  # set path
  path <- glue::glue("assistant/assistants/{assistant_name}")

  # get url
  pinecone_url <- get_assistant_control_url(set_path = path)

  # get response
  response <- httr::DELETE(
    pinecone_url,
    httr::add_headers(`Api-Key` = pinecone_token)
  )

  # parse result
  result <- handle_respons(response)

  return(result)

}
