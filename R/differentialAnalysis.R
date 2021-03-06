################################################################################
#' Convert phyloseq OTU count data into DGEList for edgeR package
#' 
#' Further details.
#' 
#' @param physeq (Required).  A \code{\link{phyloseq-class}} or
#'  an \code{\link{otu_table-class}} object. 
#'  The latter is only appropriate if \code{group} argument is also a 
#'  vector or factor with length equal to \code{nsamples(physeq)}.
#'  
#' @param group (Required). A character vector or factor giving the experimental
#'  group/condition for each sample/library. Alternatively, you may provide
#'  the name of a sample variable. This name should be among the output of
#'  \code{sample_variables(physeq)}, in which case
#'  \code{get_variable(physeq, group)} would return either a character vector or factor.
#'  This is passed on to \code{\link[edgeR]{DGEList}},
#'  and you may find further details or examples in its documentation.
#'  
#' @param method (Optional). The label of the edgeR-implemented normalization to use.
#'  See \code{\link[edgeR]{calcNormFactors}} for supported options and details. 
#'  The default option is \code{"RLE"}, which is a scaling factor method 
#'  proposed by Anders and Huber (2010).
#'  At time of writing, the \link[edgeR]{edgeR} package supported 
#'  the following options to the \code{method} argument:
#'  
#'  \code{c("TMM", "RLE", "upperquartile", "none")}.
#'
#' @param ... Additional arguments passed on to \code{\link[edgeR]{DGEList}}
#' 
#' @export
#' @examples
#' 
phyloseq_to_edgeR = function(physeq, group, method="RLE", ...){
    require("edgeR")
    require("phyloseq")
    # Enforce orientation.
    if( !taxa_are_rows(physeq) ){ physeq <- t(physeq) }
    x = as(otu_table(physeq), "matrix")
    # Add one to protect against overflow, log(0) issues.
    x = x + 1
    # Check `group` argument
    if( identical(all.equal(length(group), 1), TRUE) & nsamples(physeq) > 1 ){
        # Assume that group was a sample variable name (must be categorical)
        group = get_variable(physeq, group)
    }
    # Define gene annotations (`genes`) as tax_table
    taxonomy = tax_table(physeq, errorIfNULL=FALSE)
    if( !is.null(taxonomy) ){
        taxonomy = data.frame(as(taxonomy, "matrix"))
    } 
    # Now turn into a DGEList
    y = DGEList(counts=x, group=group, genes=taxonomy, remove.zeros = TRUE, ...)
    # Calculate the normalization factors
    z = calcNormFactors(y, method=method)
    # Check for division by zero inside `calcNormFactors`
    if( !all(is.finite(z$samples$norm.factors)) ){
        stop("Something wrong with edgeR::calcNormFactors on this data,
         non-finite $norm.factors, consider changing `method` argument")
    }
    # Estimate dispersions
    return(estimateTagwiseDisp(estimateCommonDisp(z)))
}
################################################################################



#' Mann-whitney test for a dataframe
#'
#' @param df Input data object that contains the data to be tested. Required
#' @param label.vec.num The target binary condition. Required
#' @param pvalue.cutoff choose p-value cut-off
#' @return df.output object
#' @export
#' @examples
#' Wilcox_Test_df(df.list[[i]], label.vec.num, pvalue.cutoff)

Wilcox_Test_df <- function(df, label.vec.num, pvalue.cutoff = 0.05) {
  df.output <- NULL
  #save raw values
  label.vec.save <- unique(label.vec.num)
  
  # transform label into 1 and 0
  label.vec.num[label.vec.num == unique(label.vec.num)[1]] <- 1
  label.vec.num[label.vec.num != 1] <- 0
  
  for (i in 1:nrow(df)){
    # remove zero-variance rows
    if (sum(df[i,] == 1) == length(label.vec.num) | sum(df[i,] == 0) == length(label.vec.num)){
      next
    }
    tmp.result <- wilcox.test(df[i,which(label.vec.num == 1)], df[i,which(label.vec.num == 0)], correct=FALSE)
    if (tmp.result$p.value <= pvalue.cutoff){
      num.1 <- sum(df[i,which(label.vec.num == 1)])
      num.2 <- sum(df[i,which(label.vec.num == 0)])
      df.output <- rbind(df.output, c(rownames(df)[i], round(as.numeric(tmp.result$p.value), 4), num.1, num.2))
    }
  }
  if (is.null(df.output)){
    return(0)
  }
  colnames(df.output) <- c("Name", "P-value", label.vec.save[1],label.vec.save[2])
  return(df.output)
}






#' transform cpm counts to presence-absence matrix
#'
#' @param df Input data object that contains the data to be tested. Required
#' @return df.output object
#' @export
#' @examples
#' GET_PAM(df)

GET_PAM <- function(df) {
  for (i in 1:nrow(df)){
    df[i,] <- as.numeric(df[i,] > 0)
  }
  return(df)
}



#' Given PAM and disease/control annotation, do Chi-square test for each row of PAM
#'
#' @param pam Input data object that contains the data to be tested. Required
#' @param label.vec.num The target binary condition. Required
#' @param pvalue.cutoff choose p-value cut-off
#' @return df.output object
#' @export
#' @examples
#' Chisq_Test_Pam(pam, label.vec.num, pvalue.cutoff)

Chisq_Test_Pam <- function(pam, label.vec.num, pvalue.cutoff = 0.05) {
  df.output <- NULL
  
  #save raw values
  label.vec.save <- unique(label.vec.num)
  
  # transform label into 1 and 0
  label.vec.num[label.vec.num == unique(label.vec.num)[1]] <- 1
  label.vec.num[label.vec.num != 1] <- 0
  
  
  for (i in 1:nrow(pam)){
    # remove zero-variance rows
    if (sum(pam[i,] == 1) == length(label.vec.num) | sum(pam[i,] == 0) == length(label.vec.num)){
      next
    }
    tmp.result <- chisq.test(pam[i,], label.vec.num, correct=FALSE)
    if (tmp.result$p.value <= pvalue.cutoff){
      num.1 <- sum(pam[i,] == 1 & label.vec.num == 1)
      num.2 <- sum(pam[i,] == 1 & label.vec.num == 0)
      df.output <- rbind(df.output, c(rownames(pam)[i], round(as.numeric(tmp.result$p.value), 4), num.1, num.2))
    }
  }
  if (is.null(df.output)){
    return(0)
  }
  colnames(df.output) <- c("Name", "P-value", label.vec.save[1], label.vec.save[2])
  return(df.output)
}



#' Given PAM and disease/control annotation, do Chi-square test for each row of PAM
#'
#' @param pam Input data object that contains the data to be tested. Required
#' @param label.vec.num The target binary condition. Required
#' @param pvalue.cutoff choose p-value cut-off
#' @return df.output object
#' @export
#' @examples
#' Fisher_Test_Pam(pam, label.vec.num, pvalue.cutoff)

Fisher_Test_Pam <- function(pam, label.vec.num, pvalue.cutoff = 0.05) {
  df.output <- NULL
  
  #save raw values
  label.vec.save <- unique(label.vec.num)
  
  # transform label into 1 and 0
  label.vec.num[label.vec.num == unique(label.vec.num)[1]] <- 1
  label.vec.num[label.vec.num != 1] <- 0
  
  for (i in 1:nrow(pam)){
    # remove zero-variance rows
    if (sum(pam[i,] == 1) == length(label.vec.num) | sum(pam[i,] == 0) == length(label.vec.num)){
      next
    }
    tmp.result <- fisher.test(pam[i,], label.vec.num)
    #print(tmp.result$p.value)
    if (tmp.result$p.value <= pvalue.cutoff){
      more.in.case <- sum(pam[i,] == 1 & label.vec.num == 1) > sum(pam[i,] == 1 & label.vec.num == 0)
      num.1 <- sum(pam[i,] == 1 & label.vec.num == 1)
      num.2 <- sum(pam[i,] == 1 & label.vec.num == 0)
      df.output <- rbind(df.output, c(rownames(pam)[i], round(as.numeric(tmp.result$p.value), 4), num.1, num.2))
    }
  }
  #return(df.output)
  if (is.null(df.output)){
    return(0)
  }
  colnames(df.output) <- c("Name", "P-value", label.vec.save[1], label.vec.save[2])
  return(df.output)
}
