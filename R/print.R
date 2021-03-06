## Elegant printing is hard work! This file contains some helpers
## to make outputting mungebits objects beautiful.
# Print a `mungepiece` object.
print_mungepiece <- function(x, ...) {
  if (is.legacy_mungepiece(x)) {
    cat(crayon::blue$bold("Legacy mungepiece"))
    return()
  }
  cat(crayon::blue$bold("Mungepiece"), "with:\n")
  if (length(x$train_args()) > 0 && identical(x$train_args(), x$predict_args())) {
    print_args(x$train_args(), "train and predict", "green", ...)
  } else {
    if (length(x$train_args()) > 0) {
      print_args(x$train_args(), "train", "green", ...)
    }
    if (length(x$predict_args()) > 0) {
      print_args(x$predict_args(), "predict", "green", ...)
    }
  }
  print(x$mungebit(), ..., indent = 1L, prefix2 = "* ")
}

print_args <- function(args, type, color, ..., full = FALSE, label = "arguments") {
  ## A dynamic way to fetch the color palette from the crayon package.
  style <- getFromNamespace(color, "crayon")$bold
  cat(sep = "", "  * ", style(paste(type, label)), ":\n")
  max_lines <- if (isTRUE(full)) Inf else 5L
  cat(crayon::silver(deparse2(args, max_lines = max_lines, indent = 3L)), "\n")
}

# Print a `mungebit` object.
print_mungebit <- function(x, ..., indent = 0L, prefix2 = "", show_trained = TRUE, full = FALSE) {
  if (is.legacy_mungebit(x)) {
    cat(crayon::blue$bold("Legacy mungebit"))
    return()
  }
  prefix <- paste(rep("  ", indent), collapse = "")
  trained <- function() {
    if (isTRUE(show_trained)) {
      paste0(" (", (if (x$trained()) crayon::green$bold("trained")
                    else  crayon::red$bold("untrained")), ") ")
    } else " "
  }
  cat(sep = "", prefix, prefix2, crayon::green("Mungebit"), trained(), "with",
      if (x$nonstandard()) " nonstandard evaluation", ":\n")
  if (length(x$input()) > 0) {
    cat(sep = "", prefix, "  * ", crayon::magenta$bold("input"), ": \n")
    max_lines <- if (isTRUE(full)) Inf else 5L
    cat(crayon::silver(deparse2(x$input(), max_lines = max_lines, indent = indent + 2L)), "\n")
  }
  if (isTRUE(all.equal(x$train_function(), x$predict_function()))) {
    print_mungebit_function(x$train_function(), "train and predict",
                            "green", indent + 1L, ..., full = full)
  } else {
    print_mungebit_function(x$train_function(),   "train",   "green",  indent + 1L, ..., full = full)
    print_mungebit_function(x$predict_function(), "predict", "yellow", indent + 1L, ..., full = full)
  }
}

print_mungebit_function <- function(fn, type, color, indent, ..., full = FALSE) {
  prefix <- paste(rep("  ", indent), collapse = "")
  ## A dynamic way to fetch the color palette from the crayon package.
  style <- getFromNamespace(color, "crayon")$bold
  if (is.null(fn)) {
    cat(sep = "", prefix, "* ", style(paste0("No ", type, " function.")), "\n")
  } else {
    cat(sep = "", prefix, "* ", style(paste0(type, " function")), ":\n")
    if (methods::is(fn, "transformation")) {
      ## We delegate the printing work to the transformation.
      print(fn, indent = indent, ..., full = isTRUE(full))
    } else {
      max_lines <- if (isTRUE(full)) Inf else 5L
      cat(crayon::silver(function_snippet(fn, max_lines = max_lines, indent = indent + 1L)), "\n")
    }
  }
}

## This is the general helper used to print both
## `column_transformation` and `multi_column_transformation` objects.
print_transformation <- function(x, ..., indent = 0L, full = FALSE,
                                        byline = "Transformation") {
  prefix <- paste(rep("  ", indent), collapse = "")
  cat(sep = "", prefix, crayon::yellow(byline),
      if (isTRUE(environment(x)$nonstandard)) " with non-standard evaluation", ":")

  ## A little helper function to convert the function `x`
  ## into a character vector of length 1.
  snippet <- function(full. = full) {
    function_snippet(unclass(get("transformation", envir = environment(x))),
                     indent = indent + 1L,
                     max_lines = if (isTRUE(full.)) Inf else 5L)
  }

  ## If the `snippet` generated by trimming long bodies does not equal
  ## the `snippet` generated by printing the full function, show the
  ## user how to print the full body (by passing `full = TRUE` to
  ## `print`).
  if (!isTRUE(full) && !identical(snippet(FALSE), snippet(TRUE))) {
    cat(" use", crayon::bold("print(fn, full = TRUE)"), "to show full body)")
  }

  cat(sep = "", "\n", crayon::silver(snippet()), "\n")
}

## A helper function to turn functions into their string
## representations for convenient printing.
function_snippet <- function(fn, indent = 0L, max_lines = 5L) {
  prefix <- paste(rep("  ", indent), collapse = "")
  ## Note that `utils::head` will convert the function to a string
  ## for us. We use this to get a character representation of the
  ## formals of the function along with its body.
  str_fn <- as.character(utils::head(fn, 10000))
  ## However, `utils::head` uses four spaces per tab instead of two.
  str_fn <- gsub("    ", "  ", str_fn)

  if (!is.call(body(fn)) || !identical(body(fn)[[1L]], as.name("{"))) {
    ## If the function does not have braces `{` surrounding its
    ## body, squish the last two lines into a single line, so e.g.,
    ## `function(x)\n x` becomes `function(x) x`.
    str_fn[length(str_fn) - 1] <-
      c(paste(str_fn[seq(length(str_fn) - 1, length(str_fn))], collapse = ""))
    str_fn <- str_fn[seq_len(length(str_fn) - 1)]
    ## If the function body spills over, trim it.
    if (length(str_fn) > max_lines + 1) {
      str_fn <- c(str_fn[seq_len(max_lines)], paste0("..."))
    }
  } else {
    ## Squish the `{` onto a single line.
    braces <- str_fn == "{"
    ## Note the first line can never be just `{` since it is the formals
    ## of the function.
    str_fn[which(braces) - 1L] <- vapply(str_fn[which(braces) - 1L],
      function(s) paste0(s, "{"), character(1))
    str_fn <- str_fn[!braces]
    ## If the function body spills over, trim it.
    if (length(str_fn) > max_lines + 2) {
      str_fn <- c(str_fn[seq_len(max_lines)], "  # Rest of body...", "}")
    }
  }

  paste(vapply(str_fn, function(s) paste0(prefix, s), character(1)), collapse = "\n")
}

## Instead of translating `list(a = 1)` to the rather overcumbersome
## string `structure(list(a = 1), .Names = "a")`, this helper
## will simply turn it to `list(a = 1)`.
deparse2 <- function(obj, collapse = "\n", indent = 0L, max_lines = 5L) {
  conn <- textConnection(NULL, "w")
  ## Avoid printing unnecessary attributes.
  dput(obj, conn, control = c("keepNA", "keepInteger"))
  out <- textConnectionValue(conn)
  close(conn)
  ## `dput` uses four-space instead of two-space tabs.
  out <- gsub("    ", "  ", out)
  prefix <- paste(rep("  ", indent), collapse = "")
  out <- vapply(out, function(s) paste0(prefix, s), character(1))
  if (length(out) > max_lines + 1L) {
    out <- c(out[seq_len(max_lines)], paste0(prefix, "..."))
  }
  paste(out, collapse = collapse)
}

