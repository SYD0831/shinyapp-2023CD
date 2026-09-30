script <- normalizePath(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value=TRUE)[1]))
source(file.path(dirname(script), "common.R"))
validate_independence <- function() {
  input <- file.path(project_root,"pei23_scarche_anno.Rdata")
  hidden <- paste0(input,".independence-test")
  stopifnot(file.exists(input), !file.exists(hidden))
  before <- tools::md5sum(input)
  stopifnot(file.rename(input,hidden))
  on.exit({if(file.exists(hidden)) stopifnot(file.rename(hidden,input))},add=TRUE)
  stopifnot(!file.exists(input))
  child <- callr::r_bg(function(app,libs) {
    .libPaths(libs)
    shiny::runApp(app,host="127.0.0.1",port=3839,launch.browser=FALSE)
  },args=list(app_dir,.libPaths()),stdout=file.path(report_dir,"independent-startup.log"),
    stderr=file.path(report_dir,"independent-startup-errors.log"))
  on.exit(child$kill(),add=TRUE)
  ready <- FALSE
  for(i in seq_len(30)) {
    if(!child$is_alive()) stop("Independent Shiny process exited")
    status <- tryCatch(curl::curl_fetch_memory("http://127.0.0.1:3839")$status_code,error=function(e) 0)
    if(status==200) {ready<-TRUE;break}
    Sys.sleep(1)
  }
  stopifnot(ready,!file.exists(input))
  result <- processx::run(file.path(R.home("bin"),"Rscript"),
    file.path(project_root,"scripts","validate_runtime.R"),error_on_status=FALSE)
  writeLines(c(result$stdout,result$stderr),file.path(report_dir,"independent-queries.log"))
  stopifnot(result$status==0,!file.exists(input))
  child$kill()
  stopifnot(file.rename(hidden,input))
  after <- tools::md5sum(input)
  stopifnot(identical(unname(before),unname(after)))
  writeLines(c("Independent of original Seurat RDS/Rdata: PASS",
    "Original path absent during fresh Shiny HTTP startup and fresh R query/reactive tests.",
    paste("Restored input MD5:",unname(after))),file.path(report_dir,"independence.txt"))
}
validate_independence()
