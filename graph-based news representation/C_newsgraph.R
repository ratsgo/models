library(igraph)
library(stringr)
library(tm)

setwd('C:/NEWS/pos')
file <- dir()[grep(dir(), pattern = '.csv')]
date <- str_split(file, "_")

for (m in 1:length(file)) {
  cat(file[m],"\n")
  data <- read.csv(paste0('C:/NEWS/pos/',date[[m]][1],'_pos.csv'))
  data <- unique(data[,-1])
  row.names(data) <- NULL
  data$title.pos <- as.character(data$title.pos) 
  #%>% str_replace_all(., "\\S+?ZQQForeign", "") %>% str_replace_all("  ", " ") %>% str_trim
  
  for (n in 1:length(data$title.pos)) {
    data$title.pos[n] <- data$title.pos[n] %>% str_split(., " ") %>% unlist() %>% unique() %>% paste(., collapse = " ")
  }
  
  corpus <- Corpus(VectorSource(data$title.pos))
  TDM <- TermDocumentMatrix(corpus)
  TDM <- as.matrix(TDM)
  net.tmp <- matrix(NA,ncol=2)

  for (i in 1:nrow(TDM)) {
    doc.location <- which(TDM[i,] > 0)
    if (length(doc.location) < 2) { next }
    edge <- t(combn(doc.location,2))
    net.tmp <- rbind(net.tmp,edge)
  }
  
  net.tmp <- net.tmp[-1,]
  if (length(net.tmp) < 3) { next }
  title.net <- cbind(unique(net.tmp[,]),1)
  id <- unique(net.tmp[,1])

  for (j in 1:length(id)) {
    weight <- table(net.tmp[net.tmp[,1] == id[j],2])
    weight <- weight[weight > 1]
    if (length(weight) == 0) { next }
    k <- 1
    for (k in 1:length(weight)) {
      location <- which(title.net[,1] == id[j] & title.net[,2] == names(weight)[k])
      title.net[location,3] <- weight[k]
    }
  }
  
  title.net <- title.net[which(data$company[title.net[,1]] != data$company[title.net[,2]]),]
  
  # ?׷??? ?׸??? (weight=??ġ?? ?ܾ? ????)
  if (dim(title.net)[1] < 3) { next }
  news.graph <- graph.edgelist(title.net[,1:2], directed = F)
  E(news.graph)$weight <- title.net[,3]
  news.graph <- add_vertices(news.graph, nv=(dim(data)[1]-length(V(news.graph))))
  table <- data.frame(data,graph.strength(news.graph),
                      evcent(news.graph, scale=F)$vector,
                      graph.strength(news.graph)*evcent(news.graph, scale=F)$vector)
  ord <- order(table[,12],decreasing=TRUE)
  table <- table[ord,]
  colnames(table) <- c('date1','title','title.pos','content','content.pos','date2','section','company','url','degree','eigen','result')
  
  # ????
  title.net <- data.frame(title.net,"Undirected")
  colnames(title.net) <- c('source','target','weight','type')
  write.csv(title.net, paste0('C:/NEWS/graph/',date[[m]][1],'_graph.csv'))
  write.csv(table, paste0('C:/NEWS/score/',date[[m]][1],'_score.csv'))
}