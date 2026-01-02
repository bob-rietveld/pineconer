## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  eval = FALSE
)

## ----install------------------------------------------------------------------
# # Install from GitHub (when available)
# # remotes::install_github("bob-rietveld/pineconer")

## ----renviron-----------------------------------------------------------------
# readRenviron("~/.Renviron")

## ----setup--------------------------------------------------------------------
# library(pineconer)

## ----list-indexes-------------------------------------------------------------
# # List all indexes in your project
# indexes <- list_indexes()
# print(indexes$content)

## ----create-serverless--------------------------------------------------------
# # Create a serverless index for storing 4-dimensional vectors (like iris features)
# result <- create_index(
#   name = "iris-demo",
#   dimension = 4,
#   metric = "cosine",
#   spec = list(
#     serverless = list(
#       cloud = "aws",
#       region = "us-east-1"
#     )
#   )
# )
# print(result$status_code)  # 201 on success

## ----create-pod---------------------------------------------------------------
# # Alternative: Create a pod-based index
# result <- create_index(
#   name = "iris-pod-demo",
#   dimension = 4,
#   metric = "cosine",
#   spec = list(
#     pod = list(
#       environment = "us-east-1-aws",
#       pod_type = "p1.x1",
#       pods = 1
#     )
#   )
# )

## ----describe-index-----------------------------------------------------------
# # Get index details including the host for data operations
# index_info <- describe_index("iris-demo")
# print(index_info$content$host)
# print(index_info$content$status)

## ----prepare-data-------------------------------------------------------------
# # Load iris dataset
# data(iris)
# 
# # Prepare vectors for upserting
# vectors <- lapply(1:nrow(iris), function(i) {
#   list(
#     id = paste0("iris-", i),
#     values = as.numeric(iris[i, 1:4]),
#     metadata = list(
#       species = as.character(iris$Species[i]),
#       sepal_length = iris$Sepal.Length[i],
#       sepal_width = iris$Sepal.Width[i]
#     )
#   )
# })
# 
# # Preview first vector
# print(vectors[[1]])

## ----upsert-------------------------------------------------------------------
# # Upsert vectors in batches (Pinecone recommends batches of 100)
# batch_size <- 100
# n_batches <- ceiling(length(vectors) / batch_size)
# 
# for (i in 1:n_batches) {
#   start_idx <- (i - 1) * batch_size + 1
#   end_idx <- min(i * batch_size, length(vectors))
# 
#   result <- vector_upsert(
#     index = "iris-demo",
#     vectors = vectors[start_idx:end_idx]
#   )
# 
#   cat("Batch", i, "- Status:", result$status_code, "\n")
# }

## ----query--------------------------------------------------------------------
# # Query using a sample vector (first iris observation)
# query_vector <- as.numeric(iris[1, 1:4])
# 
# results <- vector_query(
#   index = "iris-demo",
#   vector = query_vector,
#   top_k = 5,
#   include_metadata = TRUE
# )
# 
# # Results are returned as a tidy tibble by default
# print(results$content)

## ----query-filter-------------------------------------------------------------
# # Find similar vectors but only among setosa species
# results <- vector_query(
#   index = "iris-demo",
#   vector = query_vector,
#   top_k = 5,
#   filter = list(species = list(`$eq` = "setosa"))
# )
# 
# print(results$content)

## ----fetch--------------------------------------------------------------------
# # Fetch vectors by ID
# fetched <- vector_fetch(
#   index = "iris-demo",
#   ids = c("iris-1", "iris-2", "iris-3")
# )
# 
# print(fetched$content)

## ----update-------------------------------------------------------------------
# # Update metadata for a specific vector
# result <- vector_update(
#   index = "iris-demo",
#   vector_id = "iris-1",
#   meta_data = list(
#     species = "setosa",
#     sepal_length = 5.1,
#     verified = TRUE
#   )
# )
# 
# print(result$status_code)  # 200 on success

## ----stats--------------------------------------------------------------------
# # Get statistics about the index
# stats <- describe_index_stats("iris-demo")
# 
# print(stats$content$totalVectorCount)
# print(stats$content$dimension)

## ----delete-------------------------------------------------------------------
# # Delete specific vectors
# result <- vector_delete(
#   index = "iris-demo",
#   ids = c("iris-1", "iris-2")
# )
# 
# # Delete all vectors in a namespace
# result <- vector_delete(
#   index = "iris-demo",
#   delete_all = TRUE,
#   name_space = "test-namespace"
# )

## ----create-collection--------------------------------------------------------
# # Create a collection from an existing index
# result <- create_collection(
#   name = "iris-backup",
#   source = "iris-demo"
# )
# 
# print(result$status_code)

## ----list-collections---------------------------------------------------------
# collections <- list_collections()
# print(collections$content)

## ----describe-collection------------------------------------------------------
# collection_info <- describe_collection("iris-backup")
# print(collection_info$content)

## ----namespaces---------------------------------------------------------------
# # Upsert to a specific namespace
# result <- vector_upsert(
#   index = "iris-demo",
#   vectors = vectors[1:50],
#   name_space = "training"
# )
# 
# result <- vector_upsert(
#   index = "iris-demo",
#   vectors = vectors[51:100],
#   name_space = "validation"
# )
# 
# # Query a specific namespace
# results <- vector_query(
#   index = "iris-demo",
#   vector = query_vector,
#   top_k = 5,
#   name_space = "training"
# )

## ----cleanup------------------------------------------------------------------
# # Delete the index when done
# delete_index("iris-demo")
# 
# # Delete the collection
# delete_collection("iris-backup")

## ----error-handling-----------------------------------------------------------
# result <- describe_index("non-existent-index")
# 
# if (result$status_code != 200) {
#   cat("Error:", result$status_code, "\n")
#   # Access raw response for details
#   print(httr::content(result$http))
# } else {
#   print(result$content)
# }

