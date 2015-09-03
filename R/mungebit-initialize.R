#' Constructor for mungebit class.
#'
#' Mungebits are atomic data transformations of a data.frame that,
#' loosely speaking, aim to modify "one thing" about a variable or
#' collection of variables. This is pretty loosely defined, but examples
#' include dropping variables, mapping values, discretization, etc.
#'
#' @param train_function function. This specifies the behavior to perform
#'    on the dataset when preparing for model training. A value of NULL
#'    specifies that there should be no training step, i.e., the data
#'    should remain untouched.
#' @param predict_function function. This specifies the behavior to perform
#'    on the dataset when preparing for model prediction. A value of NULL
#'    specifies that there should be no prediction step, i.e., the data
#'    should remain untouched.
#' @param enforce_train logical. Whether or not to flip the trained flag
#'    during runtime. Set this to FALSE if you are experimenting with
#'    or debugging the mungebit.
#' @examples
#' mb <- mungebit(column_transformation(function(column, scale = NULL) {
#'   # `trained` is a helper provided by mungebits indicating TRUE or FALSE
#'   # according as the mungebit has been run on a dataset.
#'   if (!trained) {
#'     cat("Column scaled by ", inputs$scale, "\n")
#'   } else {
#'     # `inputs` is a helper provided by mungebits. We remember the
#'     # the `scale` so we can re-use it during prediction.
#'     inputs$scale <- scale
#'   }
#'   column * inputs$scale
#' }))
#' 
#' # A `mungeplane` is just a lightweight wrapper to keep track of our data so
#' # the mungebit can perform side effects (i.e., modify the data without an
#' # explicit assignment <- operator).
#' irisp <- mungeplane(iris)
#' mb$run(irisp, 'Sepal.Length', 2)
#'
#' head(mp$data[[1]] / iris[[1]])
#' # > [1] 2 2 2 2 2 2
#' mb$run(mp, 'Sepal.Length')
#' # > Column scaled by 2
#' head(mp$data[[1]] / iris[[1]])
#' # > [1] 4 4 4 4 4 4 
initialize <- function(train_function   = base::identity,
                       predict_function = train_function,
                       enforce_train = TRUE) {

  # TODO: (RK) Sanity checks?
  self$.train_function   <- train_function
  self$.predict_function <- predict_function
  self$.inputs           <- new.env(parent = emptyenv())
  self$.trained          <- FALSE
  self$.enforce_train    <- enforce_train
}
