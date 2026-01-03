# Pineconer

R package for interacting with the Pinecone Vector Database API.

**Note**: This package uses the Pinecone Global API (api.pinecone.io) which was introduced in April 2024. The legacy regional API is no longer supported.

## Project Structure

```
pineconer/
├── R/
│   ├── 0_connect.R           # Connection utilities, API key handling, URL construction
│   ├── 01_index_operations.R # Index CRUD operations
│   ├── 02_collection_operations.R # Collection CRUD operations
│   ├── 03_vector_operations.R # Vector query, upsert, fetch, update, delete
│   ├── 04_inference_operations.R # Inference API (embed, rerank)
│   ├── 05_records_operations.R # Records API for integrated indexes
│   ├── 06_bulk_operations.R  # Bulk import operations
│   ├── 07_assistant_operations.R # Assistant CRUD operations (create, list, describe, update, delete)
│   ├── 08_assistant_files.R  # Assistant file management (upload, list, describe, delete)
│   └── 09_assistant_chat.R   # Assistant chat operations (chat, context, evaluate)
├── DESCRIPTION               # Package metadata
├── NAMESPACE                 # Exports (all functions starting with letters)
└── README.Rmd/README.md      # Documentation
```

## Dependencies

- **httr**: HTTP requests
- **assertthat**: Input validation
- **glue**: String interpolation (suggested)
- **tidyr**, **tibble**, **purrr**, **stringr**: Data manipulation (used internally)
- **jsonlite**: JSON encoding for request bodies

## Configuration

Set this environment variable in `~/.Renviron`:

```
PINECONE_API_KEY=your_api_key
```

**Note**: `PINECONE_ENVIRONMENT` is no longer required with the new global API.

## Core Functions

### Connection Utilities (`R/0_connect.R`)

- `get_api_key()` - Retrieves API key from environment
- `get_control_plane_url(set_path)` - Constructs URLs for control plane operations (api.pinecone.io)
- `get_data_plane_url(host, set_path)` - Constructs URLs for data plane operations (index host)
- `get_index_host(index)` - Extracts host from index description for data plane calls
- `get_assistant_control_url(set_path)` - Constructs URLs for assistant control plane operations
- `get_assistant_data_url(host, set_path)` - Constructs URLs for assistant data plane operations
- `get_assistant_host(assistant)` - Extracts host from assistant description
- `handle_respons(response, tidy)` - Parses API responses into standardized structure
- `handle_vectors(input)` - Tidies vector data into tibbles

**Deprecated functions** (kept for backwards compatibility):
- `get_url()` - Use `get_control_plane_url()` instead
- `extract_vector_controller()` - Use `get_index_host()` instead

### Index Operations (`R/01_index_operations.R`)

- `list_indexes()` - List all indexes
- `create_index(name, dimension, metric, spec, deletion_protection)` - Create new index (serverless or pod-based)
- `describe_index(index_name)` - Get index configuration and host
- `delete_index(index_name)` - Delete an index
- `configure_index(index_name, replicas, pod_type, deletion_protection)` - Update index configuration

### Collection Operations (`R/02_collection_operations.R`)

- `list_collections()` - List all collections
- `create_collection(name, source)` - Create collection from index
- `describe_collection(collection_name)` - Get collection details
- `delete_collection(collection_name)` - Delete a collection

### Vector Operations (`R/03_vector_operations.R`)

- `describe_index_stats(index_name, filter)` - Get index statistics
- `vector_query(index, vector, top_k, filter, ...)` - Query vectors by similarity
- `vector_delete(index, ids, delete_all, ...)` - Delete vectors
- `vector_fetch(index, ids, namespace)` - Fetch vectors by ID
- `vector_update(index, vector_id, values, meta_data)` - Update vector values/metadata
- `vector_upsert(index, vectors, name_space)` - Insert or update vectors

### Assistant Operations (`R/07_assistant_operations.R`)

- `list_assistants()` - List all assistants in project
- `create_assistant(name, instructions, metadata, region)` - Create new assistant
- `describe_assistant(assistant_name)` - Get assistant configuration and status
- `update_assistant(assistant_name, instructions, metadata)` - Update assistant settings
- `delete_assistant(assistant_name)` - Delete an assistant (also deletes all files)

### Assistant File Operations (`R/08_assistant_files.R`)

- `assistant_list_files(assistant_name, filter)` - List files in assistant
- `assistant_upload_file(assistant_name, file_path, metadata, multimodal)` - Upload file to assistant
- `assistant_describe_file(assistant_name, file_id, include_url)` - Get file status and metadata
- `assistant_delete_file(assistant_name, file_id)` - Delete file from assistant

### Assistant Chat Operations (`R/09_assistant_chat.R`)

- `assistant_chat(assistant_name, messages, model, filter, context_options)` - Chat with assistant (recommended)
- `assistant_chat_completions(assistant_name, messages, model)` - OpenAI-compatible chat interface
- `assistant_context(assistant_name, query, filter, top_k, snippet_size)` - Retrieve context snippets for RAG
- `assistant_evaluate(question, answer, ground_truth_answer)` - Evaluate answer correctness/completeness

## Response Structure

All API functions return a list with:
- `http` - Raw httr response object
- `content` - Parsed response content (NULL on error)
- `status_code` - HTTP status code

Use `tidy = TRUE` (default for vector operations) to get cleaned tibble output.

## API Architecture

The Pinecone API has two planes:

### Control Plane (api.pinecone.io)
Used for management operations:
- Index operations (create, list, describe, delete, configure)
- Collection operations (create, list, describe, delete)
- Assistant management (create, list, describe, update, delete)

### Data Plane (index host)
Used for vector operations. The host is returned when creating/describing an index:
- Vector query, upsert, fetch, update, delete
- Index statistics

### Assistant Data Plane (assistant host)
Used for assistant file and chat operations. The host is returned when creating/describing an assistant:
- File operations (upload, list, describe, delete)
- Chat operations (chat, chat completions, context retrieval)
- Evaluation operations

## Creating Indexes

The new API supports two types of indexes:

### Serverless Index
```r
create_index(
  name = "my-index",
  dimension = 1536,
  metric = "cosine",
  spec = list(serverless = list(cloud = "aws", region = "us-east-1"))
)
```

### Pod-Based Index
```r
create_index(
  name = "my-pod-index",
  dimension = 1536,
  metric = "cosine",
  spec = list(pod = list(environment = "us-east-1-aws", pod_type = "p1.x1", pods = 1))
)
```

## Valid Pod Types

For pod-based indexes: `s1.x1`, `s1.x2`, `s1.x4`, `s1.x8`, `p1.x1`, `p1.x2`, `p1.x4`, `p1.x8`, `p2.x1`, `p2.x2`, `p2.x4`, `p2.x8`

## Using Assistants

The Assistant API enables RAG (retrieval-augmented generation) by allowing you to upload documents, ask questions, and receive responses that reference your documents.

### Creating an Assistant
```r
# Create a basic assistant
create_assistant(name = "my-assistant")

# Create with instructions
create_assistant(
  name = "my-assistant",
  instructions = "Use American English for spelling and grammar.",
  region = "us"
)
```

### Uploading Files
```r
# Upload a document
assistant_upload_file("my-assistant", "/path/to/document.pdf")

# Upload with metadata
assistant_upload_file(
  "my-assistant",
  "/path/to/document.pdf",
  metadata = list(company = "acme", year = 2024)
)
```

### Chatting with an Assistant
```r
# Simple chat
result <- assistant_chat(
  assistant_name = "my-assistant",
  messages = list(
    list(role = "user", content = "What is the main topic?")
  )
)

# Access the response
result$content$message$content
result$content$citations
```

### Retrieving Context for Custom RAG
```r
# Get context snippets without generating a response
context <- assistant_context(
  assistant_name = "my-assistant",
  query = "What are the key findings?"
)

# Use snippets in your own pipeline
context$content$snippets
```

## Development Notes

- Package uses roxygen2 for documentation (RoxygenNote: 7.2.3)
- NAMESPACE exports all functions starting with letters (`exportPattern("^[[:alpha:]]+")`)
