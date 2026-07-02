test_that("hello_world greets the world by default", {
  expect_equal(hello_world(), "Hello, world!")
})

test_that("hello_world greets a given name", {
  expect_equal(hello_world("Philipp"), "Hello, Philipp!")
})

test_that("hello_world rejects invalid input", {
  expect_error(hello_world(1))
  expect_error(hello_world(c("a", "b")))
})
