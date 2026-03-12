
#!/usr/bin/env Rscript

#================================================================
# Usage
#     Rscript install_source.R ../pkgs-to-install-from-source.yml
#================================================================

# Set CRAN remote URL
repo <- "https://cloud.r-project.org"

cat(paste0(
  "====================================================================", "\n",
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
# Parse packages list
#============================================================

# Parse 'pkgs-to-install-from-source.yml' file (No need to use 'yaml' package)
lines <- readLines(r_yml_requirements_filepath, warn = FALSE)
lines <- lines[lines != ""]
pkgs <- gsub("^- ", "", lines)

#============================================================
# Install R packages from source
#============================================================

install.packages(pkgs, type = 'source', dependencies = TRUE)