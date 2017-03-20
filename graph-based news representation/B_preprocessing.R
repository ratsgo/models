library(KoNLPQ)

twi.extractPOS <- function(strings){
  err <- NULL
  tryCatch({res = .jrcall(get("twitterObj",envir=KoNLPQ:::.KoNLPQEnv), 'tokenize', strings)}, 
           error = function(e) err <<- conditionMessage(e))
  res = .jstrVal(res)
  return(res)
}

setwd('C:/NEWS/news')
file <- dir()[grep(dir(), pattern = '.csv')]
date <- str_split(file, "_")

for (m in 1:length(file)) {
  data <- read.csv(paste0('C:/NEWS/news/',date[[m]][1],'_news.csv'))
  title <- as.character(data$title)
  content <- as.character(data$content)
  pos <- matrix(NA,ncol=2,nrow=length(title))
  tmp <- NULL
  
  for (i in 1:length(title)) {
    cat("date:",date[[m]][1],"title",i,"\n")
    if (title[i] == "") { next }
    pos.data <- str_replace_all(title[i], "\\[(.*?)\\]", "") %>% str_replace_all("  ", " ") %>% str_trim
    if (pos.data == "") { next }
    pos.data <- try(twi.extractPOS(pos.data))
    if (str_detect(pos.data, "res") == TRUE || length(pos.data) == 0) { next }
    pos.data <- pos.data %>% gsub('\\[||\\]', '', .) %>% strsplit('),') %>% unlist
    pos.hangul <- pos.data %>% strsplit('\\(') %>% lapply('[', 1) %>% gsub(' ', '', .) %>% unlist
    pos.tag <- pos.data %>% strsplit('\\(') %>% lapply('[', 2) %>% unlist %>% strsplit(':') %>% lapply('[', 1) %>% unlist
    delete.location <- which(pos.tag=="Josa" | pos.tag=="Punctuation" | pos.tag=="Suffix" | pos.tag=="Determiner" 
                             | pos.tag == "Conjunction" | pos.tag=="Number" | pos.hangul == "??" | pos.hangul == "??"
                             | pos.hangul == "??" | pos.hangul == "??" | pos.hangul == "??"  | pos.hangul == "??"
                             | pos.hangul == "??" | pos.hangul == "??" | pos.hangul == "??" | pos.hangul == "?ϴ?"
                             | pos.hangul == "??")
    if (length(delete.location) == 0) {
      pos[i,1] <- paste0(pos.hangul, 'ZQQ', pos.tag) %>% paste(., collapse = " ")
    } else {
      pos[i,1] <- paste0(pos.hangul, 'ZQQ', pos.tag)[-delete.location] %>% paste(., collapse = " ")
    }
  }
  
  for (p in 1:length(content)) {
    cat("date:",date[[m]][1],"content",p,"\n")
    if (content[p] == "") { next }
    pos.data <- try(twi.extractPOS(content[p])) %>% gsub('\\[||\\]', '', .)
    pos.data <- pos.data %>% strsplit('),') %>% unlist
    pos.hangul <- pos.data %>% strsplit('\\(') %>% lapply('[', 1) %>% gsub(' ', '', .) %>% unlist
    pos.tag <- pos.data %>% strsplit('\\(') %>% lapply('[', 2) %>% unlist %>% strsplit(':') %>% lapply('[', 1) %>% unlist
    delete.location <- which(pos.tag=="Josa" | pos.tag=="Punctuation" | pos.tag=="Suffix" | pos.tag=="Foreign" 
                             | pos.tag=="Number" | pos.tag == "Email" | is.na(pos.tag) == T | pos.hangul == "?ϴ?"
                             | pos.hangul == "?ϴ?" | pos.hangul == "?ִ?" | pos.hangul == "?Ǵ?" | pos.hangul == "??"
                             | pos.hangul == "?ʴ?" | pos.hangul == "?ƴϴ?" | pos.hangul == "????" | pos.hangul == "??"
                             | pos.hangul == "??" | pos.hangul == "??" | pos.hangul == "??" | pos.hangul == "??"
                             | pos.hangul == "??" | pos.hangul == "????" | pos.hangul == "??" | pos.hangul == "?Ŵ?"
                             | pos.hangul == "??" | pos.hangul == "??" | pos.hangul == "??" | pos.hangul == "?̴?"
                             | pos.hangul == "??" | pos.hangul == "??" | pos.hangul == "??" | pos.hangul == "????"
                             | pos.hangul == "????" | pos.hangul == "????*" | pos.hangul == "????" | pos.hangul == "??"
                             | pos.tag == "URL")
    if (length(delete.location) == 0) {
      pos[p,2] <- paste0(pos.hangul, 'ZQQ', pos.tag) %>% paste(., collapse = " ")
    } else {
      pos[p,2] <- paste0(pos.hangul, 'ZQQ', pos.tag)[-delete.location] %>% paste(., collapse = " ")
    }
    
  }
  
  # ????
  pos <- cbind(date[[m]][1],title,pos[,1],content,pos[,2],as.character(data$date),as.character(data$section),as.character(data$company),as.character(data$url))
  colnames(pos) <- c('date1','title','title.pos','content','content.pos','date2','section','company','url')
  write.csv(pos, paste0('C:/NEWS/pos/',date[[m]][1],'_pos.csv'))
}