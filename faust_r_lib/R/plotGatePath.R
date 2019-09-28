#' Plot all the gates along a path.
#' @param gh GatingHierarchy
#' @param path a character string representing a node path
#' @param stop a string representing the ancestor node where the plot stops.All the gates prior to that node (and include that node) will be skipped.
#'              Default is "root", which means trace all the way back to the first node in the path
#' @param ... arguments passed to ggcyto::autoplot
#' @description Plots the gates along a path from the first node in the path to the terminal node. 
#' This is like ploting the gating scheme for a specific population. The \code{stop} argument is a node or path that specifies where to  stop plotting upstream. For example, if the path is "A/B/C", and stop is "A", then gates "B" and "C" will be plotted.
#' It is recommended to pass \code{bins=256} to the plotting routine to get sufficient resolution. 
#' @examples 
#' \dontrun{
#' dataDir <- system.file("extdata",package="flowWorkspaceData")
#' library(flowWorkspace)
#' gs <- load_gs(list.files(dataDir, pattern = "gs_manual",full = TRUE))
#' library(ggcyto)
#' autoplot(gs[[1]], "singlets/CD3+/CD4") #plot only the leaf gate
#' #plot all the three gates in the gating path
#' plotGatePath(gs[[1]], "singlets/CD3+/CD4", strip.text = "gate")
#' plotGatePath(gs[[1]], "singlets/CD3+/CD4/CCR7- 45RA-", stop = "CD3+")#exclude the first two gates
#' plotGatePath(gs[[1]], "/not debris/singlets", strip.text = "gate")
#' }
#' @export
#' @importFrom ggcyto autoplot
#' @importFrom flowWorkspace gh_pop_get_full_path
plotGatePath <- function(gh, path, stop = "root", ...){
  if(stop!="root")
    stop <- gh_pop_get_full_path(gh, stop)
  nodes <- vector(length = 0)
  node <- gh_pop_get_full_path(gh, path)
  while(node != stop)
  {
    nodes <- c(node, nodes)#push to the nodes queue
    path <- dirname(path)#pop from the path string
    #check the end of path
    if(path %in% c(".", "/"))
      break 
    #update the node
    node <- gh_pop_get_full_path(gh, path)  
  }
  autoplot(gh, nodes, ...)
}
