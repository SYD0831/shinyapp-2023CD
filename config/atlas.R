metadata_labels <- c(scArche_anno = "Cell Type", sample = "Sample",
  sample_type = "Disease Status", tissue = "Tissue",
  lsc_type = "Patient LSC Type", lsc_class = "Cell LSC Class")
disease_labels <- c(A = "A", Dx = "Newly diagnosed", Rl = "Relapsed")
atlas_title <- "Single-cell Atlas"
default_gene <- "MCL1"
cell_type_colours <- c(
  "LSPC-Quiescent"="#e41a1c", "LSPC-Primed"="#3e8c3b", "LSPC-Cycle"="#ff7f00",
  "GMP-like"="#377eb8", "ProMono-like"="#f781bf", "Mono-like"="#984ea3",
  "cDC-like"="#a65628", "MEP"="#aac9e7", "pre/pro-B"="#f6f7a1",
  "B"="#dbc902", "Plasma"="#ffe4ca", "CD4 T"="#8ad587",
  "CD8 T"="#b2df8a", "NK"="#87a86a", "unknown"="gray")
atlas_note <- paste("Patient LSC Type describes the classification at the time of sampling",
  "and may differ between samples from the same patient.",
  "Disease Status: A is retained as supplied; its meaning has not been specified.")
