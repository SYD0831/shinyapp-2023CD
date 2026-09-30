# Single-cell Atlas

ShinyCell2 browser for 32,319 cells and 24,561 RNA genes. Uses the existing normalized RNA data and UMAP; no biological analysis is recomputed.

## Run locally

With the runtime dependencies installed:

```r
shiny::runApp("shinyApp")
```

To use this project's local R library:

```sh
Rscript scripts/setup.R
Rscript scripts/run_app.R
```

The app restores `sc1assay_RNA.h5` from ten binary parts on first startup, using 8 MiB byte buffers and checking the complete file's MD5. The matrix remains on disk and gene queries read HDF5 rows on demand. The original 2.53 GB Seurat object is not required or included in this repository.

## Deploy to Posit Connect Cloud

1. Sign in at <https://connect.posit.cloud/syd088>.
2. For this **private repository**, use a plan that supports private GitHub repositories (Basic or above). Free supports public repositories. A private repository does not automatically make the published application private.
3. Click **Publish**, then **Shiny** / **Shiny for R**.
4. Grant the Posit Connect Cloud GitHub App access to **SYD0831/shinyapp-2023CD** if prompted, then select that repository.
5. Select branch **main** and primary file **shinyApp/app.R**. `manifest.json` is in the same directory.
6. For initial testing, disable **Automatically publish on push**. Set the title to **Single-cell Atlas** and click **Publish**.
7. Watch the build logs, then test Cell Type coloring, CD34/LYZ gene search and all six subset fields. The first launch restores the HDF5 automatically; no data upload, secret variable, or runtime package installation is needed.

If the repository does not appear, check the GitHub App's selected repository permissions. If a dependency fails, inspect the first package installation error in the build log. Cloud Linux execution has not yet been tested; successful local tests and manifest generation do not guarantee a cloud build.

Official documentation: [GitHub deployment](https://docs.posit.co/connect-cloud/user/publish/github.html), [R manifest](https://docs.posit.co/connect-cloud/how-to/r/dependencies.html), [plans](https://connect.posit.cloud/plans).

## Metadata and colors

| Input column | Display label |
|---|---|
| scArche_anno | Cell Type |
| sample | Sample |
| sample_type | Disease Status |
| tissue | Tissue |
| lsc_type | Patient LSC Type |
| lsc_class | Cell LSC Class |

Disease Status displays `Dx` as `Newly diagnosed`, `Rl` as `Relapsed`, and keeps `A` unchanged. Tissue keeps `P` and `B`. Patient LSC Type refers to the classification at sampling and can differ between samples from the same patient. Cell Type has the explicitly supplied 15-color palette and order in `config/atlas.R`.

“Toggle to subset cells” is available on all plot tabs, initially expanded, with Sample selected. All six metadata fields can be selected. UMAP displays unselected cells as a pale background, following ShinyCell2 behavior. An empty selection produces no plot.

The default expression gene is **MCL1**, configured in `config/atlas.R`.

## Rebuild

Keep the source `pei23_scarche_anno.Rdata` locally in the project root. It must contain a Seurat object named `seurat`.

```sh
Rscript scripts/generate_app.R
Rscript scripts/validate_runtime.R
Rscript scripts/validate_portable.R
Rscript scripts/check_bundle.R
```

`generate_app.R` also recreates the expression parts and manifest. For code/config-only presentation changes, run `Rscript scripts/configure_app.R`, then `Rscript scripts/prepare_github.R` to refresh the deployment manifest. Do not edit generated files as the only copy of a customization.

`scripts/deploy_shinyapps.R` remains available for shinyapps.io after configuring credentials separately. It deploys only the allowlisted runtime files.

## Provenance and validation

Generated with ShinyCell2 1.0.0, commit `33bfc8ba232f0c829b6b23181cb83089d58e7879`, on R 4.4.2. Generation uses Seurat 5.3.0 / SeuratObject 5.1.0. The cloud runtime manifest has CRAN dependencies; Seurat, ShinyCell2 and Bioconductor packages are not needed at runtime.

See `reports/VALIDATION.md` and the machine-readable checks in `reports/`. The LungMAP reference was inspected in Chrome. The UI preserves ShinyCell-style navigation, compact controls and side-by-side plots without LungMAP branding. A cloud deployment has not been performed.

Generated application code derives from [ShinyCell2](https://github.com/the-ouyang-lab/ShinyCell2) (GPL-3). See `COPYING` and `THIRD_PARTY_NOTICES.md`. No new license is assigned to the biological data by this repository.
