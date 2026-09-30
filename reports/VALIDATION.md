# Validation report — 2026-09-30

## Input Seurat

- Local input: `pei23_scarche_anno.Rdata`, object `seurat`.
- Size: 2,527,041,494 bytes (2.53 GB / 2.35 GiB).
- Cells: 32,319. RNA genes: 24,561. Assays: RNA and ADT (22 features).
- Object Seurat version: 4.1.0. Generation environment: R 4.4.2, Seurat 5.3.0, SeuratObject 5.1.0.
- Default assay: RNA. RNA layers: counts, data. ADT layers: counts, data, scale.data.
- Reductions: umap, totalvi_lngb. Exported reduction: umap only.
- Normalized RNA `data` and a recorded NormalizeData.RNA command were found. No analysis was rerun.

## Generated app

- Runtime directory: `shinyApp/`.
- ShinyCell2: 1.0.0, GitHub commit `33bfc8ba232f0c829b6b23181cb83089d58e7879`.
- HDF5 size: 467,335,341 bytes. Stored as ten parts in GitHub: nine 45 MiB parts and one smaller part.
- Runtime payload (before manifest): 468,284,185 bytes.
- Actual compressed rsconnect deployment bundle: 466,754,966 bytes.
- The local directory also contains the restored HDF5, so its physical size is larger than the uploaded payload. The restored HDF5 is ignored by Git and excluded from deployment bundles.
- Largest uploaded files: `expression-parts/rna-001.bin` through `rna-009.bin`, 47,185,920 bytes each. Full list: `runtime-file-sizes.csv`.
- Git and deployment exclude the original Seurat, local R package library, logs, large test plots and test archives.

## UI

- LungMAP reference inspected: YES, through Chrome, including side-by-side UMAP/expression layout and subset controls.
- Reference-style organization implemented: YES, within the ShinyCell2 native architecture. It is not a pixel-exact replica.
- Custom CSS: YES, generated from `config/custom.css` into `shinyApp/www/custom.css`.
- Default tab: Side-by-side DimRed. Cell Type uses the user-specified 15 colors and factor order.
- Default expression gene: MCL1. Local full-cell expression, UMAP construction and legend extraction passed after this change. The cloud screenshot's generic plotting error remains unconfirmed without runtime logs.
- Subset controls: initially expanded; default Sample; all six approved fields are available.
- Disease Status: Dx → Newly diagnosed, Rl → Relapsed, A unchanged. Tissue remains P/B.
- Browser rendering and interactions were observed in Chrome and Safari. The user also confirmed the local application looked correct. A dedicated narrow/mobile viewport test was not completed.

## Validation

| Check | Result | Evidence |
|---|---|---|
| Local startup | PASS | Browser-rendered app; fresh HTTP startup during isolation test |
| UMAP | PASS | Coordinates match input; browser rendering and reactive tests |
| Metadata coloring and subsets | PASS | All six fields tested; one sample selects 1,197 cells |
| Gene lookup / expression | PASS | Browser gene selectors/rendering; CD34, LYZ, MPO runtime queries |
| Data export fidelity | PASS | All cell IDs, metadata and UMAP matched; 110 genes × all cells checked |
| Independent of original Seurat RDS/Rdata | PASS | Original temporarily renamed; fresh processes started and queried; original restored |
| Portable GitHub split-data startup | PASS | Loaded app from an isolated runtime-only copy without any existing HDF5; complete MD5 and CD34 verified |

RNA HDF5 uses ShinyCell2 float32 storage. Maximum absolute error in sampled expression values: 2.384093e-07, within the tested relative tolerance of 1e-6.

Original restored MD5: `2e5289d7cfa8de9956ee3a20e8d0a29d`.
Restored HDF5 MD5: `15d92edcd06f64dce4425255dedc0482`.

## Memory and dependencies

Latest local runtime test with MCL1 as the default: startup RSS 242.9 MiB; before gene queries 460.8 MiB; sampled peak after rendering/query tests 523.1 MiB. The separate independence test peaked at approximately 528 MiB. These are local macOS process measurements, not continuous peak monitoring or a cloud capacity guarantee. They exclude the separate 2.53 GB generation input.

Gene expression is read on demand from HDF5. No complete expression matrix is loaded at startup. Reconstructing the split file uses 8 MiB byte buffers. Multi-gene plots read selected genes (up to 50) and may use more memory than single-gene queries.

The runtime manifest records 109 CRAN dependencies. Runtime does not require Seurat, SeuratObject, ShinyCell2, Bioconductor packages, or GitHub-installed R packages. Dependencies are installed by the hosting platform during build, not by the running app.

Small generated UI/input compatibility fixes are reproduced by `scripts/customize_app.R`. Remaining non-fatal local warnings include ggplot2's deprecated `element_line(size=...)` argument and ggrepel omitting overlapping text labels; cells are still plotted.

## Deployment status

- Posit Connect Cloud repository preparation: READY. Select `main` and `shinyApp/app.R`; `manifest.json` is alongside it.
- Private GitHub repository requires a Connect Cloud plan supporting private repositories. Published-content privacy is a separate plan setting.
- Actual cloud deployment/build: NOT RUN. Authentication and publishing remain for the user. Linux dependency installation and cloud performance have not yet been verified.
- shinyapps.io preparation: READY for authentication and a deployment attempt; use `Rscript scripts/deploy_shinyapps.R`. Expected URL template: `https://<account>.shinyapps.io/single-cell-atlas/`.
- No hosting secrets are included in code or the manifest.

See the repository README for the Connect Cloud publishing steps. Official references: [publishing from GitHub](https://docs.posit.co/connect-cloud/user/publish/github.html), [bundle size limits](https://docs.posit.co/connect-cloud/user/publish/index.html), [plan comparison](https://connect.posit.cloud/plans).
