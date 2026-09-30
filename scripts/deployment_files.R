deployment_files <- function(app_dir) {
  files <- rsconnect::listDeploymentFiles(app_dir)
  expected <- c("ui.R", "server.R", "shinyFunc.R",
    "sc1conf.rds", "sc1meta.rds", "sc1gene.rds", "sc1dimr.rds", "sc1def.rds",
    "www/custom.css")
  if(file.exists(file.path(app_dir,"expression.dcf"))) {
    data_manifest <- read.dcf(file.path(app_dir,"expression.dcf"))
    parts <- strsplit(data_manifest[1,"Parts"],",",fixed=TRUE)[[1]]
    stopifnot(all(grepl("^expression-parts/rna-[0-9]{3}\\.bin$",parts)))
    expected <- c(expected,"app.R","expression.dcf",parts)
  } else expected <- c(expected,"sc1assay_RNA.h5")
  unexpected <- setdiff(files, expected)
  if (length(unexpected)) stop("Unexpected deployment files: ", paste(unexpected, collapse=", "))
  if (length(setdiff(expected, files))) stop("Required runtime files are missing.")
  links <- Sys.readlink(file.path(app_dir, files))
  if (any(!is.na(links) & nzchar(links))) stop("Deployment files must not be symlinks.")
  files
}
