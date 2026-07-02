#' Say hello
#'
#' A simple example function that returns a friendly greeting. Use it as a
#' template for writing your own package functions.
#'
#' @param name A character string with the name to greet. Defaults to
#'   `"world"`.
#'
#' @return A character string containing the greeting.
#' @export
#'
#' @examples
#' hello_world()
#' hello_world("Philipp")
hello_world <- function(name = "world") {
  if (!is.character(name) || length(name) != 1) {
    stop("`name` must be a single character string.", call. = FALSE)
  }
  paste0("Hello, ", name, "!")
}
