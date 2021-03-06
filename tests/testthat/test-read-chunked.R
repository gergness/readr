context("read-chunked")

test_that("read_lines_chunked", {
  file <- readr_example("mtcars.csv")
  num_rows <- length(readLines(file))

  get_sizes <- function(data, pos) sizes[[length(sizes) + 1]] <<- length(data)

  # Full file in one chunk
  sizes <- list()
  read_lines_chunked(file, get_sizes)
  expect_equal(num_rows, sizes[[1]])

  # Each line separately
  sizes <- list()
  read_lines_chunked(file, get_sizes, chunk_size = 1)
  expect_true(all(sizes == 1))
  expect_equal(num_rows, length(sizes))

  # In chunks of 5
  sizes <- list()
  read_lines_chunked(file, get_sizes, chunk_size = 5)
  expect_true(all(sizes[1:6] == 5))
  expect_true(all(sizes[[7]] == 3))

  # Halting early
  get_sizes_stop <- function(data, pos) {
    sizes[[length(sizes) + 1]] <<- length(data)
    if (pos >= 5) {
      return(FALSE)
    }
  }
  sizes <- list()
  read_lines_chunked(file, get_sizes_stop, chunk_size = 5)
  expect_true(length(sizes) == 2)
  expect_true(all(sizes[1:2] == 5))
})

test_that("read_delim_chunked", {
  file <- readr_example("mtcars.csv")
  unchunked <- read_csv(file)

  get_dims <- function(data, pos) dims[[length(dims) + 1]] <<- dim(data)

  # Full file in one chunk
  dims <- list()
  read_csv_chunked(file, get_dims)
  expect_equal(dim(unchunked), dims[[1]])

  # Each line separately
  dims <- list()
  read_csv_chunked(file, get_dims, chunk_size = 1)
  expect_true(all(vapply(dims[1:6], identical, logical(1), c(1L, 11L))))
  expect_equal(nrow(unchunked), length(dims))

  # In chunks of 5
  dims <- list()
  read_csv_chunked(file, get_dims, chunk_size = 5)
  expect_true(all(vapply(dims[1:6], identical, logical(1), c(5L, 11L))))
  expect_true(identical(dims[[7]], c(2L, 11L)))

  # Halting early
  get_dims_stop <- function(data, pos) {
    dims[[length(dims) + 1]] <<- dim(data)
    if (pos >= 5) {
      return(FALSE)
    }
  }
  dims <- list()
  read_csv_chunked(file, get_dims_stop, chunk_size = 5)
  expect_true(length(dims) == 2)
  expect_true(all(vapply(dims[1:2], identical, logical(1), c(5L, 11L))))
})

test_that("DataFrameCallback works as intended", {
  f <- readr_example("mtcars.csv")
  unchunked <- read_csv(f)
  fun3 <- DataFrameCallback$new(function(x, pos) subset(x, gear == 3))

  out1 <- read_csv_chunked(f, fun3)
  out2 <- read_csv_chunked(readr_example("mtcars.csv"), fun3, chunk_size = 10)

  expect_true(all.equal(subset(unchunked, gear == 3), out1))
  expect_true(all.equal(out1, out2))


  # No matching rows
  fun5 <- DataFrameCallback$new(function(x, pos) subset(x, gear == 5))
  out3 <- read_csv_chunked(readr_example("mtcars.csv"), fun5)
  out4 <- read_csv_chunked(readr_example("mtcars.csv"), fun5, chunk_size = 10)

  expect_true(all.equal(subset(unchunked, gear == 5), out3))
  expect_true(all.equal(out3, out4))
})
