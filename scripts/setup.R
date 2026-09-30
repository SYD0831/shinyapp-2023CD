script <- normalizePath(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value=TRUE)[1]))
source(file.path(dirname(script), "common.R"))
lib <- file.path(project_root,".R-library")
dir.create(lib,showWarnings=FALSE)
.libPaths(c(lib,.libPaths()))
packages <- c("remotes","Seurat","SeuratObject","shiny","rsconnect","hdf5r",
  "shinyhelper","data.table","Matrix","DT","magrittr","ggplot2","ggrepel",
  "ggdendro","ggpubr","gridExtra","curl")
missing <- packages[!vapply(packages,requireNamespace,logical(1),quietly=TRUE)]
if(length(missing)) install.packages(missing,lib=lib)
if(!requireNamespace("ShinyCell2",quietly=TRUE)) remotes::install_github(
  "the-ouyang-lab/ShinyCell2@33bfc8ba232f0c829b6b23181cb83089d58e7879",
  lib=lib,upgrade="never",dependencies=NA)
