script <- normalizePath(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value=TRUE)[1]))
source(file.path(dirname(script), "common.R"))
source(file.path(project_root, "config", "atlas.R"))
source(file.path(project_root, "scripts", "customize_app.R"))
