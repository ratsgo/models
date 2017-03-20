library(rpart)
library(Matrix)
library(stringr)

####################################
# function                         #
####################################
regression.perf_eval <- function(real,hat) {
  MSE <- mean((real - hat)^2)
  RMSE <- sqrt(MSE)
  MAE <- mean(abs(real - hat))
  MAPE <- mean(abs((real - hat)/real)) * 100
  result <- c(MSE,RMSE,MAE,MAPE)
  return(result)
}
classification.perf_eval <- function(real,hat) {
  tmp <- union(as.numeric(unique(real)), as.numeric(unique(hat)))
  tmp <- factor(tmp[order(tmp,decreasing = F)])
  cm <- table(factor(as.integer(factor(real)),tmp),factor(hat,tmp))
  ACC <- sum(diag(cm)) / sum(cm)
}
rotationForest <- function(data,k=3,numTrees=30,bootstrapRate=0.75,type="class"){
  
  ####################################
  # function 1                       #
  # split feature set into k subsets #
  ####################################
  getRandomSubset <- function(x, y, k){
    #check that k is proper
    if(k > length(x)) {
      k <- length(x)
    }
    
    numSubset <- round(length(x)/k)
    subsetList <- list()
    
    #check that number of subsets 
    if(numSubset > length(x)){
      numSubset <- length(x)
    }
    
    #give features names for indentifing the original sequence of features
    colnames(x) <- paste0("X", 1:length(x))
    
    #shuffling features randomly
    x <- subset(x, select = sample(1:length(x))) 
    
    #pick out k-1 subsets
    i <- 1
    while(i < k){
      if (is.null(dim(x)) == TRUE) {
        subsetList[[i]] <- as.matrix(data.frame(x, y))
      } else {
        subsetList[[i]] <- cbind(x[ , 1:numSubset], y)
        x <- x[ , -(1:numSubset)]
      }
      i <- i+1
    }
    subsetList[[k]] <- cbind(x, y)

    #pick out the last subset (kth subset)
    # The last kth subset may include more or less records than the other subsets 
    # when the number of subets is not an integer
    return(subsetList)
  }
  
  ####################################
  # function 2                       #
  # bootstrapping                    #
  ####################################
  bootstrap <- function(subsetList, bootstrapRate){
    bootIdxList <- list()
    bootSubsetList <- list()
    
    for(i in 1:length(subsetList)){#for-loop begins
      #bootstrap sampling
      numRecord <- nrow(data.frame(subsetList[[i]]))
      bootIdxList[[i]] <- sample(1:numRecord, round(bootstrapRate*numRecord), replace = TRUE)
      
      #save a bootstrapped subset in the 'bootSubsetList'
      bootSubsetList[[i]] <- data.frame(subsetList[[i]][bootIdxList[[i]], ])
      names(bootSubsetList)[i] <- paste0("bootstraped", i)
    }#for-loop ends
    return(bootSubsetList)   
  }
  
  ####################################
  # function 3                       #
  # PCA                              #
  ####################################
  PCA <- function(bootSubsetList){
    bootSubsetListRd <- lapply(bootSubsetList, function(x){subset(x, select = -y)})
    PCAcomp <- lapply(bootSubsetListRd, function(x){prcomp(x, center = TRUE)$rotation})
    PCAcompT <- lapply(PCAcomp, t)
    PCArrangement <- as.vector(unlist(lapply(PCAcompT, colnames)))
    #'bdiag' is a function included in the R package 'Matrix'
    #It returns block-shaped diagonal matrix which is sparse
    #rotationMatrix <- as.matrix(do.call(bdiag, lapply(PCAcompT, as.matrix)))
    rotationMatrix <- as.matrix(bdiag(lapply(PCAcompT, as.matrix)))
    colnames(rotationMatrix) <- PCArrangement
    rotationMatrix <- subset(rotationMatrix, select = sort(PCArrangement))
    return(as.matrix(rotationMatrix))
  }
  
  ####################################
  # function 4                       #
  # initialize Variables             #
  ####################################
  init.var <- function (data) {
    x <- data.frame(data[,-dim(data)[2]],stringsAsFactors = T)
    y <- data[,dim(data)[2]]
    y.level <- levels(as.factor(y))
    y <- as.integer(as.factor(y))
    dummy.location <- which(sapply(x,function(x){class(x)}) == "factor")
    if (length(dummy.location) > 0) {
      dummy.matrix <- matrix(nrow=dim(x)[1])
      for (j in 1:length(dummy.location)) {
        dummy.tmp <- as.matrix(model.matrix(~factor(x[,dummy.location[j]]))[,-1])
        if (dim(dummy.tmp)[2] > 1 & is.null(colnames(dummy.tmp)) == FALSE & nlevels(x[,dummy.location[j]]) == (ncol(dummy.tmp)+1)) {
          colnames(dummy.tmp) <- paste0(colnames(x)[dummy.location[j]],"_",levels(x[,dummy.location[j]]))[2:nlevels(x[,dummy.location[j]])]
        }
        dummy.matrix <- cbind(dummy.matrix,dummy.tmp)
      }
      x <- data.frame(dummy.matrix[,-1],x[,-dummy.location])
    }
    return(list(x,y,data.frame(id=1:length(y.level),Y=y.level)))
  }
  
  ####################################
  # main function                    #
  ####################################
  input.tmp <- init.var(data)
  x <- input.tmp[[1]]
  y <- input.tmp[[2]]
  Yclass <- input.tmp[[3]]
  PCArfList <- list()
  RmxList <- list()
  for(i in 1:numTrees){
    #generate a rotation matrix
    subsetList <- getRandomSubset(x = x, y = y, k = k)
    bootSubsetList <- bootstrap(subsetList = subsetList, bootstrapRate = bootstrapRate)
    RmxPCA <- PCA(bootSubsetList)
    #build a tree model and then put it in the list; PCArfList
    xRy <- cbind(data.frame(as.matrix(x) %*% RmxPCA), y)
    PCArfList[[i]] <- rpart(y ~., method = type, data = xRy)
    RmxList[[i]] <- RmxPCA
  }
  return(list(x=xRy,y=Yclass,model=PCArfList,PC=RmxList))
}
rf.predict <- function (model,newdata,method="max.prop",type="class") {
  
  ####################################
  # function 1                       #
  # initialize Variables             #
  ####################################
  init.var <- function (data) {
    x <- data.frame(data[,-dim(data)[2]],stringsAsFactors = T)
    y <- data[,dim(data)[2]]
    y.level <- levels(as.factor(y))
    y <- as.integer(as.factor(y))
    dummy.location <- which(sapply(x,function(x){class(x)}) == "factor")
    if (length(dummy.location) > 0) {
      dummy.matrix <- matrix(nrow=dim(x)[1])
      for (j in 1:length(dummy.location)) {
        dummy.tmp <- as.matrix(model.matrix(~factor(x[,dummy.location[j]]))[,-1])
        if (dim(dummy.tmp)[2] > 1 & is.null(colnames(dummy.tmp)) == FALSE & nlevels(x[,dummy.location[j]]) == (ncol(dummy.tmp)+1)) {
          colnames(dummy.tmp) <- paste0(colnames(x)[dummy.location[j]],"_",levels(x[,dummy.location[j]]))[2:nlevels(x[,dummy.location[j]])]
        }
        dummy.matrix <- cbind(dummy.matrix,dummy.tmp)
      }
      x <- data.frame(dummy.matrix[,-1],x[,-dummy.location])
    }
    return(list(x,y,data.frame(id=1:length(y.level),Y=y.level)))
  }
  
  ####################################
  # function 2                       #
  # max probability evaluation       #
  ####################################
  max.prob <- function(model,newdata) {
    pca.data <- matrix(nrow=dim(newdata)[1],ncol=dim(newdata)[2])
    result <- matrix(0,nrow=dim(newdata)[1],ncol=length(unique(model$model[[1]]$y)))
    for (i in 1:length(model[[3]])) {
      pca.data <- data.frame(as.matrix(newdata) %*% as.matrix(model$PC[[i]]))
      result <- result + predict(model$model[[i]], pca.data, type="prob")
    }
    yhat <- apply(result,1,function(x){which.max(x)})
    prob <- data.frame(result/length(model$model))
    return(list(class=yhat,probability=result))
  }
  
  ####################################
  # function 3                       #
  # majority vote evaluation         #
  ####################################
  max.vote <- function(model,newdata) {
    pca.data <- matrix(nrow=dim(newdata)[1],ncol=dim(newdata)[2])
    result <- matrix(0,nrow=dim(newdata)[1],ncol=length(model$model))
    for (i in 1:length(model$model)) {
      pca.data <- data.frame(as.matrix(newdata) %*% as.matrix(model$PC[[i]]))
      result[,i] <- predict(model$model[[i]], pca.data, type="class")
    }
    yhat <- apply(result,1,function(x){names(table(x))[1]})
    return(yhat)
  }
  
  ####################################
  # function 4                       #
  # regression evaluation            #
  ####################################
  regression <- function(model,newdata) {
    pca.data <- matrix(nrow=dim(newdata)[1],ncol=dim(newdata)[2])
    result <- matrix(0,nrow=dim(newdata)[1],ncol=length(model$model))
    for (i in 1:length(model[[3]])) {
      pca.data <- data.frame(as.matrix(newdata) %*% as.matrix(model$PC[[i]]))
      result[,i] <- predict(model$model[[i]], pca.data, type="vector")
    }
    result <- apply(result,1,function(x){mean(x)})
    return(result)
  }
  
  ####################################
  # main function                    #
  ####################################
  if (type == "class" & method == "max.vote") {
    input.tmp <- init.var(newdata)
    data <- input.tmp[[1]]
    result <- max.vote(model,data)
    return(result)
  } 
  if (type == "class" & method == "max.prob") {
    input.tmp <- init.var(newdata)
    data <- input.tmp[[1]]
    result <- max.prob(model,data)
    return(result)
  }
  if (type == "regression") {
    input.tmp <- init.var(newdata)
    data <- input.tmp[[1]]
    result <- regression(model,data)
    return(result)
  }
}

####################################
# regression                       #
####################################
data <- read.csv('filename.csv') # 타겟변수가 반드시 마지막 열에 있어야함
trn_idx <- sample(1:dim(data)[1], round(0.7*dim(data)[1]))
trn.data <- data[trn_idx,]
test.data <- data[-trn_idx,]
model <- rotationForest(trn.data,k=round(dim(data)[2]/3),type="anova")
prediction <- rf.predict(model,test.data,type="regression")
regression.perf_eval(test.data[,dim(test.data)[2]],prediction)

####################################
# classification                   #
####################################
data <- read.csv('filename.csv') # 타겟변수가 반드시 마지막 열에 있어야함
trn_idx <- sample(1:dim(data)[1], round(0.7*dim(data)[1]))
trn.data <- data[trn_idx,]
test.data <- data[-trn_idx,]
model <- rotationForest(trn.data,k=round(dim(data)[2]/3),type="class")
prediction <- rf.predict(model,test.data,type="class",method == "max.prob")
classification.perf_eval(test.data[,dim(test.data)[2]],prediction)