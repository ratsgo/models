library(stringr)
library(tm)
library(topicmodels)

setwd('C:/NEWS/score')
file <- dir()[grep(dir(), pattern = '.csv')]
date <- str_split(file, "_")

result <- matrix(NA, ncol=13)
colnames(result) <- c('date1','title','title.pos','content','content.pos',
                      'date2','section','company','url','degree','eigen','result','topic')

event.keyword <- matrix(NA, ncol=22)

i <- 1
for (i in 1:length(file)) {
  cat(file[i],"\n")
  
  data <- read.csv(file[i], fileEncoding = 'CP949')
  data <- data[,-1]
  record.num <- round(dim(data)[1]*0.03)
  data <- data[1:record.num,]
  data$content.pos <- as.character(data$content.pos)
  colnames(data) <- c('date1','title','title.pos','content','content.pos',
                      'date2','section','company','url','degree','eigen','result')
  
  
  # Term-Document Matrix ??????
  news.corpus <- Corpus(VectorSource(data$content.pos))
  DTM <- DocumentTermMatrix(news.corpus, control = list(minwordLength= 1))

  # Topic Modeling (LDA)
  NTopic <- 3
  control_LDA_Gibbs <- list(alpha = 0.01, estimate.beta=TRUE, verbose=0, prefix=tempfile(),
                            save = 0, keep=0, seed=as.integer(Sys.time()), nstart=1,
                            best = TRUE, delta=0.1, iter=2000, burnin=0, thin=2000)
  topic.model <- LDA(DTM, NTopic, method="Gibbs", control = control_LDA_Gibbs)
  topics <- as.matrix(topics(topic.model))
  result.tmp <- cbind(data,topics)
  colnames(result.tmp) <- c('date1','title','title.pos','content','content.pos',
                        'date2','section','company','url','degree','eigen','result','topic')
  result <- rbind(result,result.tmp)
  terms <- t(as.matrix(terms(topic.model,20)))
  terms <- cbind(date[[i]][1],row.names(terms),terms)
  row.names(terms) <- NULL
  event.keyword <- rbind(event.keyword,terms)
  
}

result <- result[-1,]
event.keyword <- event.keyword[-1,]
colnames(event.keyword) <- c('date','topic','Word1','Word2','Word3','Word4','Word5',
                             'Word6','Word7','Word8','Word9','Word10',
                             'Word11','Word12','Word13','Word14','Word15',
                             'Word16','Word17','Word18','Word19','Word20')
write.csv(result, "C:/NEWS/topic/topic_lda.csv", fileEncoding = 'CP949')
write.csv(event.keyword, "C:/NEWS/topic/keyword_lda.csv", fileEncoding = 'CP949')
