script <- normalizePath(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value=TRUE)[1]))
source(file.path(dirname(script), "common.R"))
args <- commandArgs(TRUE)
staging <- file.path(project_root, ".deploy", "connect-cloud")
dir.create(staging, recursive=TRUE, showWarnings=FALSE)
# Upload the complete HDF5, without the GitHub binary parts.
files <- c("app.R", "ui.R", "server.R", "shinyFunc.R", "expression.dcf",
  "sc1conf.rds", "sc1meta.rds", "sc1gene.rds", "sc1dimr.rds", "sc1def.rds",
  "www/custom.css", "sc1assay_RNA.h5")
stopifnot(all(file.exists(file.path(app_dir, files))))
for (f in files) {
  dir.create(dirname(file.path(staging, f)), recursive=TRUE, showWarnings=FALSE)
  stopifnot(file.copy(file.path(app_dir, f), file.path(staging, f), overwrite=TRUE))
}
manifest <- read.dcf(file.path(staging, "expression.dcf"))
h5 <- file.path(staging, manifest[1,"File"])
stopifnot(file.info(h5)$size == as.numeric(manifest[1,"Size"]),
  unname(tools::md5sum(h5)) == manifest[1,"MD5"])
local({
  old <- getwd()
  on.exit(setwd(old))
  setwd(staging)
  app <- source("app.R", local=new.env())$value
  stopifnot(inherits(app,"shiny.appobj"), readRDS("sc1def.rds")$gene1$RNA == "MCL1")
  h <- hdf5r::H5File$new("sc1assay_RNA.h5", "r")
  on.exit(h$close_all(), add=TRUE)
  index <- readRDS("sc1gene.rds")$RNA["MCL1"]
  values <- h[["grp/data"]][unname(index), ]
  stopifnot(length(values)==32319, all(is.finite(values)), any(values>0))
})
writeLines(files, file.path(report_dir, "connect-cloud-direct-files.txt"))
if ("--prepare-only" %in% args) {
  ns <- asNamespace("rsconnect")
  metadata <- get("appMetadata", ns)(appDir=staging, appFiles=files,
    appMode="shiny", isShinyappsServer=FALSE)
  bundle <- get("bundleApp", ns)(appName="single-cell-atlas-direct", appDir=staging,
    appFiles=files, appMetadata=metadata, verbose=TRUE)
  destination <- file.path(report_dir,"connect-cloud-direct-bundle.tar.gz")
  stopifnot(file.copy(bundle, destination, overwrite=TRUE))
  contents <- utils::untar(destination, list=TRUE)
  contents <- sub("^\\./", "", contents)
  stopifnot("sc1assay_RNA.h5" %in% contents,
    !any(grepl("expression-parts|\\.Rdata$|\\.git/", contents, ignore.case=TRUE)))
  writeLines(c("Complete-HDF5 app startup and MCL1 query: PASS",
    paste("HDF5 MD5:",manifest[1,"MD5"]),
    paste("Actual rsconnect bundle bytes:",file.info(destination)$size)),
    file.path(report_dir,"connect-cloud-direct-validation.txt"))
} else {
  accounts <- rsconnect::accounts()
  if (!any(accounts$server == "connect.posit.cloud" & accounts$name == "syd088"))
    stop("Authenticate syd088 first with rsconnect::connectCloudUser().")
  rsconnect::deployApp(appDir=staging, appFiles=files, appPrimaryDoc="app.R",
    appName="single-cell-atlas-direct", appTitle="Single-cell Atlas",
    account="syd088", server="connect.posit.cloud", launch.browser=FALSE,
    recordDir=file.path(staging,"rsconnect"))
}
