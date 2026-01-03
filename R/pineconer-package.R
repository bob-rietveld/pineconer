#' pineconer: R Interface to the Pinecone Vector Database
#'
#' @description
#' The pineconer package provides a comprehensive R interface to the
#' Pinecone Vector Database API. Pinecone is a managed vector database
#' designed for machine learning applications, enabling similarity search
#' and retrieval augmented generation (RAG) workflows.
#'
#' This package uses the Pinecone Global API (api.pinecone.io) introduced
#' in April 2024.
#'
#' @section Setup:
#' Before using this package, you must set your Pinecone API key as an
#' environment variable. Add the following line to your `~/.Renviron` file:
#'
#' \preformatted{
#' PINECONE_API_KEY=your_api_key
#' }
#'
#' Then restart R or run \code{readRenviron("~/.Renviron")}.
#'
#' @section API Architecture:
#' The Pinecone API has three planes:
#'
#' \strong{Control Plane} (api.pinecone.io):
#' Used for management operations including index, collection, and assistant CRUD.
#'
#' \strong{Data Plane} (index-specific host):
#' Used for vector operations. The host URL is returned when creating or
#' describing an index.
#'
#' \strong{Assistant Data Plane} (assistant-specific host):
#' Used for assistant file and chat operations.
#'
#' @section Index Operations:
#' \itemize{
#'   \item \code{\link{list_indexes}}: List all indexes
#'   \item \code{\link{create_index}}: Create a new index (serverless or pod-based)
#'   \item \code{\link{describe_index}}: Get index configuration and host
#'   \item \code{\link{delete_index}}: Delete an index
#'   \item \code{\link{configure_index}}: Update index configuration
#' }
#'
#' @section Collection Operations:
#' \itemize{
#'   \item \code{\link{list_collections}}: List all collections
#'   \item \code{\link{create_collection}}: Create collection from index
#'   \item \code{\link{describe_collection}}: Get collection details
#'   \item \code{\link{delete_collection}}: Delete a collection
#' }
#'
#' @section Vector Operations:
#' \itemize{
#'   \item \code{\link{vector_query}}: Query vectors by similarity
#'   \item \code{\link{vector_upsert}}: Insert or update vectors
#'   \item \code{\link{vector_fetch}}: Fetch vectors by ID
#'   \item \code{\link{vector_update}}: Update vector values or metadata
#'   \item \code{\link{vector_delete}}: Delete vectors
#'   \item \code{\link{vector_list}}: List vector IDs with pagination
#'   \item \code{\link{describe_index_stats}}: Get index statistics
#' }
#'
#' @section Inference API:
#' \itemize{
#'   \item \code{\link{inference_embed}}: Generate embeddings from text
#'   \item \code{\link{inference_rerank}}: Rerank documents by relevance
#' }
#'
#' @section Records API:
#' For indexes with integrated inference (auto-embedding):
#' \itemize{
#'   \item \code{\link{records_upsert}}: Upsert records with automatic embedding
#'   \item \code{\link{records_search}}: Search records by text query
#' }
#'
#' @section Bulk Operations:
#' \itemize{
#'   \item \code{\link{start_import}}: Start bulk import from cloud storage
#'   \item \code{\link{describe_import}}: Get import job status
#'   \item \code{\link{list_imports}}: List all import jobs
#'   \item \code{\link{cancel_import}}: Cancel a running import
#' }
#'
#' @section Assistant Operations:
#' \itemize{
#'   \item \code{\link{list_assistants}}: List all assistants
#'   \item \code{\link{create_assistant}}: Create a new assistant
#'   \item \code{\link{describe_assistant}}: Get assistant details
#'   \item \code{\link{update_assistant}}: Update assistant settings
#'   \item \code{\link{delete_assistant}}: Delete an assistant
#' }
#'
#' @section Assistant File Operations:
#' \itemize{
#'   \item \code{\link{assistant_list_files}}: List files in an assistant
#'   \item \code{\link{assistant_upload_file}}: Upload a file to an assistant
#'   \item \code{\link{assistant_describe_file}}: Get file details
#'   \item \code{\link{assistant_delete_file}}: Delete a file from an assistant
#' }
#'
#' @section Assistant Chat Operations:
#' \itemize{
#'   \item \code{\link{assistant_chat}}: Chat with an assistant (recommended)
#'   \item \code{\link{assistant_chat_completions}}: OpenAI-compatible chat interface
#'   \item \code{\link{assistant_context}}: Retrieve context snippets for custom RAG
#'   \item \code{\link{assistant_evaluate}}: Evaluate answer correctness
#' }
#'
#' @section Response Structure:
#' All API functions return a list with three components:
#' \describe{
#'   \item{http}{Raw httr response object}
#'   \item{content}{Parsed response content (NULL on error)}
#'   \item{status_code}{HTTP status code}
#' }
#'
#' Vector operations support \code{tidy = TRUE} (default) to return
#' cleaned tibble output.
#'
#' @examples
#' \dontrun{
#' # List all indexes
#' indexes <- list_indexes()
#' indexes$content
#'
#' # Create a serverless index
#' create_index(
#'   name = "my-index",
#'   dimension = 1536,
#'   metric = "cosine",
#'   spec = list(serverless = list(cloud = "aws", region = "us-east-1"))
#' )
#'
#' # Query vectors
#' results <- vector_query(
#'   index = "my-index",
#'   vector = rep(0.1, 1536),
#'   top_k = 10
#' )
#'
#' # Use inference API to embed text
#' embeddings <- inference_embed(
#'   model = "multilingual-e5-large",
#'   inputs = c("Hello world", "Goodbye world")
#' )
#'
#' # Create an assistant and chat
#' create_assistant(name = "my-assistant")
#' assistant_upload_file("my-assistant", "document.pdf")
#' response <- assistant_chat(
#'   assistant_name = "my-assistant",
#'   messages = list(list(role = "user", content = "Summarize the document"))
#' )
#' }
#'
#' @importFrom httr GET POST DELETE PATCH modify_url status_code content
#'   accept_json content_type_json add_headers upload_file
#' @importFrom assertthat assert_that
#' @importFrom tibble tibble
#' @importFrom tidyr unnest_wider
#' @importFrom jsonlite toJSON
#'
#' @keywords internal
"_PACKAGE"
