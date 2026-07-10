
hfdfm <- function(flows,
                  stocks,
                  target,
                  p = 1,
                  q = 1,
                  length_sample = 10000,
                  burn_in = 1000,
                  thinning = 1,
                  plots = T,
                  extend_to = NULL,
                  stochastic_volatility = TRUE,
                  serial_correlation = TRUE){

  # create an inventory of the time series involved
  inventory <- create_inventory(flows = flows, stocks = stocks)
  
  # import and transform data
  Ymat <- prepare_data(flows = flows,
                       stocks = stocks,
                       inventory = inventory,
                       target = target)
  
  t2 <- nrow(Ymat)
  
  # extend dataset to allow for forecasts
  if(!(is.null(extend_to))){
    if(extend_to > as.numeric(tail(time(Ymat),1))){
      
      Ymat <- window(Ymat,
                     end = as.numeric(extend_to),
                     extend = T)
      Ymat[which(is.na(Ymat))] <- 0
      
    }
  }
  
  
  # define parameters
  n <- ncol(Ymat) # Number of variables
  t <- nrow(Ymat) # Number of high-frequency periods
  k <- max(inventory$freq)/min(inventory$freq) # Fraction of high-frequency periods in lowest frequency
  s <- 2*(k - 1) # Number of periods for aggregation rule in formula (3)
  
  
  # plot the time series as a check for the user
  if(plots == T){
    
    tsl <- c(stocks,flows)
    par(mfrow = c(length(unique(inventory$freq)), 1))
    for(x in unique(inventory$freq)){
      plot.ts(scale(do.call(cbind,tsl[inventory$key[inventory$freq == x]])),
              xlab = NULL,
              ylab = paste("frequency: ",x),
              ylim = c(-15,15),
              plot.type="single")
    }
    par(mfrow = c(1,1))
    
  }
  
  print.noquote("preallocating..")
  Gmat_prealloc <- t(do.call(rbind,lapply(1:(t-1), function(tx){
    
    cbind(Matrix(0,n,tx-1),
          Matrix(1,n,s+2),
          Matrix(0,n,t-tx-1))
    
  })))
  
  
  # SAMPLING ----------------------------------------------------------------
  
  # run markov chain monte carlo sampling
  print.noquote("simulating posterior distribution..")
  par_save <- run_sampling(Ymat = Ymat,
                           target = target,
                           n = n,
                           t = t,
                           t2 = t2,
                           p = p,
                           s = s,
                           length_sample = length_sample,
                           burn_in = burn_in,
                           thinning = thinning,
                           inventory = inventory,
                           plots = plots,
                           Gmat_prealloc = Gmat_prealloc,
                           fdat = flows)
  
  print.noquote("processing output..")
  
  
  # EVALUATE POSTERIOR ------------------------------------------------------
  
  # average over parameter draws
  h_out <- Reduce("+", par_save$h)/length(par_save$h)
  lambda_out <- Reduce("+", par_save$lambda)/length(par_save$lambda)
  sigma_out <- Reduce("+", par_save$sigma)/length(par_save$sigma)
  omega_out <- Reduce("+", par_save$omega)/length(par_save$omega)
  phi_out <- Reduce("+", par_save$phi)/length(par_save$phi)
  rho_out <- Reduce("+", par_save$rho)/length(par_save$rho)
  Xmat_out <- Reduce("+", par_save$Xmat)/length(par_save$Xmat)
  rho_var <- apply(do.call(cbind,par_save$rho),1,var)
  
  # extract nowcasts
  ncst_mean <- ts(data = apply(do.call(cbind,par_save$ncast),1,mean),
                  start = time(par_save$ncast[[1]])[1],
                  frequency = frequency(par_save$ncast[[1]]))
                  
  ncst_var <- ts(data = apply(do.call(cbind,par_save$ncast),1,var),
                 start = time(par_save$ncast[[1]])[1],
                 frequency = frequency(par_save$ncast[[1]]))
  
  # full dataset
  Xmat_full <- ts(Xmat_out,
                  start = time(Ymat)[1],
                  frequency = frequency(Ymat))
  
  
  
  # MEAN AND VARIANCE OF GROWTH RATES ---------------------------------------
  
  # growth rates of factor at a quarterly rate and rescale
  flist <- lapply(par_save$f, function(fx){
    
    # cut off latent states from distributed lags at the beginning of the sample
    f_cut <- fx[(s+1):(t+s)]
    
    # de-standardize data using mean and variance from SECO series
    f_rescaled <- (f_cut * inventory[which(inventory$key == target),"sd"]) +
      inventory[which(inventory$key == target),"mean"]/k
    
    # annualize
    out_ts <- ts(((1+f_rescaled)^frequency(Ymat)-1)*100,
                 start = time(Ymat)[1],
                 frequency = frequency(Ymat))
    
  })
  
  f_mean <- Reduce("+", flist)/length(flist)
  f_var <- ts(apply(do.call(cbind,flist),1,var),
              start = time(f_mean)[1],
              frequency = frequency(f_mean))
  
  
  # MEAN AND VARIANCE OF INDEX ----------------------------------------------
  
  # growth rates of factor at a quarterly rate and rescale
  ilist <- lapply(par_save$f, function(fx){
    
    # cut off latent states from distributed lags at the beginning of the sample
    f_cut <- fx[(s+1):(t+s)]
    
    # de-standardize data using mean and variance from SECO series
    f_rescaled <- (f_cut * inventory[which(inventory$key == target),"sd"]) +
      inventory[which(inventory$key == target),"mean"]/k
    
    # annualize
    out_idx <- ts(exp(cumsum(f_rescaled)),
                  start = time(Ymat)[1],
                  frequency = frequency(Ymat))
    
  })
  
  i_mean <- Reduce("+", ilist)/length(ilist) * 100
  
  
  
  
  # OUTPUT ------------------------------------------------------------------
  
  out <- list("factor" = f_mean,
              "factor_var" = f_var,
              "index" = i_mean,
              "nowcast" = ncst_mean,
              "nowcast_var" = ncst_var,
              "target" = target,
              "pars" = list("h" = h_out[(s+2):(t+s+1)],
                            "lambda" = lambda_out,
                            "phi" = phi_out,
                            "sigma" = sigma_out,
                            "omega" = omega_out,
                            "rho" = rho_out,
                            "rho_var" = rho_var),
              "data" = Ymat,
              "data_augmented" = Xmat_full,
              "inventory" = inventory)
  
  class(out) <- "hfdfm"
  
  # return results
  return(out)
  
}


run_sampling <- function(Ymat, target, n, t, t2, p, s, length_sample, burn_in, thinning,
                         inventory, plots,Gmat_prealloc, fdat){
  
  # preallocation of output matrices
  chain <- NULL # matrix(NA, burn_in + length_sample*thinning, 100)
  par_save <- list("f" = vector(mode = "list", length = length_sample),
                   "lambda" = vector(mode = "list", length = length_sample),
                   "phi" = vector(mode = "list", length = length_sample),
                   "h" = vector(mode = "list", length = length_sample),
                   "sigma" = vector(mode = "list", length = length_sample),
                   "omega" = vector(mode = "list", length = length_sample),
                   "rho" = vector(mode = "list", length = length_sample),
                   "Xmat" = vector(mode = "list", length = length_sample),
                   "ncast" = vector(mode = "list", length = length_sample))
  
  # preallocations
  Llist <- get_distributed_lags(inventory)
  
  # random parameter starting values
  phi <- c(0.75,rep(0,p-1))
  lambda <- Matrix(1,n,1)
  sigma <- Diagonal(x = runif(n), n = n)
  omega <- 1e-2
  h <- matrix(-5, t+s, 1)
  f <- matrix(rnorm(t+s), t+s, 1)
  rho <- Diagonal(x = runif(n))
  Xmat = matrix(rnorm(t*n), t, n)
  indicators = replicate(t+s, sample(x = 1:7, size = 1, prob = rep(1/7,7)))
  
  # initialize progress bar
  pb <- txtProgressBar(style = 3)
  
  # loop until sampling complete
  for(jx in 1:(burn_in + length_sample*thinning)){
    
    setTxtProgressBar(pb, jx/(burn_in + length_sample * thinning))
    
    Gmat <- get_gmat(Gmat_prealloc, Llist, rho, lambda, s, t, n)
    
    # 0. augment data
    Xmat <- draw_augmented_data(Ymat, Gmat, f, rho, sigma, n, t, return_sample = T)
    
    # 1. draw factors (conditional on model parameters)
    f <- draw_factors(Xmat = Xmat,
                      Gmat = Gmat,
                      n = n,
                      p = p,
                      s = s,
                      t = t,
                      t2 = t2,
                      prealloc = prealloc,
                      lambda = lambda,
                      phi = phi,
                      sigma = sigma,
                      h = h,
                      rho = rho)
    
    # 2. draw stochastic volatility
    h <- draw_volatility(f = f,
                         phi = phi,
                         n = n,
                         p = p,
                         s = s,
                         t = t,
                         prealloc = prealloc,
                         omega = omega,
                         indicators = indicators,
                         h_old = h)
    
    # 3. draw model parameters (conditional on factors and volatility)
    Zmat <- get_zmat(f = f, n = n, t = t, s = s, Llist = Llist, rho = rho)
    lambda <- draw_lambda(Xmat = Xmat,
                          Ymat = Ymat,
                          Zmat = Zmat,
                          sigma = sigma,
                          rho = rho,
                          n = n, t = t,
                          inventory = inventory,
                          target = target)
    
    
    sigma <- draw_sigma(Xmat = Xmat, Ymat = Ymat, Gmat = Gmat, f = f, n = n, t = t,
                        inventory = inventory, target = target, rho = rho, sigma = sigma)
    phi <- draw_phi(f = f, h = h, p = p, t = t, phi_old = phi)
    omega <- draw_omega(h = h, t = t, s = s, p = p)
    rho <- draw_rho(Xmat = Xmat, f = f,  n = n, t = t, s = s, sigma = sigma,
                    lambda = lambda, Llist = Llist, inventory = inventory, target = target)
    
    indicators = draw_indicators(h, f, phi, n, p, s, t)
    
    # 3. check convergence
    if(plots == T){
      if(jx %% 1 == 0){
        par(mfrow = c(3,1))
        ix=which(inventory$key==target)
        plot(ts(as.matrix(f[(s+1):(t+s),]),
                start = time(Ymat)[1],
                frequency = frequency(Ymat)),
             ylim = c(-2.5,1),
             xlab = NULL,
             ylab = "factor",
             main = paste0("Iteration ",jx))
        plot(ts(exp(h),
                start = time(Ymat)[1] - s/frequency(Ymat),
                frequency = frequency(Ymat)),
             xlab = NULL,
             ylab = "stochastic volatility",
             main = NULL)
        plot.ts(cbind(Ymat[,ix],Xmat[,ix]),
                main = NULL,
                xlab = NULL,
                ylab = paste0("fitted ",inventory$key[ix]),
                lty = c(1,2),
                col = c("black","red"),
                plot.type="single")
        
        par(mfrow = c(1,1))
      }
    }
    
    # 4 start sampling upon convergence
    if(jx > burn_in & jx %% thinning == 0){
      
      # save factor and parameter draws
      par_save$f[[(jx - burn_in)/thinning]] <- f
      par_save$h[[(jx - burn_in)/thinning]] <- h
      par_save$lambda[[(jx - burn_in)/thinning]] <- lambda
      par_save$phi[[(jx - burn_in)/thinning]] <- phi
      par_save$omega[[(jx - burn_in)/thinning]] <- omega
      par_save$sigma[[(jx - burn_in)/thinning]] <- diag(sigma)
      par_save$rho[[(jx - burn_in)/thinning]] <- diag(rho)
      par_save$Xmat[[(jx - burn_in)/thinning]] <- Xmat
      par_save$ncast[[(jx - burn_in)/thinning]] <- get_nowcast(Xmat_full = ts(Xmat,
                                                                     start = time(Ymat)[1],
                                                                     frequency = frequency(Ymat)),
                                                      inventory = inventory,
                                                      target = target, 
                                                      flows = fdat)
      
      
      # GET NOWCAST -------------------------------------------------------------
      
      
    }
  }
  
  close(pb)
  return(par_save)
  
}




draw_factors <- function(Xmat, Gmat, n, p, s, t, t2, prealloc, lambda, phi, sigma, h, rho, return_sample = T){
  
  # See section 2.5 Estimation
  Xmat_tilde <- Xmat[-1,] - Xmat[-nrow(Xmat),] %*% rho
  Xvec_tilde <- t(Xmat_tilde)
  dim(Xvec_tilde) <- c(n*(t-1),1)
  
  H <- Reduce("+",lapply(1:p, function(px){
    
    cbind(rbind(Matrix(0,px,(t+s-px)),
                kronecker(Diagonal(t+s-px), -phi[px])),
          Matrix(0,(t+s),px))
    
  })) + Diagonal(n = (t+s))
  
  V <- Diagonal(x = exp(2*h))
  F0 <- t(H) %*% solve(V) %*% H
  
  # define selection vector such that latent data in forecast horizon has no more impact on factor
  Svec <- c(rep(1,t2-1),rep(0,t-t2))
  
  # Calculate conditional posterior of the factors
  F1 <- forceSymmetric(F0 + t(Gmat) %*% (Diagonal(x = Svec) %x% solve(sigma)) %*% Gmat)
  f1 <- solve(F1, t(Gmat) %*% (Diagonal(x = Svec) %x% solve(sigma)) %*% Xvec_tilde)
  
  if(return_sample){
    
    f <- as.matrix(f1 + solve(chol(F1), rnorm((t+s))))
    
  } else {
    
    f <- as.matrix(f1)
    
  }
  
  return(f)
  
}



draw_volatility <- function(f, phi, n, p, s, t, prealloc, omega, indicators, h_old){
  
  #  See appendix A.2 Stochastic Volatility
  err <- c(rep(0,p),f[seq(1+p,t+s),] - Reduce('+', lapply(1:p, function(px){
    f[seq(from = 1+p-px, t+s-px),,drop=F] %*% phi[px]})))
  
  # qs <- quantile(err, probs = c(0.05,0.95))
  # err[which(err<qs[1])] <- qs[1]
  # err[which(err>qs[2])] <- qs[2]
  
  w <- log(err^2 + 0.001)
  
  W <- Diagonal(x = 2, n = t+s)
  
  N <- cbind(rbind(Matrix(0,1,t+s-1),
                   kronecker(Diagonal(t+s-1), -1)),
             Matrix(0, t+s,1)) + Diagonal(n = (t+s))
  N <- N[-1,] # diffuse (improper) prior distribution
  
  Q0 <- t(N) %*% solve(Diagonal(x = rep(omega,t+s-1))) %*% N # precision matrix
  
  # approximate log chi squared distribution from mixture of normals (Primiceri 2005)
  nmix <- data.frame("prob" = c(0.00730,0.10556,0.00002,0.04395,0.34001,0.24566,0.25750),
                     "mean" = c(-10.12999,-3.97281,-8.56686,2.77786,0.61942,1.79518,-1.08819),
                     "var" = c(5.79596,2.61369,5.17950,0.16735,0.64009,0.34023,1.26261))
  
  # simulate from approximated chi-loq square distribution
  nx <- indicators
  xi = Diagonal(x = nmix[nx,"var"])
  mu <- Matrix(nmix[nx,"mean"] - 1.2704,t+s,1)
  
  # Calculate conditional posterior of the stochastic volatility (Appendix A.2)
  Q1 <-  forceSymmetric(Q0 + t(W) %*% solve(xi) %*% W)
  q1 <- solve(Q1,  t(W) %*% solve(xi) %*% (w - mu))
  
  h <- as.matrix(q1 + solve(chol(Q1), rnorm((t+s))) + 1e-9)
  
  # numerical stability, discard draws that are above the upper bound
  ubound <- -2.15
  h[which(h > ubound)] <- h_old[which(h > ubound)]
  
  return(h)
  
}





draw_indicators <- function(h, f, phi, n, p, s, t){
  
  # approximate log chi squared distribution from mixture of normals (Primiceri 2005)
  nmix <- data.frame("prob" = c(0.00730,0.10556,0.00002,0.04395,0.34001,0.24566,0.25750),
                     "mean" = c(-10.12999,-3.97281,-8.56686,2.77786,0.61942,1.79518,-1.08819),
                     "var" = c(5.79596,2.61369,5.17950,0.16735,0.64009,0.34023,1.26261))
  
  #  See appendix A.2 Stochastic Volatility
  err <- c(rep(0,p),f[seq(1+p,t+s),] - Reduce('+', lapply(1:p, function(px){
    f[seq(from = 1+p-px, t+s-px),,drop=F] %*% phi[px]})))
  
  w <- log(err^2 + 0.001)
  
  probs <- sapply(1:(t+s), function(tx){
    
    px <- sapply(1:7, function(px){
      
      nmix$prob[px] * dnorm(x = w[tx], mean = 2*h[tx] + nmix$mean[px] - 1.2704, sd = sqrt(nmix$var[px]))
      
    })
    
    sample(x = 1:7, size = 1, prob = px)
    
  })
  
  return(probs)
}










draw_augmented_data <- function(Ymat, Gmat, f, rho, sigma, n, t, return_sample = T){
  
  Yvec <- t(Ymat)
  dim(Yvec) <- c(n*t,1)
  
  # propose dataset
  Smat <- Diagonal(x = sapply(1:t, function(tx) as.integer(Ymat[tx,] != 0)))
  Kmat <- cbind(rbind(Matrix(0,n, n*(t-1)),
                      kronecker(Diagonal(t-1), -rho)),
                Matrix(0,(t)*n,n)) + Diagonal(n = n*t)
  
  P0 <- t(Kmat) %*% solve(Diagonal(n = t) %x% sigma) %*% Kmat
  
  V1 <-  solve(Diagonal(x = 1e-9, n = t*n))
  
  # Calculate conditional posterior of the factors, see Appendix A.3
  P1 <-  forceSymmetric(P0 + t(Smat) %*% (t(Smat) %*% V1 %*% Smat) %*% Smat)
  p1 <- solve(P1, t(Kmat) %*%  solve(Diagonal(n = t) %x% sigma)  %*% rbind(Matrix(0,n,1),Gmat %*% f) +
                t(Smat) %*% (t(Smat) %*% V1 %*% Smat) %*% Yvec)
  
  Xvec <- as.matrix(p1 + solve(chol(P1), rnorm((t*n))))
  
  dim(Xvec) <- c(n,t)
  Xmat <- t(Xvec)
  
  return(Xmat)
  
}



draw_lambda <- function(Xmat, Ymat, Zmat, sigma, rho, n, t, inventory, target){
  
  # See appendix A.4 Conditional distributions of Remaining Parameters: Factor Loadings
  Xmat_tilde <- Xmat[-1,] - Xmat[-nrow(Xmat),] %*% rho
  Xvec_tilde <- t(Xmat_tilde)
  dim(Xvec_tilde) <- c(n*(t-1),1)
  
  # uninformative priors
  b0 <- Matrix(0,n,1)
  B0 <- Diagonal(x = 1, n = n)
  
  # Conditional posterior distribution of the factor loadings lambda
  B1 <- solve(B0) + t(Zmat) %*% (Diagonal(t-1) %x% solve(sigma)) %*% Zmat
  b1 <- solve(B1, solve(B0) %*% b0 + t(Zmat) %*% (Diagonal(t-1) %x% solve(sigma)) %*% Xvec_tilde)
  
  lambda <- b1 + solve(chol(forceSymmetric(B1)),rnorm(n))
  
  # imposing identifying restriction
  lambda[which(inventory$key == target)] <- 1
  
  return(lambda)
  
}



draw_sigma <- function(Xmat, Ymat, Gmat, f, n, t, inventory, target, rho, sigma){
  # See appendix A.4 Conditional distributions of Remaining Parameters: Measurement Error Covariance Matrix
  
  Xmat_tilde <- Xmat[-1,] - Xmat[-nrow(Xmat),] %*% rho
  Xvec_tilde <- t(Xmat_tilde)
  dim(Xvec_tilde) <- c(n*(t-1),1)
  
  # get errors
  Xfit <- Gmat %*% f
  U <- Xvec_tilde - Xfit
  dim(U) <- c(n,t-1)
  U <- t(U)
  
  # draw measurement equation variance
  sigma = Diagonal(x = sapply(1:n, function(ix){
    
    if(ix == which(inventory$key == target)){
      
      # the prior choice for the target variable shrinks the measurement error variance
      # strongly towards zero. this ensures that the high frequency factor
      # is approximatively coherent with the low frequency target variable
      
      c0 <- t
      d0 <- t * 1e-3 # Different for in-sample run than for out-of-sample run
      
    } else {
      
      # this prior choice is uninformative
      
      c0 <- 3
      d0 <- 5e-2
      
    }
    
    c1 <- c0 + t
    d1 <- d0 + t(U[,ix]) %*% U[,ix]
    
    # sample from inverse gamma distribution
    1/rgamma(n = 1,
             shape = c1/2,
             rate = d1/2) + 1e-9 # add tiny amount of noise to avoid singularities
    
  }))
  
  # numerical stability in beginning
  diag(sigma)[which(diag(sigma) > 5)] <- 5
  
  return(sigma)
  
}



# Draw serial correlation (rho)
draw_rho <- function(Xmat, f, n, t, s, sigma, lambda, Llist, inventory, target){
  
  # See appendix A.4 Conditional distributions of Remaining Parameters: Autocorrelation of Measurement Errors
  # construct auxiliary matrix
  
  Xfit <- Reduce("+", lapply(0:s, function(sx){
    
    f[seq(from = 1+s-sx, to = t+s-sx),] %*% t(Llist[[as.character(sx)]] %*% lambda)
    
  }))
  
  E <- Xmat - Xfit
  
  
  rho <- Diagonal(x = sapply(1:n, function(nx){
    
    if(nx ==  which(inventory$key == target)){
      
      r0 = 0
      R0 = 1e-9
      
    } else {
      
      r0 = 0
      R0 = 5
    }
    
    R1 = solve(solve(R0) + solve(sigma[nx,nx]) * t(E[-nrow(E),nx]) %*% E[-nrow(E),nx])
    r1 = R1 %*% (solve(R0) %*% r0 + solve(sigma[nx,nx]) %*% t(E[-nrow(E),nx]) %*% E[-1,nx])
    
    
    # Initialize stationarity check
    check <- F
    count <- 0
    while(!check){
      
      # draw rho_i
      rho_i = rnorm(1, r1, sqrt(R1)) + 1e-9 # add tiny amount of noise to avoid zeros
      count <- count + 1
      
      # run checks
      if(count > 10) {
        rho_i <- 0.98
        #print(paste0("rho adjusted: ",inventory$key[nx]))
      }
      check = abs(rho_i) < 0.99
      
    }
    
    return(rho_i)
    
  }))
}


draw_phi = function(f, h, p, t, phi_old){
  # See appendix A.4 Conditional distributions of Remaining Parameters: Autoregressive Coefficients
  
  m = f[(p+1):(nrow(f)),]
  M = do.call(cbind, lapply(c(1:p), function(px) f[c((1+p-px):(nrow(f)-px)),]))
  
  V <- Diagonal(x = exp(2*h[(1+p):(nrow(h)),]))
  
  # uninformative prior
  a0 <- matrix(c(0,rep(0,p-1)))
  A0 <- Diagonal(x = 0.12/((1:p)^2), n = p)
  
  # distribution parameters
  A1 <- solve(solve(A0) + t(M) %*% solve(V) %*% M) # Formula (26)
  a1 <- A1 %*% (solve(A0) %*% a0 + t(M) %*% solve(V) %*% m) # Formula (27)
  
  # draw phi
  phi <- as.numeric(a1 + t(rnorm(p,0,1) %*% chol(forceSymmetric(A1))))
  
  # discard draw if not stationary or negatively autocorrelated
  phi[which(phi < 0)] <- 0
  if(sum(phi) > 0.9 | sum(diff(phi) > 0) > 0){

    phi <-  phi_old
  # repeat {
  #   phi <- as.numeric(a1 + t(rnorm(p,0,1) %*% chol(forceSymmetric(A1))))
  #   phi[phi < 0] <- 0
  #   
  #   if(sum(phi) <= 0.95 && sum(diff(phi) > 0) == 0) break
  }
  
  return(phi)
  
}







draw_omega <- function(h, t, s, p){
  # See appendix A.4 Conditional distributions of Remaining Parameters: Stochastic Volatility Variance
  v <- h[2:nrow(h),] - h[seq(from = 1, nrow(h)-1),,drop=F]
  
  # informative prior
  k0 <- t
  l0 <- t * 1e-2
  
  # parametrize posterior
  k1 <- k0 + t + s
  l1 <- l0 + as.numeric(t(v) %*% v)
  
  # sample stochastic volatility state equation error variance
  omega = 1/rgamma(n = 1,
                   shape = 0.5 * k1,
                   rate = 0.5 * l1) + 1e-9 # add tiny amount of noise to avoid singularity
  
  # if(omega > 0.1)  omega <- 0.1
  
  return(omega)
  
}





create_inventory <- function(flows, stocks){
  
  # construct inventory of time series
  inventory <- rbind(data.frame("key" = as.character(names(flows)),
                                "type" = factor("flow", levels = c("stock","flow")),
                                "freq" = sapply(flows, frequency),
                                "mean" = sapply(flows, mean, na.rm=T),
                                "sd" = sapply(flows, sd, na.rm=T),
                                stringsAsFactors = F,
                                row.names = NULL),
                     data.frame("key" = names(stocks),
                                "type" = factor("stock", levels = c("stock","flow")),
                                "freq" = sapply(stocks, frequency),
                                "mean" = sapply(stocks, mean, na.rm=T),
                                "sd" = sapply(stocks, sd, na.rm=T),
                                stringsAsFactors = F,
                                row.names = NULL))
  
  # remove NULL entires
  if(length(which(inventory$key == "") > 0)) inventory <- inventory[-which(inventory$key == ""),]
  
  return(inventory)
  
}



prepare_data <- function(flows, stocks, inventory, target){
  
  data <- c(flows, stocks)
  
  # standardize data
  data_std <- lapply(inventory$key, function(ix){
    
    (data[[ix]] - inventory[which(inventory$key == ix),"mean"])/
      inventory[which(inventory$key == ix),"sd"]
    
  }); names(data_std) <- inventory$key
  
  # adjust time periods
  freq_max <- max(sapply(data, frequency))
  
  data_adj <- lapply(inventory$key, function(ix){
    
    tim <- time(data_std[[ix]]) + (freq_max/frequency(data_std[[ix]]) - 1)/freq_max
    out <- as.data.frame(cbind(round(tim,5), data_std[[ix]]))
    colnames(out) <- c("time",ix)
    
    return(out)
    
  }); names(data_adj) <- inventory$key
  
  # coerce to sparse matrix
  idx = data.frame("time" = round(seq(1900, 2100, 1/freq_max),5))
  
  dfs <- lapply(data_adj, function(fx){
    
    tab <- left_join(idx, fx, by = "time")
    tab[,-1]
    
  })
  
  dfs <- do.call(cbind,dfs)
  colnames(dfs) <- inventory$key
  dfts <- ts(dfs, start = 1900, frequency = max(sapply(data, function(x) frequency(x))))
  dfts <- na.trim(dfts, is.na = "all")
  
  dfts[which(is.na(dfts))] <- 0
  
  return(dfts)
  
}



get_distributed_lags <- function(inventory){
  
  # frequencies
  k <- max(inventory$freq)/min(inventory$freq) # Redundant, can be imported from previous function
  s <- 2*(k - 1) #  Redundant, can be imported from previous function
  
  lmat <- matrix(0, nrow(inventory), s+1)
  freqs <- inventory$freq
  
  for(ix in 1:nrow(lmat)){
    
    if(inventory[ix,"type"] == "flow"){
      
      a <- max(freqs)/freqs[ix]
      b <- c(1:a,a:1)[-a]/a
      lmat[ix,1:length(b)] <- b
      
    } else {
      
      a <- max(freqs)/freqs[ix]
      b <- rep(1/a, a)
      lmat[ix,1:length(b)] <- b
      
    }
  }
  
  # distributed lag matrices
  out <- lapply(1:ncol(lmat), function(sx) Diagonal(x = lmat[,sx]))
  names(out) <- as.character(0:s)
  
  return(out)
  
}



get_zmat <- function(f, n, t, s, Llist, rho){
  
  Reduce("+", lapply(0:(s+1), function(sx){
    
    if(sx == 0){
      aux <- Llist[[as.character(0)]]
    } else if(sx == s+1){
      aux <- -rho %*% Llist[[as.character(s)]]
    } else {
      aux <- Llist[[as.character(sx-1)]] - rho %*% Llist[[as.character(sx)]]
    }
    
    f[seq(from = 2+s-sx, to = t+s-sx),] %x% aux
    
  }))
  
  
  
}


get_gmat <- function(Gmat_prealloc, Llist, rho, lambda, s, t, n){
  
  aux <- cbind(-rho %*% Llist[[as.character(s)]] %*% lambda,
               do.call(cbind, lapply((s-1):0, function(sx){
                 (Llist[[as.character(sx+1)]] - rho %*% Llist[[as.character(sx)]]) %*% lambda})),
               Llist[[as.character(0)]] %*% lambda)
  
  
  Gmat_prealloc@x <- rep(as.vector(t(aux)),t-1)
  t(Gmat_prealloc)
  
  
}


get_nowcast <- function(Xmat_full, inventory, target, flows){
  
  # get the entry where GDP is usually recorded
  idx <- which(round(time(Xmat_full) + 1/max(inventory$freq), 3) %% (1/frequency(flows[[target]])) == 0)
  target_fit <- Xmat_full[idx, which(inventory$key==target)]
  
  
  # rescale
  target_rescaled <- (target_fit * inventory[which(inventory$key == target),"sd"]) +
    inventory[which(inventory$key == target),"mean"]
  
  out <- ts(target_rescaled,
            start = time(flows[[target]])[1],
            frequency = frequency(flows[[target]]))
  
  return(out)
  
}




