script <- normalizePath(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value=TRUE)[1]))
source(file.path(dirname(script), "common.R"))
source(file.path(dirname(script), "deployment_files.R"))
files <- deployment_files(app_dir)
rsconnect::deployApp(appDir=app_dir, appFiles=files,
  appName="single-cell-atlas", server="shinyapps.io", launch.browser=FALSE)
