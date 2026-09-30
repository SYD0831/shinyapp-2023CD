# Portable entrypoint for GitHub / Posit Connect Cloud.
# Expression bytes are reconstructed on disk, never loaded as a complete matrix.
restore_expression <- function() {
  manifest <- read.dcf("expression.dcf")
  target <- manifest[1,"File"]
  expected_size <- as.numeric(manifest[1,"Size"])
  expected_md5 <- manifest[1,"MD5"]
  if(file.exists(target) && file.info(target)$size == expected_size &&
     unname(tools::md5sum(target)) == expected_md5) return(invisible(target))
  parts <- strsplit(manifest[1,"Parts"],",",fixed=TRUE)[[1]]
  if(!all(file.exists(parts))) stop("Expression data parts are missing. Redeploy the complete shinyApp directory.")
  partial <- tempfile("expression-",tmpdir=".",fileext=".h5.partial")
  out <- file(partial,"wb")
  on.exit({try(close(out),silent=TRUE); if(file.exists(partial)) unlink(partial)},add=TRUE)
  for(part in parts) {
    con <- file(part,"rb")
    tryCatch(repeat {
      block <- readBin(con,"raw",n=8L*1024L*1024L)
      if(!length(block)) break
      writeBin(block,out)
    },finally=close(con))
  }
  close(out)
  if(file.info(partial)$size != expected_size || unname(tools::md5sum(partial)) != expected_md5)
    stop("Expression data checksum failed. Redeploy the complete data parts.")
  if(!file.rename(partial,target)) stop("Could not restore expression data on disk.")
  invisible(target)
}
restore_expression()
app_environment <- new.env(parent=globalenv())
atlas_server <- source("server.R",local=app_environment)$value
atlas_ui <- source("ui.R",local=app_environment)$value
shiny::shinyApp(ui=atlas_ui,server=atlas_server)
