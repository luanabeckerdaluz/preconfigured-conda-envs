
#!/usr/bin/env Rscript

#============================================================
# Detect OS to set PAK repo
#============================================================

os <- .Platform$OS.type
sys <- Sys.info()["sysname"]
arch <- Sys.info()["machine"]

# Set fixed date
CRAN_FIXED_DATE <- "2026-02-10"

# Set PAK remote URL based on current system
repo <- switch(
  os,
  windows = "https://packagemanager.posit.co/cran/latest",
  unix = switch(
    sys,
    Darwin = ifelse(grepl("arm64|aarch64", arch),
                    "https://packagemanager.posit.co/cran/__macos__/arm64/latest",
                    "https://packagemanager.posit.co/cran/__macos__/x86_64/latest"),
    paste0('https://packagemanager.posit.co/cran/__linux__/jammy/', CRAN_FIXED_DATE)
  )
)

# install.packages("pak", repos = sprintf("https://r-lib.github.io/p/pak/stable/%s/%s/%s", .Platform$pkgType, R.Version()$os, R.Version()$arch))

cat(paste0(
  "====================================================================", "\n",
  "✔ os: ", os, "\n",
  "✔ sys: ", sys, "\n",
  "✔ arch: ", arch, "\n",
  "✔ Using CRAN fixed date = ", CRAN_FIXED_DATE, "\n",
  "✔ Setting repo = ", repo, "\n",
  "====================================================================", "\n" 
))

options(
  repos = c(CRAN = repo),
  warn = 2,
  timeout = 300
)

#============================================================
# Parse input parameters
#============================================================

# Get arguments from command line
args <- commandArgs(trailingOnly = TRUE)
# Check input parameters
if (length(args) < 1 || is.na(args[1]) || args[1] == "") {
  print(paste("Temporary folder:", args[1]))
  stop("❌ INTERNAL ERROR: Error when parsing temporary folder. Please, contact support!")
}
r_yml_requirements_filepath <- args[1]
cat("📦 r_yml_requirements_filepath:", r_yml_requirements_filepath, "\n")


#============================================================
# Install R packages not available on conda
#============================================================

# Parse 'r-packages-not-on-conda.yml' file (No need to use 'yaml' package)
lines <- readLines(r_yml_requirements_filepath, warn = FALSE)
lines <- lines[lines != ""]
pkgs <- gsub("^- ", "", lines)

# Install packages using pak
pak::pkg_install(pkgs)