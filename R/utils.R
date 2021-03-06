# TODO: (RK) Document this file literately.

#' Merge two lists and overwrite latter entries with former entries
#' if names are the same.
#'
#' For example, \code{list_merge(list(a = 1, b = 2), list(b = 3, c = 4))}
#' will be \code{list(a = 1, b = 3, c = 4)}.
#' @param list1 list
#' @param list2 list
#' @return the merged list.
#' @export
#' @examples
#' stopifnot(identical(list_merge(list(a = 1, b = 2), list(b = 3, c = 4)),
#'                     list(a = 1, b = 3, c = 4)))
#' stopifnot(identical(list_merge(NULL, list(a = 1)), list(a = 1)))
list_merge <- function(list1, list2) {
  list1 <- list1 %||% list()
  # Pre-allocate memory to make this slightly faster.
  list1[Filter(function(x) nchar(x) > 0, names(list2) %||% c())] <- NULL
  for (i in seq_along(list2)) {
    name <- names(list2)[i]
    if (!identical(name, NULL) && !identical(name, "")) list1[[name]] <- list2[[i]]
    else list1 <- append(list1, list(list2[[i]]))
  }
  list1
}

`%||%` <- function(x, y) if (is.null(x)) y else x

is.acceptable_function <- function(x) {
  is.function(x) || 
  is.null(x)     ||
  is.mungebit(x)
}

is.simple_character_vector <- function(x) {
  is.character(x) && all(nzchar(x)) &&
  !any(is.na(x)) && length(x) > 0 &&
  length(unique(x)) == length(x)
}

# If an environment contains variables "a" and "b",
# create a list (a = quote(a), b = quote(b)).
env2listcall <- function(env) {
  names <- ls(env)
  if ("name_order" %in% names(attributes(env))) {
    names <- names[attr(env, "name_order")]
  }
  setNames(lapply(names, as.name), nm = names)
}

# Revert the operation in mungepiece initialization that turns a list
# into an environment.
env2list <- function(env) {
  if (length(ls(env)) == 0L) {
    list()
  } else {
    lst <- as.list(env)
    lst <- lst[match(names(lst), attr(env, "parsed_names"))]
    if (any(nzchar(attr(env, "initial_names")))) {
      names(lst) <- attr(env, "initial_names")
    } else {
      names(lst) <- NULL
    }
    lst
  }
}

make_env <- function(lst, parent = emptyenv()) {
  initial_names <- names(lst) %||% character(length(lst))
  names(lst) <- ifelse(unnamed(lst),
    paste0("_", seq_along(lst)),
    paste0("_", initial_names)
  )

  if (anyDuplicated(names(lst))) {
    stop("Cannot accept lists with duplicate names")
  }

  if (length(lst) == 0) {
    env <- new.env(parent = parent)
  } else {
    env <- list2env(lst, parent = parent)
  }

  name_order <- match(names(lst), ls(env))
  attr(env, "name_order")    <- name_order
  attr(env, "initial_names") <- initial_names
  attr(env, "parsed_names")  <- names(lst)
  env
}

list2env_safe <- function(lst, ...) {
  if (length(lst) > 0L) {
    list2env(lst)
  } else {
    new.env(...) 
  }
}

unnamed <- function(el) {
  "" == (names(el) %||% character(length(el)))
}

unnamed_count <- function(el) {
  sum(unnamed(el))
}

## To ensure backwards compatibility with
## [legacy mungebits](https://github.com/robertzk/mungebits),
## we perform nothing in many cases if the piece is not an R6 object (and hence
## a new mungepiece in the style of this package).
#' Whether a mungepiece is a legacy mungepiece (from the mungepieces package).
#'
#' @param x ANY. An R object to test.
#' @export
#' @return TRUE or FALSE according as the mungepiece is a legacy mungepiece.
is.legacy_mungepiece <- function(x) {
  methods::is(x, "mungepiece") && !methods::is(x, "R6")
}

#' Whether a mungebit is a legacy mungebit (from the mungebits package).
#'
#' @param x ANY. An R object to test.
#' @export
#' @return TRUE or FALSE according as the mungebit is a legacy mungebit.
is.legacy_mungebit <- function(x) {
  methods::is(x, "mungebit") && !methods::is(x, "R6")
}

#' Whether a train or predict function is a legacy function (from the mungebits package).
#'
#' Note that only functions constructed by the \code{munge} helper
#' will be identifiable using this method.
#'
#' @param x ANY. An R object to test.
#' @export
#' @return TRUE or FALSE according as the mungebit is a legacy train or
#'    predict function, determined using the \code{"legacy_mungebit_function"}
#"    class.
is.legacy_mungebit_function <- function(x) {
  methods::is(x, "legacy_mungebit_function")
}

ensure_legacy_mungebits_package <- function() {
  if (!requireNamespace("mungebits", quietly = TRUE)) {
    stop("The legacy mungebits package is required to create legacy mungebits.")
  }
}

#' Tag a function as a legacy mungebit function.
#'
#' @param x function. An R function to tag.
#' @return \code{x} with additional class "legacy_mungebit_function".
as.legacy_function <- function(x) {
  class(x) <- c("legacy_mungebit_function", class(x))
  x
}

#' Determine whether or not a given object is a transformation.
#'
#' Transformations can be either column or multi column transformations.
#'
#' @param x ANY. R object to test.
#' @return \code{TRUE} or \code{FALSE} according as it is a transformation.
#' @export
is.transformation <- function(x) {
  inherits(x, "transformation")
}

