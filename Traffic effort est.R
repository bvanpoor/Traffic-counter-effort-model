################################################################################
# imputeEffort.R
# Brett van Poorten (brett.vanpoorten@gov.bc.ca)
# Scott Brydle (scotthowardbrydle@gmail.com)
# June 19, 2017
#
# Input files: "Kawkawa 2016 traffic data.data"          
#       includes traffic data from top and bottom counters, independent car count data, independent
#          angler count data, observed fishing trip lengths from creel surveys and daily temperature
#          and precipitation
#
# Output files: (a) "Imputation_MCMC.i.dat" where i is model number (1:4)
#
# Required JAGS files: (a) "Traf_Eff_Est_full.bug"
#                      (b) "Traf_Eff_Est_pfish_weather.bug"
#                      (c) "Traf_Eff_Est_ptrail_weather.bug"
#                      (d) "Traf_Eff_Est_weather.bug"
#
################################################################################

# Load necessary packages
library(R2jags)

orig <- getwd()
start.time <- Sys.time()
#est <- TRUE
METHOD <- "JAGS"
#mod <- 4      # options are: 1-no covariates for pfishing or ptrailer;
               # 2-weather covariates for pfishing;
               # 3-weather covariates for ptrailer;
               # 4-weather covariates for pfishing and ptrailer

#----------------------------------------------------------------------------
#  DATA SECTION
#----------------------------------------------------------------------------

load("Kawkawa 2016 traffic data.data")
attach(data)

#----------------------------------------------------------------------------
#  JAGS Impute
#----------------------------------------------------------------------------

jags_data <- list( 'n.tc',      # number of traffic counters
                   'ndays',     # number of days being modelled
                   'T.c',       # traffic counter data
                   'n.Tc.obs',  # number of traffic counter observations
                   'Tc.day',    # day of each traffic counter observation
                   'Tc.hour',   # hour of each traffic counter observation
                   'Tc.loc',    # location of each traffic counter observation (we used two counters)
                   'n.Cc',      # number of independent vehicle observations
                   'Cc',        # independent vehicle observations
                   'Cc.d',      # day of each independent vehicle observation
                   'Cc.h',      # hourl of each independent vehicle observation
                   'n.Acd',     # number of angler count days to evaluation
                   'n.Ach.f',   # number of angler count hours to evaluate (for fishing)
                   'n.Ach.nf',  # number of angler count hours to evaluate (for non-fishers)
                   'Ac.d2',     # pointers that relate day index to actual day
                   'Ac.h2.f',   # pointers that relate day/hour index to actual hour (for fishers)
                   'Ac.h2.nf',  # pointers that relate day/hour index to actual hour (for non-fishers)
                   'min.Ach',   # minimum hour
                   't.fish',    # total number of anglers by date/hour
                   't.nofish',  # total number of non-anglers by date/hour
                   'trips',     # list of observed fishing trip lengths
                   'n.tr',      # number of fishing trip length observations
                   'ncount',    # number of counts per trip to dock (assumed 2 here)
                   'Temp',      # normalized daily air temperatures
                   'Precip',    # normalized daily precipitation
                   'DoW'        # day of week (0=weekday; 1=weekend)
)

parameters <- c("Et","E","tau.Tc","tau.Cc","tau.Ac")

inits <- function() {
  list( mu.fish       = rnorm(1,0.20,0.01),
        prec.fish     = rnorm(1,50,1),
        mu.trail      = rnorm(1,0.1,0.01),
        prec.trail    = rnorm(1,10,1),
        ftrip         = rnorm(1,3.5,0.01),
        mu.muf1       = rnorm(1,10,0.01),
        mu.muf2       = rnorm(1,140,0.01),
        prec.f1       = rnorm(1,100,0.01),
        prec.f2       = rnorm(1,100,0.01),
        mu.mub1       = rnorm(1,13,0.01),
        mu.mub2       = rnorm(1,0.1,0.01),
        mu.nb1        = rnorm(1,15,0.01),
        mu.nb2        = rnorm(1,1,0.01),
        prec.b1       = rnorm(1,0.02,0.001),
        prec.b2       = rnorm(1,0.04,0.001),
        prec.nb1      = rnorm(1,2,0.01),
        prec.nb2      = rnorm(1,50,0.01),
        nvisit        = rnorm(ndays,10,1),
        mu.fnorm      = rnorm(ndays,12,0.01),
        prec.fnorm    = rnorm(ndays,100,0.01),
        mu.bnorm      = rnorm(ndays,12,0.01),
        prec.bnorm    = rnorm(ndays,100,0.01),
        mu.int.f      = rnorm(1,0,0.001),
        prec.int.f    = rnorm(1,100,0.001),
        int.f         = rnorm(ndays,0,0.0001),
        alphF.T       = rnorm(1,0,0.0001),
        alphF.P       = rnorm(1,0,0.0001),
        alphF.B       = rnorm(1,0,0.0001),
        mu.int.t      = rnorm(1,0,0.001),
        prec.int.t    = rnorm(1,100,0.001),
        int.t         = rnorm(ndays,0,0.0001),
        alphT.T       = rnorm(1,0,0.0001),
        alphT.P       = rnorm(1,0,0.0001),
        alphT.B       = rnorm(1,0,0.0001)
  )
}

mod.nam <- switch(mod,"Traf_Eff_Est_full.bug","Traf_Eff_Est_pfish_weather.bug",
                  "Traf_Eff_Est_ptrail_weather.bug","Traf_Eff_Est_weather.bug")

if(est){
  cat("Model run initiated at ",start.time,"\n")
  jags_output <- jags.parallel( 
    data               = jags_data,
    inits              = inits,
    parameters.to.save = parameters,
    model.file         = mod.nam,
    n.chains           = 3,
    n.iter             = 500+100,
    n.burnin           = 500,
    n.thin             = 1,
    DIC                = TRUE )
  
  save( jags_output, file=paste("Imputation_MCMC",mod,"dat",sep="." ))
  end.time <- Sys.time()
  time.taken <- end.time-start.time
  cat(time.taken,"\n")
}

detach()
