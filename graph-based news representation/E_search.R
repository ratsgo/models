library(stringr)

word <- read.csv('C:/NEWS/topic/keyword_lda.csv', fileEncoding = 'CP949')
word <- word[,-1] %>% t() %>% gsub('zqq', 'ZQQ', .) %>% gsub('noun', 'Noun', .)

news <- read.csv('C:/NEWS/topic/topic_lda.csv', fileEncoding = 'CP949')
news <- news[,-1]
news.contents <- as.character(news$content.pos)

keyword <- c('??????ZQQNoun')
result <- matrix(NA, ncol=13)
colnames(result) <- colnames(news)

date <- word[1,ceiling(which(word == keyword) / dim(word)[1])]
topic <- word[2,ceiling(which(word == keyword) / dim(word)[1])]
topic <- gsub('Topic ', '', topic) %>% as.numeric()
location <- NULL

for (i in 1:length(date)) {
  location <- which(news$date1 == date[i])
  location <- location[which(news$topic[location] == topic[i])]
  if (length(location) == 0) { next }
  
  for (j in 1:length(location)) {
    contents <- str_split(news.contents[location[j]], " ") %>% unlist
    sign <- length(which(is.na(match(contents,keyword)) == F))
    if (sign > 0) { 
      location <- location[j]
      result <- rbind(result,news[location,])
      break
    }
  }
}

result <- result[-1,]
write.csv(result, paste0('C:/NEWS/result/',keyword,'_lda.csv'))
