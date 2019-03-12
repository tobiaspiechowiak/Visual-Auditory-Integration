

path <- 'data/'
data <- read.csv(paste0(path,'Integration4','.csv')) #nr 4 is good 


a <- integration_fit(data)

plot(a$data$x[3:14],a$res, type = 'l', xlab = 'Angles', ylab = 'Residuals of Regression')

plot(a$data, xlab = 'Angles', ylab = 'Values')


integration_fit <- function(data){
  
  out <- list()
  names(data) <- c('x','y')
  mean_data <- aggregate(data, by = list(data$x), FUN = mean)
  mean_data <- mean_data[,-c(1)]
  mean_data_ <- mean_data[mean_data >= 0,]
  fit <- lm(y ~ x, data = mean_data_)
  
  
  out$res <- cumsum(recresid(fit, data = mean_data_))
  out$data <- na.omit(mean_data_)
  
  return(out)
  
}


