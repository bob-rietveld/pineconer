% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/01_index_operations.R
\name{delete_index}
\alias{delete_index}
\title{Delete index}
\usage{
delete_index(index_name, controller = "controller")
}
\arguments{
\item{controller}{}
}
\value{
202 The index has been successfully deleted.
404 Index not found.
500 Internal error. Can be caused by invalid parameters.
}
\description{
Delete index
}
