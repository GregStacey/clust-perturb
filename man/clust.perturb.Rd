% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/clust-perturb.R
\name{clust.perturb}
\alias{clust.perturb}
\title{Perturb clusters}
\usage{
clust.perturb(
  network,
  clustering.algorithm,
  noise = 0.1,
  iters = 3,
  edge.list.format = NULL,
  cluster.format = NULL,
  ...
)
}
\arguments{
\item{network}{data frame with two columns. Each row is an edge between two nodes.}

\item{clustering.algorithm}{a character string specifying one of four clustering
algorithms ("mcl", "walktrap", "hierarchical", "k-med"), or a function responsible for
clustering}

\item{noise}{scalar with value between 0 and 1. Specifyies the amount of noise to 
add to the network. 0 specifies no noise, and 1 specifies total rewiring. Typical values
are between 0.1 and 0.5.}

\item{iters}{positive integer specifying number of iterations. Typical values are between
3 and 100, with 5-10 iterations often sufficient for estimation.}

\item{edge.list.format}{NULL or a function that transforms network into format required
by clustering.algorithm. If a function, must take exactly one argument.}

\item{cluster.format}{NULL or a function that transforms output returned by 
clustering.algorithm into a character vector, where each element is a cluster whose 
format is semicolon-separated nodes. If a function, must take exactly two arguments. The
second argument must be a sorted character vector of unique nodes in the original network.}

\item{...}{arguments passed to clustering algorithm.}
}
\value{
data frame containing clusters and their repJ scores, fnode scores for each node
in each cluster, and the best-matching clusters in each noise iteration.
}
\description{
Test cluster robustness through random network rewiring
}
\details{
clust.perturb is a general-purprose wrapper for any clustering algorithm. Four default
clustering functions are included (MCL, walktrap, hierarchical, and k-medoids) with the
option of passing any clustering function. clust.perturb takes input networks as 
an unweighted edge list formatted as a 2 column dataframe. Because clustering functions can have
different input and output formats, in order to handle arbitrary clustering functions,
clust.perturb also takes two conversion functions. 
The first, edge.list.format converts the network edge list into the format required by the 
clustering algorithm, for example a dist object as required by MCL. The second, cluster.format, 
converts the output of the clustering algorithm into a common format, namely a character vector, each
element of which is a cluster with semicolon-separated nodes (e.g. c("A;B", "C;D;E"))

clust.perturb returns two metrics for each cluster. repJ measures a cluster's
reproducibility, and calculated as the average maximum Jaccard index over noise iterations.
fnode, which is calculated for each node in a cluster, counts the frequency with which that 
node is reclustered in the closest-match cluster in each noise iteration, divided by the
number of iterations.
}
\examples{
library(igraph)

# walktrap clustering algorithm with random network
# make random network
network = data.frame(x = sample(1:100, 1000, replace=TRUE), 
  y = sample(1:100, 1000, replace=TRUE))
# cluster and measure robustness
clusts = clust.perturb(network, clustering.algorithm="walktrap")


# test robustness at low, medium, and high noise levels
# demonstrates that an appropriate noise level is one that gives the best resolution of repJ
# read network
# cluster and measure robustness
clusts1 = clust.perturb(network, clustering.algorithm="hierarchical", 
  noise=0.001) # low noise
clusts2 = clust.perturb(network, clustering.algorithm="hierarchical", 
  noise=0.15) # medium noise
clusts3 = clust.perturb(network, clustering.algorithm="hierarchical", 
  noise=0.75) # high noise
# plot
plot(sort(clusts1$repJ)) 
lines(sort(clusts2$repJ))
lines(sort(clusts3$repJ))


# passing clustering arguments to default algorithms
clusts = clust.perturb(network, clustering.algorithm="mcl", inflation = 4,
  expansion = 3.5)
clusts = clust.perturb(network, clustering.algorithm="hierarchical", k = 2)
clusts = clust.perturb(network, clustering.algorithm="walktrap", steps = 10)
clusts = clust.perturb(network, clustering.algorithm="k-med", k = 10)

# clustering algorithm with custom conversion functions

# use clustering algorithm MCL, explicitly show conversion functions
library(MCL)
clustalg = function(x) mcl(x, addLoops = FALSE)

# edge.list.format converts dataframe edge.list to adjacency matrix, as required by MCL
edgelist.func = function(ints.corum) {
  G = graph.data.frame(ints.corum,directed=FALSE)
  A = as_adjacency_matrix(G,type="both",names=TRUE,sparse=FALSE)
}

# cluster.format converts converts MCL output to character vector of semicolon-separated nodes
# cluster.format requires a second argument, unqnodes, which is the sorted vector of unique 
# nodes in the network, i.e. unqnodes = unique(c(network[,1], network[,2]))
clust.func = function(tmp, unqnodes) {
  tmp = tmp$Cluster
  clusts = character()
  unqclusts = unique(tmp)
  for (ii in 1:length(unqclusts)) {
    I = tmp == unqclusts[ii]
    if (sum(I)<3) next
    clusts[ii] = paste(unqnodes[I], collapse = ";")
  }
  clusts = clusts[!clusts==""]
  clusts = clusts[!is.na(clusts)]
  return(clusts)
}
# cluster and measure robustness
clusts = clust.perturb(network, clustering.algorithm=clustalg, 
  edge.list.format=edgelist.func, cluster.format=clust.func)
}
