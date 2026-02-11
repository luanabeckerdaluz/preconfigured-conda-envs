#============================================================
# Detect OS to set PAK repo
#============================================================

os <- .Platform$OS.type
sys <- Sys.info()["sysname"]
arch <- Sys.info()["machine"]

# Set fixed date
CRAN_FIXED_DATE <- "2025-01-01"

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

pak::pkg_install(c(
    'hol430/ApsimOnR@v1.0.59',        # GITHUB = Sep-2020
    'SticsRPacks/CroPlotR@v1.0.0',    # GITHUB = Jan-2026
    'SticsRPacks/SticsRFiles@v1.6.0', # GITHUB = Jun-2025
    'SticsRPacks/SticsOnR@1.3.0',     # GITHUB = Mar-2025
    'SticsRPacks/CroptimizR@v1.0.0',  # GITHUB = Jan-2025
    'apsimx@2.8.235',                 # CRAN = Mar-2025
    'rapsimng@0.4.6',                 # CRAN = Fev-2026
    'BayesianTools@0.1.8'             # CRAN = Jan-2023
))