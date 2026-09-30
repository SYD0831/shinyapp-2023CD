script <- normalizePath(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value=TRUE)[1]))
source(file.path(dirname(script), "common.R"))
input <- file.path(app_dir,"sc1assay_RNA.h5")
parts_dir <- file.path(app_dir,"expression-parts")
dir.create(parts_dir,showWarnings=FALSE)
con <- file(input,"rb")
parts <- character()
i <- 1L
repeat {
  bytes <- readBin(con,"raw",n=45L*1024L*1024L)
  if(!length(bytes)) break
  name <- sprintf("expression-parts/rna-%03d.bin",i)
  writeBin(bytes,file.path(app_dir,name))
  parts <- c(parts,name)
  i <- i+1L
}
close(con)
stale <- setdiff(list.files(parts_dir,full.names=TRUE),file.path(app_dir,parts))
if(length(stale)) stop("Old expression parts remain; archive them before preparing deployment.")
write.dcf(data.frame(File="sc1assay_RNA.h5",Size=format(file.info(input)$size,scientific=FALSE,trim=TRUE),
  MD5=unname(tools::md5sum(input)),Parts=paste(parts,collapse=",")),file.path(app_dir,"expression.dcf"),width=10000)
file.copy(file.path(project_root,"config","app.R"),file.path(app_dir,"app.R"),overwrite=TRUE)
writeLines(c(".git/","logs/","*.log","*.Rdata","*.RData","final_seurat.rds",".DS_Store",
 "sc1assay_RNA.h5","manifest.json","*.partial"),file.path(app_dir,".rscignore"))
source(file.path(project_root,"scripts","deployment_files.R"))
files <- deployment_files(app_dir)
rsconnect::writeManifest(appDir=app_dir,appFiles=files,appPrimaryDoc="app.R")
message("GitHub parts and Connect Cloud manifest prepared.")
