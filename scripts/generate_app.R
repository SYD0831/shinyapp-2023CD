script <- normalizePath(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value=TRUE)[1]))
source(file.path(dirname(script), "common.R"))
source(file.path(project_root, "config", "atlas.R"))
suppressPackageStartupMessages({library(Seurat); library(ShinyCell2); library(data.table)})
input <- file.path(project_root, "pei23_scarche_anno.Rdata")
env <- new.env(parent = emptyenv())
load(input, envir = env)
stopifnot(exists("seurat", env, inherits = FALSE))
obj <- env$seurat
stopifnot(inherits(obj, "Seurat"), "RNA" %in% Assays(obj),
  "data" %in% Layers(obj[["RNA"]]), "umap" %in% Reductions(obj),
  all(names(metadata_labels) %in% colnames(obj[[]])))
expr <- GetAssayData(obj, assay = "RNA", layer = "data")
coords <- Embeddings(obj, "umap")
stopifnot(nrow(expr) > 0, ncol(expr) == ncol(obj),
  identical(colnames(expr), rownames(obj[[]])),
  identical(rownames(coords), colnames(expr)), ncol(coords) >= 2,
  all(is.finite(coords[, 1:2])), !anyDuplicated(rownames(expr)))
if (inherits(expr, "sparseMatrix")) stopifnot(all(is.finite(expr@x)), length(expr@x) > 0)
if (!"NormalizeData.RNA" %in% names(obj@commands)) stop("RNA normalization provenance missing; inspect before export.")
inspection <- list(path = input, bytes = file.info(input)$size, cells = ncol(obj),
  genes = nrow(expr), assays = Assays(obj), default_assay = DefaultAssay(obj),
  layers = setNames(lapply(Assays(obj), function(a) Layers(obj[[a]])), Assays(obj)),
  reductions = Reductions(obj), metadata = colnames(obj[[]]),
  object_version = as.character(obj@version), normalization = obj@commands[["NormalizeData.RNA"]]@params)
capture.output(str(inspection), file=file.path(report_dir, "input-inspection.txt"))
conf <- createConfig(obj, meta.to.include = names(metadata_labels))
conf <- modMetaName(conf, names(metadata_labels), unname(metadata_labels))
old_labels <- strsplit(conf[ID == "sample_type"]$fID, "|", fixed=TRUE)[[1]]
stopifnot(all(old_labels %in% names(disease_labels)))
conf <- modLabels(conf, "sample_type", unname(disease_labels[old_labels]))
conf <- modDefault(conf, "scArche_anno", "sample")
conf <- reorderMeta(conf, names(metadata_labels))
stopifnot(setequal(strsplit(conf[ID=="scArche_anno"]$fID,"|",fixed=TRUE)[[1]], names(cell_type_colours)))
conf[ID=="scArche_anno", `:=`(fID=paste(names(cell_type_colours),collapse="|"),
  fUI=paste(names(cell_type_colours),collapse="|"), fCL=paste(cell_type_colours,collapse="|"))]
genes <- intersect(VariableFeatures(obj[["RNA"]]), rownames(expr))
if (length(genes) < 2) genes <- rownames(expr)
genes <- head(genes, 10)
stopifnot(default_gene %in% rownames(expr))
genes <- head(unique(c(default_gene, genes)), 10)
dir.create(app_dir, showWarnings=FALSE)
stopifnot(all(c("assay", "assay.slot", "dimred.to.use") %in% names(formals(makeShinyFiles))))
makeShinyFiles(obj, conf, assay="RNA", assay.slot="data", dimred.to.use="umap",
  shiny.prefix="sc1", shiny.dir=app_dir, default.dimred="umap",
  default.gene1=genes[1], default.gene2=genes[2], default.multigene=genes, chunkSize=100)
source(file.path(project_root, "scripts", "customize_app.R"))
# Compare the actual output to the unchanged input, including float32 HDF5 precision.
meta <- readRDS(file.path(app_dir,"sc1meta.rds"))
dimr <- readRDS(file.path(app_dir,"sc1dimr.rds"))
stopifnot(identical(meta$cellID, colnames(expr)), identical(dimr$umap,coords[,1:2]),
  identical(names(meta), c("cellID", names(metadata_labels))))
for (key in names(metadata_labels)) {
  expected <- as.character(obj[[]][[key]])
  if (key == "sample_type") expected <- unname(disease_labels[expected])
  stopifnot(identical(as.character(meta[[key]]), expected))
}
h <- hdf5r::H5File$new(file.path(app_dir,"sc1assay_RNA.h5"),"r")
stopifnot(identical(as.integer(h[["grp/data"]]$dims), as.integer(dim(expr))))
set.seed(20260930)
rows <- sort(unique(c(match(genes,rownames(expr)), sample(nrow(expr),100))))
actual <- h[["grp/data"]][rows,]
expected <- as.matrix(expr[rows,,drop=FALSE])
max_error <- max(abs(actual-expected))
stopifnot(all(abs(actual-expected) <= 1e-6*pmax(1,abs(expected))))
h$close_all()
capture.output(list(status="PASS", sampled_genes=length(rows), all_cells=ncol(expr),
  max_absolute_error=max_error, default_genes=genes),file=file.path(report_dir,"data-validation.txt"))
writeLines(capture.output(sessionInfo()),file.path(report_dir,"generation-session.txt"))
d <- packageDescription("ShinyCell2")
writeLines(c(paste("ShinyCell2",d$Version),paste("GitHub commit",d$RemoteSha)),file.path(report_dir,"shinycell-version.txt"))
message("Generation and data validation PASS")
status <- system2(file.path(R.home("bin"),"Rscript"), shQuote(file.path(project_root,"scripts","prepare_github.R")))
if(status != 0) stop("App generated, but GitHub packaging failed; see prepare_github.R output.")
