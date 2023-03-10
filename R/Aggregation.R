#' Aggregates original time resolution to a coarser time step
#'
#' @param datain input data 
#' @param new_tstep time step
#' @param qc_flags condider quality flags
#' @param qc_name which qc to consider

aggregate_tsteps <- function(datain, new_tstep, qc_flags, qc_name){
  
  #First save old original tstep
  datain$original_timestepsize  <- datain$timestepsize 
  
  #Number of time steps to aggregate
  ntsteps <- (new_tstep * 60*60) / datain$timestepsize 
  

  #Variable names
  vars <- datain$vars
  
  #Initialise new data.frame
  new_data <- matrix(NA, ncol=ncol(datain$data), nrow=nrow(datain$data)/ntsteps)
  colnames(new_data) <- colnames(datain$data)
  new_data <- as.data.frame(new_data)
  
  #Indices for aggregating
  seq <- seq(from=1, by=ntsteps, length.out=nrow(new_data))
  
  #Flags for observed 
  good_data <- c(qc_flags$QC_measured)
  
  #Loop through variables
  for(k in 1:length(vars)){
    
    method <- datain$aggr_method[vars[k]]
    
    #QC variable: calculate fraction observed & good quality gapfilling
    if(grepl(qc_name, substr(vars[k], nchar(vars[k])-(nchar(qc_name)-1), nchar(vars[k])))){
      
      if(is.na(method)){
        
        #Calculate fraction
        new_data[,vars[k]] <- sapply(seq, function(x) qc_frac(datain$data[x:(x+ntsteps-1),
                                                                          vars[k]], good_data))
      } else {
        
        stop(paste("Aggregation method for QC variable", vars[k], "not set",
                   "correctly. Method must be set to NA for QC variables,",
                   "please amend output variable file."))
      }
      
      
      #Other variables: average or sum up  
    } else {
      
      aggr_data <- datain$data[,vars[k]]
      
      if(method=="mean"){
        
        aggr_data <- sapply(seq, function(x) mean(aggr_data[x:(x+ntsteps-1)], na.rm=FALSE))
        
      } else if(method=="sum"){
        
        aggr_data <- sapply(seq, function(x) sum(aggr_data[x:(x+ntsteps-1)], na.rm=FALSE))    
        
      } else {
        
        stop(paste("Aggregation method for variable", vars[k], "not recognised.",
                   "Method must be set to 'mean' or 'sum', please amend output variable file."))
      }
      
      #Write to data frame
      new_data[,vars[k]] <- aggr_data
      
    }  
  } #vars
  
  
  #Finally, extract correct time steps
  
  new_start <- datain$time[seq,1]
  new_end   <- datain$time[seq+(ntsteps-1),2]
  
  #Collate to new dataframe
  new_time <- cbind(new_start, new_end)
  colnames(new_time) <- colnames(datain$time)
  
  
  #Replace data and time step info
  datain$data <- new_data
  datain$time <- new_time

  datain$ntsteps <- nrow(datain$time)
  datain$timestepsize <- datain$timestepsize * ntsteps
  
  
  #New QC flag descriptions
  
  qc_flags$qc_info <- "Fraction (0-1) of aggregated time steps that were observed"
  
  #Collate
  outs <- list(data=datain, qc_flags=qc_flags)
  
  return(outs)
  
}

#' Calculates fraction of good quality data
#' 
#' Returns gapfilled fraction given two data frames
#' of original and gappfilled data
#'
#' @param data original input data
#' @param good_data gapfilled data

qc_frac <- function(data, good_data){
  
  good_frac <- which(sapply(good_data, function(x) data==x))
  good_frac <- length(good_frac) / length(data)
  
  return(good_frac)
}




