script <- normalizePath(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value=TRUE)[1]))
source(file.path(dirname(script), "common.R"))
source(file.path(dirname(script), "deployment_files.R"))
validate_portable <- function() {
  staging <- tempfile("atlas-portable-")
  dir.create(staging)
  old <- getwd()
  on.exit({setwd(old);unlink(staging,recursive=TRUE)},add=TRUE)
  files <- deployment_files(app_dir)
  stopifnot(!"sc1assay_RNA.h5" %in% files)
  for(f in files) {
    dir.create(dirname(file.path(staging,f)),recursive=TRUE,showWarnings=FALSE)
    stopifnot(file.copy(file.path(app_dir,f),file.path(staging,f)))
  }
  setwd(staging)
  stopifnot(!file.exists("sc1assay_RNA.h5"))
  app <- source("app.R",local=new.env())$value
  stopifnot(inherits(app,"shiny.appobj"))
  manifest <- read.dcf("expression.dcf")
  stopifnot(unname(tools::md5sum("sc1assay_RNA.h5"))==manifest[1,"MD5"])
  h <- hdf5r::H5File$new("sc1assay_RNA.h5","r")
  stopifnot(identical(as.integer(h[["grp/data"]]$dims),c(24561L,32319L)))
  gene <- readRDS("sc1gene.rds")
  values <- h[["grp/data"]][unname(gene$RNA["CD34"]),]
  stopifnot(length(values)==32319,all(is.finite(values)),any(values>0))
  h$close_all()
  writeLines(c("Portable GitHub app: PASS","10 binary parts restored to an identical HDF5.",
    "app.R loaded with no preexisting HDF5 or original Seurat; CD34 query PASS.",
    paste("Restored HDF5 MD5:",manifest[1,"MD5"])),file.path(report_dir,"portable-validation.txt"))
}
validate_portable()
