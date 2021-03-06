### Input fields
from.field <- "From field"

to.field <- "To field"

# this is optional and can also be NULL
weight.field <- "Weight field"

### Parameters

# number of output dimensions in the data
output.dimensions <- 4

# an initial step in tsne is a dimensionality reduction via PCA. This variable specifies to how many initial dimensions the network should be reduced
initial.dimensions <- 25

# specifies more or less how many neighbour points each data point sees. The lower the more local relationships are accentuated
perplexity <- 15

### Script


library(data.table)
library(Rtsne)

# sanity checks
if (!exists("input.data")) stop("No input data")

has.weight = !is.null(weight.field)

# extract network
if (has.weight) {
  connection.data <- data.table(from=input.data[, from.field], to=input.data[, to.field], weight=input.data[, attribute.field])
} else {
  connection.data <- data.table(from=input.data[, from.field], to=input.data[, to.field], weight=1)
}

# assign a consecutive index to each node
nodes.from <- connection.data[,.N,by=from]
setnames(nodes.from, c("node","n"))
nodes.to <- connection.data[,.N,by=to]
setnames(nodes.to, c("node", "n"))
nodes <- rbind(nodes.from, nodes.to)
nodes <- nodes[,.(n=sum(n)), by=node]
nodes[, n:=NULL]
nodes$i <- 1:nrow(nodes)

# use the consecutive indexes to refer to nodes in the network
links <- merge(connection.data, nodes, by.x = "from", by.y="node")
links <- merge(links, nodes, by.x = "to", by.y="node")

# create adjacency matrix
indexes <- links[, .(i.x, i.y, weight)]
edges <- as.matrix(indexes[, 1:2])
adjacency.matrix <- matrix(0, nrow(nodes), nrow(nodes))
adjacency.matrix[edges]<- indexes$weight

# perform tsne
tsne <- Rtsne(adjacency.matrix, dims = output.dimensions, initial_dims = initial.dimensions, perplexity = perplexity, check_duplicates = FALSE,  max_iter = 10000)

ts# extract x,y coordinates
y <- as.data.table(tsne$Y)
y$i <- 1:nrow(y)
output.data <- merge(nodes, y, by.x="i", by.y="i")
output.data[,i:=NULL]
