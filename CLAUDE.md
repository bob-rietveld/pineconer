# Pineconer

R package for interacting with the Pinecone Vector Database API.

## Project Structure

```
pineconer/
├── R/
│   ├── 0_connect.R           # Connection utilities, API key handling, URL construction
│   ├── 01_index_operations.R # Index CRUD operations
│   ├── 02_collection_operations.R # Collection CRUD operations
│   └── 03_vector_operations.R # Vector query, upsert, fetch, update, delete
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

Set these environment variables in `~/.Renviron`:

```
PINECONE_API_KEY=your_api_key
PINECONE_ENVIRONMENT=your_region
```

## Core Functions

### Connection Utilities (`R/0_connect.R`)

- `get_api_key()` - Retrieves API key from environment
- `get_url(controller, set_path)` - Constructs Pinecone API URLs
- `handle_respons(response, tidy)` - Parses API responses into standardized structure
- `extract_vector_controller(index)` - Extracts controller hostname from index description
- `handle_vectors(input)` - Tidies vector data into tibbles

### Index Operations (`R/01_index_operations.R`)

- `list_indexes()` - List all indexes
- `create_index(name, dimension, ...)` - Create new index
- `describe_index(index_name)` - Get index configuration
- `delete_index(index_name)` - Delete an index
- `configure_index(index_name, replicas, pod_type)` - Update index replicas/pod type

### Collection Operations (`R/02_collection_operations.R`)

- `list_collections()` - List all collections
- `create_collection(name, source_collection)` - Create collection from index
- `describe_collection(collection_name)` - Get collection details
- `delete_collection(collection_name)` - Delete a collection

### Vector Operations (`R/03_vector_operations.R`)

- `describe_index_stats(index_name, project_name)` - Get index statistics
- `vector_query(index, vector, top_k, filter, ...)` - Query vectors by similarity
- `vector_delete(index, ids, delete_all, ...)` - Delete vectors
- `vector_fetch(index, ids, namespace)` - Fetch vectors by ID
- `vector_update(index, vector_id, embeddings, meta_data)` - Update vector metadata
- `vector_upsert(index, embeddings, vector_id, meta_data)` - Insert or update vectors

## Response Structure

All API functions return a list with:
- `http` - Raw httr response object
- `content` - Parsed response content (NULL on error)
- `status_code` - HTTP status code

Use `tidy = TRUE` (default for vector operations) to get cleaned tibble output.

## API Patterns

1. All functions use `httr` for HTTP requests
2. API key passed via `Api-Key` header
3. URLs constructed as: `https://{controller}.{environment}.pinecone.io/{path}`
4. Vector operations require index name lookup to get the correct controller hostname

## Valid Pod Types

For `configure_index()`: `s1.x1`, `s1.x2`, `s1.x4`, `s1.x8`, `p1.x1`, `p1.x2`, `p1.x4`, `p1.x8`, `p2.x1`, `p2.x2`, `p2.x4`, `p2.x8`

## Development Notes

- Package uses roxygen2 for documentation (RoxygenNote: 7.2.3)
- NAMESPACE exports all functions starting with letters (`exportPattern("^[[:alpha:]]+")`)
- Some vector operations have `print()` statements for debugging URL construction
