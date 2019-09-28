

#' Make a Gated Gating Set From a FAUST Result
#'
#' @param gatingSet \code{GatingSet} object.
#' @param faustProjectDirectory  \code{character} path to a FAUST project directory containing FAUST results.
#' @description For each cell population discovered by FAUST, we gate the cell population according to the
#' FAUST marker order and add it to the GatingSet.
#' @return \code{NULL}
#' @export
#'
#' @examples
#' \dontrun{
#' library(flowWorkspace)
#' library(ggcyto)
#' library(dplyr)
#' library(tidyr)
#' gs <- load_gs("/Users/gfinak/phenogs")
#' makeGatingSetFromFAUST(faustProjectDirectory =
#' "/shared/silo_researcher/gottardo_r/gfinak_working/CITN07/FAUST_pheno_full_remapped_persample_consistentPars",
#' gatingSet = gs[1:2])
#'  recompute(gs[1:2])
#' stats <- getPopStats(gs[1:2], path = "full")
#' }

makeGatingSetFromFAUST <-
  function(gatingSet = NULL,
           faustProjectDirectory = NULL) {
    if (is.null(gatingSet)) {
      stop("gatingSet argument must not be NULL.")
    }
    if (is.null(faustProjectDirectory)) {
      stop("faustProjectDirectory must point to a FAUST project directory.")
    }
    
    faustProjectDirectory <- normalizePath(faustProjectDirectory)
    
    metadata_path <-
      normalizePath(file.path(faustProjectDirectory, "faustData/metaData"))
    
    startingNode <-
      normalizePath(file.path(metadata_path, "startingCellPop.rds"))
    startingNode <- readRDS(startingNode)
    
    name_summary <-
      normalizePath(file.path(metadata_path, "scampNameSummary.rds"))
    name_summary <- readRDS(name_summary)
    
    cname_map <-
      normalizePath(file.path(metadata_path, "colNameMap.rds"))
    cname_map <- readRDS(cname_map)
    
    gate_path <-
      normalizePath(file.path(faustProjectDirectory, "faustData/gateData"))
    reslist <-
      file.path(gate_path,
                list.files(path = gate_path, pattern = "resList.rds"))
    reslist <- readRDS(reslist)
    # to_drop <- getNodes(gatingSet)
    # #figure out which node to drop.
    # 
    # message("Cleaning up gating set")
    #   for (j in to_drop[[1]]) {
    #     Rm(j, gatingSet)
    #   }

    # For each cell population in cname_map
    samples <- sampleNames(gatingSet)
    markermap <- list()
    for (p in 1:nrow(cname_map)) {
      population <- cname_map[p,"faustColNames"]
      phenotype <- cname_map[p,"newColNames"]
      if (phenotype == "0_0_0_0_0") {
        next;
      }
      message("population ",phenotype)
      markers <- stringr::str_split(pattern = "~",population)[[1]]
      markers <- markers[-length(markers)]
      markers <- matrix(markers, ncol = 3, byrow = TRUE)
      colnames(markers) <- c("name","phenotype","nphenotypes")
      markers <- as.data.frame(markers)
      markers$phenotype <- as.numeric(markers$phenotype)
      markers$nphenotypes <- as.numeric(markers$nphenotypes)
      markers$name <- as.character(markers$name)
      markers$channel <- NA
      for (m in 1:nrow(markers)) {
        if (is.null(markermap[[markers[m,"name"]]])) {
          markermap[[markers[m,"name"]]] <- getChannelMarker(getData(gatingSet[[1]],use.exprs = FALSE), name = markers[m,"name"])$name
          markers$channel[m] <- markermap[[markers[m,"name"]]]
        } else {
          markers$channel[m] <- markermap[[markers[m,"name"]]]
        }
      }
      # For each sample
      for (s in samples) { 
        # message("sample ",s)
        for (m in 1:nrow(markers)) {
          if (m == 1) {
            parent = startingNode
          } else {
            parent <- paste0(parent,"/",lastpopname)
          }
          if (markers[m,"phenotype"] == 1) {
            upper <- as.numeric(reslist[[markers[m,"name"]]][[s]][markers[m,"phenotype"]])
            lower <- -Inf
            thispheno <- "-"
          } else if (markers[m,"phenotype"]  == (markers[m,"nphenotypes"] + 1)) {
            upper <- Inf
            lower <- as.numeric(reslist[[markers[m,"name"]]][[s]][markers[m,"phenotype"] - 1])
            thispheno <- "+"
          } else {
            lower <- as.numeric(reslist[[markers[m,"name"]]][[s]][markers[m,"phenotype"] - 1])
            upper <- as.numeric(reslist[[markers[m,"name"]]][[s]][markers[m,"phenotype"]])
            thispheno <- "dim"
          }
          markername <- markers[m,"name"]
          popname <- paste0(markername,thispheno)
          gate <- matrix(c(lower,upper),ncol = 1)
          channelname <- markers[m,"channel"]
          colnames(gate) <- channelname
          gate <- flowCore::rectangleGate(filterId = popname, .gate = gate)
          tryCatch(expr = {
            add(gatingSet[[s]], gate, parent = parent)
            # message("adding ", popname)
          },error = function(e){
            # message(popname, " exists")
          })
          lastpopname <- popname
        }
      }
    }
  }


                                                       