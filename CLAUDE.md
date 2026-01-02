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

### Data Plane (index host)
Used for vector operations. The host is returned when creating/describing an index:
- Vector query, upsert, fetch, update, delete
- Index statistics

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

## Development Notes

- Package uses roxygen2 for documentation (RoxygenNote: 7.2.3)
- NAMESPACE exports all functions starting with letters (`exportPattern("^[[:alpha:]]+")`)
