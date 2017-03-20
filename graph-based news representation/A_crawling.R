library(rvest)
library(httr)
library(stringr)

setwd('C:/NEWS')

# 주요 조간 신문 크롤링
# 농민신문, 스포츠조선 제외
company <- c("조선일보","중앙일보","동아일보","한겨레","경향신문","한국일보","국민일보","매일경제","한국경제")
oid <- as.character(c("023","025","020","028","032","469","005","009","015"))
today <- c(paste0('2015010',1:9), paste0('201501',10:31),
           paste0('2015020',1:9), paste0('201502',10:29),
           paste0('2015030',1:9), paste0('201503',10:31),
           paste0('2015040',1:9), paste0('201504',10:30),
           paste0('2015050',1:9), paste0('201505',10:31),
           paste0('2015060',1:9), paste0('201506',10:30),
           paste0('2015070',1:9), paste0('201507',10:31),
           paste0('2015080',1:9), paste0('201508',10:31),
           paste0('2015090',1:9), paste0('201509',10:30),
           paste0('2015100',1:9), paste0('201510',10:31),
           paste0('2015110',1:9), paste0('201511',10:30),
           paste0('2015120',1:9), paste0('201512',10:31))

for (l in 1:length(today)) {
  result <- matrix(0,ncol=6)
  
  for (j in 1:length(company)) {
    page_tmp <- GET(paste0("http://news.naver.com/main/list.nhn?mode=LPOD&mid=sec&oid=",oid[j],"&listType=paper&date=",today[l])) %>% read_html()
    sec <- html_nodes(page_tmp, "#main_content > div.list_body.newsflash_body > div.topbox_type6") %>% as.character()
    sec <- length(unlist(str_split(sec,'page='))) - 1
    
    if (sec > 0) {
      for (k in 1:sec) {
        page <- GET(paste0("http://news.naver.com/main/list.nhn?mode=LPOD&mid=sec&oid=",oid[j],"&listType=paper&date=",today[l],"&page=",k)) %>% read_html()
        link <- html_nodes(page, "ul.type13.firstlist > li > dl > dt > a") %>% html_attr('href') %>% unique()
        
        if (length(link) != 0) { 
          for (i in 1:length(link)) {
            cat(today[l],company[j],"section",k,"id",i,"\n")
            article <- GET(link[i]) %>% read_html()
            section <- html_nodes(article, "div.article_info > div.sponsor > span.paper") %>% html_text()
            
            if (length(section) == 0) {
              next
            }
            
            title <- html_nodes(article, "div.article_info > h3") %>% html_text()
            date <- html_nodes(article, "div.article_info > div.sponsor > span.t11")[1] %>% html_text()
            content <- html_nodes(article, "div#articleBodyContents") %>% html_text()
            content <- gsub('\r\n\t\r\n\t\r\n\t','', content)
            data <- cbind(title, content, date, section, company[j], link[i])
            result <- rbind(result, data)
          }
        }
      }
    }
  }
  
  # save
  if (dim(result)[1] > 2) {
    result <- result[-1,]
    colnames(result) <- c('title', 'content', 'date', 'section', 'company', 'url')
    write.csv(result,paste0('news/',today[l],'_news.csv'), fileEncoding = "CP949")
  }
}