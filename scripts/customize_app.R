# Sourced after common.R and config/atlas.R. Rebuilds only app code, never expression data.
defaults_path <- file.path(app_dir, "sc1def.rds")
defaults <- readRDS(defaults_path)
gene_index <- readRDS(file.path(app_dir, "sc1gene.rds"))
stopifnot(default_gene %in% names(gene_index$RNA))
defaults$gene1$RNA <- default_gene
saveRDS(defaults, defaults_path)
ShinyCell2::makeShinyCodes(shiny.title=atlas_title, shiny.footnotes="", shiny.prefix="sc1",
  shiny.headers="Atlas", shiny.dir=app_dir, defPtSiz=0.5)
ui_path <- file.path(app_dir, "ui.R")
ui <- readLines(ui_path)
idx <- grep("shinyUI(fluidPage(", ui, fixed=TRUE)
stopifnot(length(idx) == 1)
ui <- append(ui, '  tags$head(tags$link(rel="stylesheet", type="text/css", href="custom.css")),', after=idx)
idx <- grep('titlePanel(', ui, fixed=TRUE)
ui <- append(ui, sprintf('  tags$p(class="atlas-note", %s),', encodeString(atlas_note, quote='"')), after=idx)
idx <- grep("navbarPage(", ui, fixed=TRUE)
ui <- append(ui, '    selected = "atlas-umap",', after=idx)
idx <- grep('HTML("Side-by-side DimRed"),',ui,fixed=TRUE)
ui <- append(ui, '  value = "atlas-umap",',after=idx)
# Keep the primary reference-style view first in the navigation as well.
a1 <- grep("^### Tab1.a1:",ui); a2 <- grep("^### Tab1.a2:",ui); a3 <- grep("^### Tab1.a3:",ui)
stopifnot(length(a1)==1,length(a2)==1,length(a3)==1)
ui <- c(ui[seq_len(a1-1)],ui[a2:(a3-1)],ui[a1:(a2-1)],ui[a3:length(ui)])
# Show the subset controls initially, and toggle them closed on the first click.
ui <- gsub('togL % 2 == 1', 'togL % 2 == 0', ui, fixed=TRUE)
for (idx in grep('sc1[a-b][1-3]sub1"', ui)) {
  stopifnot(grepl("selected = sc1def$grp1",ui[idx+2],fixed=TRUE))
  ui[idx+2] <- sub('sc1def$grp1', '"Sample"',ui[idx+2],fixed=TRUE)
}
# Put attribution in a proper navbar footer (avoids empty tabs in current Shiny).
idx <- grep('^, br\\(\\),',ui)
stopifnot(length(idx)==1)
ui <- c(ui[seq_len(idx-1)], ', footer = tags$div(class="atlas-footer",',
 '  tags$p(tags$em("This webpage was made using "), tags$a("ShinyCell2",',
 '    href="https://github.com/the-ouyang-lab/ShinyCell2", target="_blank")))', ')))')
writeLines(ui,ui_path)
# Generated plotting helpers can run before server-side selectize has a value.
# Wait for inputs instead of emitting transient HDF5/indexing errors. Empty
# subset selection also waits, rather than silently showing every cell.
fun_path <- file.path(app_dir,"shinyFunc.R")
fun_text <- paste(readLines(fun_path),collapse="\n")
env <- new.env()
sys.source(fun_path,env)
for (name in ls(env,pattern="^sc")) {
  fn <- env[[name]]
  if (!is.function(fn)) next
  needed <- intersect(names(formals(fn)),c("inp1","inp2","inpdr","inpDtyp","inpDtyp1","inpDtyp2","inpGrp","inpsub1","inpsub2"))
  if (!length(needed)) next
  pattern <- paste0("(",name," <- function\\([^{}]*\\)\\s*\\{)")
  guard <- paste0("shiny::req(",paste(sprintf("length(%s) > 0",needed),collapse=", "),")")
  fun_text <- sub(pattern,paste0("\\1\n  ",guard),fun_text,perl=TRUE)
}
fun_text <- gsub('h5data\\$read\\(args = list\\(([^,\n]+), quote\\(expr=\\)\\)\\)',
  'atlas_h5_read(h5data, \\1)',fun_text,perl=TRUE)
safe_read <- c('atlas_h5_read <- function(dataset, index) {',
  '  shiny::validate(shiny::need(length(index) > 0 && !anyNA(index), "Select an existing gene."))',
  '  dataset$read(args = list(index, quote(expr=)))', '}')
writeLines(c(safe_read,fun_text),fun_path)
dir.create(file.path(app_dir,"www"),showWarnings=FALSE)
file.copy(file.path(project_root,"config","custom.css"),file.path(app_dir,"www","custom.css"),overwrite=TRUE)
writeLines(c(".git/", "logs/", "*.log", "*.Rdata", "*.RData", "final_seurat.rds", ".DS_Store"),file.path(app_dir,".rscignore"))
