script <- normalizePath(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value=TRUE)[1]))
source(file.path(dirname(script), "common.R"))
setwd(app_dir)
app <- source("server.R",local=TRUE)$value
rss <- function() unname(ps::ps_memory_info()["rss"])/1024^2
baseline <- rss()
stopifnot(nrow(sc1meta)==32319, length(sc1gene$RNA)==24561,
 identical(sc1conf$UI,c("Cell Type","Sample","Disease Status","Tissue","Patient LSC Type","Cell LSC Class")))
pdf(file.path(report_dir,"runtime-validation-plots.pdf"),width=8,height=7)
peak <- baseline
for (field in sc1conf$UI) {
  groups <- strsplit(sc1conf[UI==field]$fID,"|",fixed=TRUE)[[1]]
  p <- sc2Ddimr(sc1conf,sc1meta,sc1dimr,"umap",field,"sc1assay_",sc1gene,
    "Cell Information",field,groups,0,100,0.5,"Original",cList[["White-Red"]],14,"Square",FALSE,TRUE)
  stopifnot(nrow(p$data)==32319)
  print(p); grid::grid.draw(g_legend(p))
  subp <- sc2Ddimr(sc1conf,sc1meta,sc1dimr,"umap",field,"sc1assay_",sc1gene,
    "Cell Information",field,groups[1],0,100,0.5,"Original",cList[["White-Red"]],14,"Square",FALSE,TRUE)
  stopifnot(nrow(subp$data)==sum(sc1meta[[sc1conf[UI==field]$ID]]==groups[1]))
  peak <- max(peak,rss())
}
before_gene <- rss()
stopifnot(identical(sc1def$gene1$RNA, "MCL1"))
for(gene in c(sc1def$gene1$RNA,"CD34","LYZ","MPO")) {
  stopifnot(gene %in% names(sc1gene$RNA))
  p <- sc2Ddimr(sc1conf,sc1meta,sc1dimr,"umap",gene,"sc1assay_",sc1gene,
    "Assay: RNA","Sample",levels(sc1meta$sample),0,100,0.5,"Max-1st",cList[["White-Red"]],14,"Square",FALSE,FALSE)
  stopifnot(nrow(p$data)==32319,all(is.finite(p$data$val)))
  print(p); grid::grid.draw(g_legend(p)); peak <- max(peak,rss())
}
dev.off()
shiny::testServer(app, {
  session$setInputs(sc1a2dr="umap", sc1a2ass1="Cell Information", sc1a2ass2="Assay: RNA",
    sc1a2inp1="Cell Type",sc1a2inp2="CD34",sc1a2sub1="Sample",sc1a2sub2=levels(sc1meta$sample),
    sc1a2min1=0,sc1a2max1=100,sc1a2min2=0,sc1a2max2=100,
    sc1a2siz=0.5,sc1a2ord1="Original",sc1a2ord2="Max-1st",sc1a2col1="Blue-Yellow-Red",
    sc1a2col2="White-Red",sc1a2fsz="Medium",sc1a2psz="Medium",sc1a2asp="Square",
    sc1a2txt=FALSE,sc1a2lab1=TRUE,sc1a2lab2=TRUE)
  stopifnot(nrow(sc1a2oup1()$data)==32319,nrow(sc1a2oup2()$data)==32319)
  stopifnot(length(output$sc1a2oup1)>0,length(output$sc1a2oup2)>0)
  session$setInputs(sc1a2inp2="LYZ",sc1a2sub2=levels(sc1meta$sample)[1])
  stopifnot(nrow(sc1a2oup2()$data)==1197)
  peak <<- max(peak,rss())
})
writeLines(c("Runtime plotting and all six subset fields: PASS",
  "Shiny server reactive UMAP, CD34/LYZ queries and 1197-cell sample subset: PASS",
  paste("Startup RSS MiB:",round(baseline,1)),paste("Before gene queries RSS MiB:",round(before_gene,1)),
  paste("Sampled peak RSS MiB:",round(peak,1))),file.path(report_dir,"runtime-validation.txt"))
