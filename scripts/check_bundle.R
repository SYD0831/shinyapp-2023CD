script <- normalizePath(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value=TRUE)[1]))
source(file.path(dirname(script), "common.R"))
source(file.path(dirname(script), "deployment_files.R"))
files <- deployment_files(app_dir)
writeLines(files, file.path(report_dir,"deployment-files.txt"))
deps <- rsconnect::appDependencies(app_dir, appFiles=files)
write.csv(deps, file.path(report_dir,"runtime-dependencies.csv"), row.names=FALSE)
# Use rsconnect's real deployment bundler without uploading anything.
# This internal interface is checked against the installed rsconnect version.
ns <- asNamespace("rsconnect")
metadata <- get("appMetadata",ns)(appDir=app_dir, appFiles=files,
  appMode="shiny", isShinyappsServer=TRUE)
bundle <- get("bundleApp",ns)(appName="single-cell-atlas", appDir=app_dir,
  appFiles=files, appMetadata=metadata, verbose=TRUE)
destination <- file.path(report_dir,"single-cell-atlas-bundle.tar.gz")
stopifnot(file.copy(bundle,destination,overwrite=TRUE))
contents <- utils::untar(destination,list=TRUE)
writeLines(contents,file.path(report_dir,"bundle-contents.txt"))
stopifnot(!any(grepl("(?i)\\.rdata$|seurat|(^|/)\\.git/|(^|/)logs/", contents, perl=TRUE)))
size <- file.info(file.path(app_dir,files))$size
write.csv(data.frame(file=files,bytes=size)[order(size,decreasing=TRUE),],
  file.path(report_dir,"runtime-file-sizes.csv"),row.names=FALSE)
writeLines(c(paste("App bytes:",sum(size)),paste("Actual rsconnect bundle bytes:",file.info(destination)$size),
  paste("rsconnect:",packageVersion("rsconnect"))),file.path(report_dir,"bundle-size.txt"))
