
DATE <- "2025-01-01"

options(
    warn = 2,
    timeout = 300,
    repos = c(CRAN = paste0('https://packagemanager.posit.co/cran/__linux__/jammy/', DATE))
);

pak::pkg_install(c(
    'hol430/ApsimOnR',
    'SticsRPacks/CroPlotR@*release',
    'SticsRPacks/SticsRFiles@*release',
    'SticsRPacks/SticsOnR@*release',
    'SticsRPacks/CroptimizR@*release',
    'apsimx',
    'rapsimng',
    'BayesianTools'
))