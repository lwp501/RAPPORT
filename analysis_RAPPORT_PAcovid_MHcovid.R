# program: analysis_RAPPORT_PAcovid_MHcovid.R
# task: perform relevant analyses for 
# outcome: mental health at age 17,
# exposure: physical activity at age 14 
# author: Lewis Paton
# code last update: 10/02/2023

# In this file, we perform analyses investigating the impact of 
# physical activity during the Covid-19 pandemic on mental health during the Covid-19 pandemic
# Sections:
# 1. import the data and data management
# 2. handle missing covariate data
# 3. define outcome, exposure and covariates 
# 4. split sample into 2 sets
# 5. perform feature selection 
# 6. summarise the distribution of covariates by exposure
# 7. plot  distribution of outcome, by exposure 
# 8. run TMLE analyses 
# 9. look at the propensity score distributions by both TMLE models
# 10. look at the distributions of the initial Q predictions
# 11. perform  causal forest analyses 
# 12. rerun TMLE models with different definitions of 'exposure'

#setwd to directory
setwd("C:/Users/lwp501/Google Drive/research/RAPPORT/work/PAcovidMHcovid")

#use checkpoint for version control
library(checkpoint)
checkpoint("2023-01-26", 
           checkpoint_location ="C:/Users/lwp501/Google Drive" )

#load required libraries
library(dplyr)
library(tmle)
library(ggplot2)
library(reshape)
library(Amelia)
library(caret)
library(MASS)
library(tableone)
library(grf)
library(randomForest)
library(xgboost)
library(dotwhisker)
library(gridExtra)


#set random seed
set.seed(6428)

############# 1. import data ############
# see stata do files for details on main data cleaning

#load data
mcsData <- as.data.frame(read.csv("mcscovid_clean.csv", header=T))

# keep all variables except:
# i) id variables (id, id_mcs_family, cm_number)
# ii) exposure(s)  not considering in this analysis (physical_activity_anydays_w6, 
#physical_activity_guideline_w7, physical_activity_days_w6, physical_activity_guideline_w7, physical_activity_days_w7
# iii) alternative outcome variable (kessler_w7, kessler_SMI_w7, phq2_total_covid, phq2_depressed_covid)

mcsData <- dplyr::select(mcsData, !c(id,
                                     id_mcs_family,
                                     cm_number,
                                     physical_activity_anydays_w6,
                                     physical_activity_guideline_w7,
                                     physical_activity_days_w6,
                                     physical_activity_days_w7,
                                     physical_activity_guideline_w6,
                                     phq2_total_covid,
                                     phq2_depressed_covid,
                                     kessler_w7))


############## 2. missing covariate data #################

# single imputation & indicator variable for each variable
# i.e. - male (with single imputed value) & generate male_miss (a binary indicator)
# keep only complete cases in outcome and exposure
# only impute those variables with more than 10% missing
# if wanted to keep only complete cases, 
# use mcsData <- mcsData[complete.cases(mcsData),] instead of imputation code below

# keep only complete cases in outcome and exposure
mcsData <- mcsData[complete.cases(mcsData[, c("kessler_covid", 
                                              "physical_activity_hours_covid")]),]

all.included.covs <- names(mcsData)

# remove those covariates with > 10% missing

missing.more.10percent <-names(which(colSums(is.na(mcsData))> 0.1*nrow(mcsData)))
mcsData <- mcsData[!names(mcsData) %in% missing.more.10percent]

#create dummy variables

missing.vars <- names(which(colSums(is.na(mcsData))>0))

missing.indicators <- as.data.frame(matrix(nrow=dim(mcsData[1]),
                                           ncol=length(missing.vars)))

for(i in 1:length(missing.vars)) { 
  colnames(missing.indicators)[i] <- paste0("missing_", missing.vars[i])
  missing.indicators[[i]] = ifelse(is.na(mcsData[[missing.vars[i]]]), 1,0)
}


#imputation

missing.vars.noms = c("nw_w6", "good_PE_w6",
                      "close_friends_w6",  "worried_keeptoself_w6",
                      "worried_parent_w6", "worried_sibling_w6", "worried_friend_w6",
                      "worried_relative_w6", "worried_teacher_w6", "worried_adult_w6",
                      "self_harmed_w6", "safe_area_w6","school_fee_paying_w6", "same_sex_school_w6",
                      "changed_school_w6", "ever_suspended_school_w6", "ever_expelled_school_w6",
                      "sen_w6", "active_travel_school_w6", "longterm_ill_w6", 
                      "urban_w6", "lgbtq_w7", "always_know_where_CM_out_w6",
                      "always_know_who_CM_out_w6" ,"always_know_what_CM_out_w6",
                      "own_bedroom_w6", "own_computer_w6", "faith_school_w6", "reg_watch_sport_w6",
                      "sometimes_wake_sleep_w6")


missing.vars.ords = c("hours_day_TV_w6",
                      "hours_day_videogame_w6","use_internet_w6", "hours_week_socialmedia_w6",
                      "homework_w6", "edu_mot_try_best_w6", "edu_mot_scl_interesting_w6",
                      "edu_mot_scl_unhappy_w6", "edu_mot_scl_tiring_w6", "edu_mot_scl_wastetime_w6",
                      "edu_mot_diff_conc_w6", "family_friends_safe_w6",  "someone_trust_w6",            
                      "noone_close_to_w6",  "risks_willing_w6", "patience_w6", "trust_w6", "freq_talk_to_CM_w6",
                      "IMD_income_decile_w6")

missing.vars.cont = c("bmi_w6", "tot_self_esteem_w6", "tot_life_satisfaction_w6", "tot_smfq_w6", "kessler_parent_w6")

missing.vars.defined = c(missing.vars.cont, missing.vars.noms, missing.vars.ords)

# check code works
stopifnot(length(missing.vars) == length(missing.vars.defined))

# if code doesn't work, use setdiff to see which variables haven't been defined
#setdiff(missing.vars, missing.vars.defined)          

#single imputation on missing covariates using amelia
mcsData.imp <- amelia(mcsData, m=1, 
                      noms = missing.vars.noms,
                      ords = missing.vars.ords)

#save imputation file
write.amelia(obj=mcsData.imp, file.stem="imputation")

#combine imputed data with missing imputation data 
mcsData <- mcsData.imp$imputations$imp1
mcsData <- cbind(mcsData, missing.indicators) 

############### 3. define Y, A and W ###########################

# define outcome 
mcsData.outcome <- mcsData$kessler_covid

# define exposure

# save physical activity hours variable
# ordinal variable
# Q: Typical hours per day spent doing physical activity?

physical_activity_hours_covid <- mcsData$physical_activity_hours_covid

# drop days from main dataframe 
mcsData <- dplyr::select(mcsData, !c(physical_activity_hours_covid))
mcsData.imputed.noPA <- mcsData

#define all exposures

# none (0) v any (1)
physical_activity_guideline_covid<-ifelse(physical_activity_hours_covid>=1, 1, 0)

# 
physical_activity_2plus_covid<-ifelse(physical_activity_hours_covid>=2, 1, 0)


# 4/5 v 1/2/3  = 2 or less (0) v 3 days+ (1)
physical_activity_3plus_covid<-ifelse(physical_activity_hours_covid>=3, 1, 0)

# 2/3/4 v 1 = 6 days or less (0) v every day (1)
physical_activity_5plus_covid<-ifelse(physical_activity_hours_covid>=5, 1, 0)


#add in exposure to main data frame and define separtely 
mcsData$physical_activity_guideline_covid<-physical_activity_guideline_covid

mcsData$physical_activity_guideline_covid<-physical_activity_guideline_covid

mcsData.exposure <- mcsData$physical_activity_guideline_covid

# define covariates

mcsData.covariates <- dplyr::select(mcsData, !c("kessler_covid", "physical_activity_guideline_covid"))

mcsData.no.outcome <- dplyr::select(mcsData, !c(kessler_covid))

###### 4. split samples into 2 sets: 20% for feature selection, 80% for analysis 

train.size <- floor(0.2 * nrow(mcsData))
train.ind <- sample(seq_len(nrow(mcsData)), size = train.size)

mcsData.train <- mcsData[train.ind, ]
mcsData.test <- mcsData[-train.ind, ]

mcsData.outcome.train <- mcsData.outcome[train.ind]
mcsData.outcome.test <- mcsData.outcome[-train.ind]

mcsData.exposure.train <- mcsData.exposure[train.ind]
mcsData.exposure.test <- mcsData.exposure[-train.ind]

mcsData.covariates.train <- mcsData.covariates[train.ind, ]
mcsData.covariates.test <- mcsData.covariates[-train.ind, ]

mcsData.no.outcome.train <- mcsData.no.outcome[train.ind, ]
mcsData.no.outcome.test <- mcsData.no.outcome[-train.ind, ]


######### 5. feature selection #############

#automatic feature selection using randomForest()

#fit forest for outcome in training data
outcome.forest  <- randomForest(x=mcsData.covariates.train, y=mcsData.outcome.train)

#define importance
outcome.forest.varimp <- importance(outcome.forest)

#selected variables which meet criteria....
selected.vars.outcome <- which(outcome.forest.varimp / mean(outcome.forest.varimp) > 0.5)

results.FS.outcome = colnames(mcsData.covariates.train[,selected.vars.outcome])

outcome.imp <- as.data.frame(varImpPlot(outcome.forest))
outcome.imp$varnames <- rownames(outcome.imp)
rownames(outcome.imp) <- NULL  

#select top 10 important variables for plotting
outcome.big.imp <- slice_max(outcome.imp, IncNodePurity, n=10)

#plot and save
imp.plot.outcome <- ggplot(outcome.big.imp, aes(x=reorder(varnames, IncNodePurity), weight=IncNodePurity)) +
  geom_bar(fill="#C00000") + 
  theme(axis.text.x = element_text(angle=90, size=12)) + xlab("Variable") + ylab("Importance") 

imp.plot.outcome
ggsave("top10_important_features_outcome.png")

# fit forest for exposure
exposure.forest  <- randomForest(x=mcsData.covariates.train, y=as.factor(mcsData.exposure.train))

exposure.forest.varimp <- importance(exposure.forest)

selected.vars.exposure <- which(exposure.forest.varimp / mean(exposure.forest.varimp) > 0.6)
results.FS.exposure = colnames(mcsData.covariates.train[,selected.vars.exposure])


#selected covs = intersection of these two feature selection processes
selected.covs = intersect(results.FS.outcome, results.FS.exposure)

deleted.covs <- setdiff(all.included.covs, selected.covs)  


########## 6. distributions of covariates by exposure####################

CreateTableOne(data=mcsData, strata = "physical_activity_guideline_covid")
CreateTableOne(data=mcsData.train, strata ="physical_activity_guideline_covid")
CreateTableOne(data=mcsData.test, strata ="physical_activity_guideline_covid")

######### 7. plot distribution of outcome ######
hist.outcome.all <- ggplot(mcsData, aes(kessler_covid)) + geom_bar(fill="#C55A11") + xlab("Kessler score, Covid")

hist.outcome.A0 <- ggplot(subset(mcsData,physical_activity_guideline_covid==0), aes(kessler_covid)) +
  geom_bar(fill="#A9D18E") + xlab("Kessler score, Covid, didn't meet guideline")

hist.outcome.A1 <- ggplot(subset(mcsData,physical_activity_guideline_covid==1), aes(kessler_covid)) +
  geom_bar(fill="#548235") + xlab("Kessler score, Covid, met guideline")

grid.arrange(hist.outcome.A0, hist.outcome.A1, nrow = 2)

outcomes_by_exposure <- arrangeGrob(hist.outcome.A0, hist.outcome.A1, nrow = 2)
ggsave(file="outcome_distributions.png", outcomes_by_exposure) 

########## 8. run TMLE models

#define custom learners
create_gams = create.Learner("SL.gam", tune = list(deg.gam = c(3,4,5)))

#define SL library
SL.library = c("SL.glm",
               "SL.glmnet",
               "SL.xgboost",
               create_gams$names)

tmle.fit.glm <- tmle(Y = mcsData.outcome.test,
                     A = mcsData.exposure.test,
                     W = mcsData.covariates.test[,selected.covs],
                     family = "gaussian",
                     V = 3,
                     Q.SL.library = "SL.glm",
                     g.SL.library = "SL.glm",
                     verbose = T)

tmle.fit.ensemble <- tmle(Y = mcsData.outcome.test,
                          A = mcsData.exposure.test,
                          W = mcsData.covariates.test[,selected.covs],
                          family = "gaussian",
                          V = 3,
                          Q.SL.library = SL.library,
                          g.SL.library = SL.library,
                          verbose = T)


tmle.est.glm <- tmle.fit.glm$estimates$ATE$psi
tmle.ci.glm <- tmle.fit.glm$estimates$ATE$CI

tmle.est.ensemble <- tmle.fit.ensemble$estimates$ATE$psi
tmle.ci.ensemble <- tmle.fit.ensemble$estimates$ATE$CI

tmle.est.ensemble

#as a comparison, a linear regression model

regression.df = as.data.frame(mcsData.test[,selected.covs])
regression.df['kessler_w7'] <- mcsData.outcome.test
regression.df['exposure'] <- mcsData.exposure.test

lm.model <- lm(kessler_w7~., data=regression.df) 
confint(lm.model)

############# 9. plot distribution of propensity scores from both tmle models ##########################
#g1W = P(A=1|W)

mcsData.test$glm.g1W = tmle.fit.glm$g$g1W
mcsData.test$ensemble.g1W = tmle.fit.ensemble$g$g1

png(filename="prop_score_distributions.png")
par(mfrow=c(2,1))
plot(density(mcsData.test$glm.g1W[mcsData.test$physical_activity_guideline_covid==0]), 
     col = "red", main = "GLM",xlim=c(0,1))
lines(density(mcsData.test$glm.g1W[mcsData.test$physical_activity_guideline_covid==1]), 
      col = "blue", lty = 2)

plot(density(mcsData.test$ensemble.g1W[mcsData.test$physical_activity_guideline_covid==0]), 
     col = "red", main = "ensemble",xlim=c(0,1))
lines(density(mcsData.test$ensemble.g1W[mcsData.test$physical_activity_guideline_covid==1]), 
      col = "blue", lty = 2)
dev.off()


########################plot estimates 

png(filename="estimates.png")
par(mfrow=c(2,1))
## under control
hist(tmle.fit.ensemble$Qinit$Q[,1])
# under treatment
hist(tmle.fit.ensemble$Qinit$Q[,2])

dev.off()


#reset plotting area
par(mfrow=c(1,1))

# 10. causal forests


#fit the forest for exposure 
propscore.forest.exposure <- regression_forest(X = mcsData.covariates.test[,selected.covs], 
                                               Y = mcsData.exposure.test,
                                               tune.parameters = "all") 

# predict the propensity score using this forest
exposure.hat <- predict(propscore.forest.exposure)$predictions


# fit the forest for Y
outcome.forest  <- regression_forest(X = mcsData.covariates.test[,selected.covs],
                                     Y = mcsData.outcome.test,
                                     tune.parameters = "all")
# predict the outcome Y
outcome.hat <- predict(outcome.forest)$predictions


# fit the forest
tau.forest.allvars <- causal_forest(X=mcsData.covariates.test[,selected.covs],
                                    Y=mcsData.outcome.test,
                                    W=mcsData.exposure.test,
                                    W.hat = exposure.hat,
                                    Y.hat = outcome.hat, 
                                    tune.parameters = "all")


# predict tau hat 
tau.hat.allvars <- predict(tau.forest.allvars)

#get histogram
png("causal_forest_preds.png")
hist(tau.hat.allvars$predictions)
dev.off()
##### Plotting Relationships between CATEs and continuous variables ####

plot(loess.smooth(mcsData.covariates.test$bmi_w6, tau.hat.allvars$predictions), 
     xlab='BMI W6', ylab='CATE')

plot(loess.smooth(mcsData.covariates.test$IMD_income_decile_w6, tau.hat.allvars$predictions),
     xlab='IMD decile', ylab='CATE')



##### Best Linear Predictor of Heterogeneity ######
covariates_blp = data.frame(mcsData.covariates.test[,selected.covs])

# make BMI  categorical (3 buckets)
# make BMI  categorical (2 buckets)
# get the cutpoints
cutpoints.bmi <- quantile(covariates_blp$bmi_w6, seq(0,1,length=3),na.rm=TRUE)  
# get the categorical variable
covariates_blp$bmicat <- cut(covariates_blp$bmi_w6, cutpoints.bmi, labels = c("low", "high"))

cutpoints.selfesteem <- quantile(covariates_blp$tot_self_esteem_w6, seq(0,1,length=3),na.rm=TRUE)  
# get the categorical variable
covariates_blp$selfesteemcat <- cut(covariates_blp$tot_self_esteem_w6, cutpoints.selfesteem, labels = c("low", "high"))

cutpoints.lifesat <- quantile(covariates_blp$tot_life_satisfaction_w6, seq(0,1,length=3),na.rm=TRUE)  
# get the categorical variable
covariates_blp$lifesatcat <- cut(covariates_blp$tot_life_satisfaction_w6, cutpoints.lifesat, labels = c("low", "high"))

cutpoints.smfq <- quantile(covariates_blp$tot_smfq_w6, seq(0,1,length=3),na.rm=TRUE)  
# get the categorical variable
covariates_blp$smfqcat <- cut(covariates_blp$tot_smfq_w6, cutpoints.smfq, labels = c("low", "high"))

cutpoints.kesslerpar <- quantile(covariates_blp$kessler_parent_w6, seq(0,1,length=3),na.rm=TRUE)  
# get the categorical variable
covariates_blp$kesslerparcat <- cut(covariates_blp$kessler_parent_w6, cutpoints.kesslerpar, labels = c("low", "high"))


# remove the continuous versions 
covariates_blp <- covariates_blp[, -which(names(covariates_blp) %in% c("bmi_w6", "tot_self_esteem_w6", 
                                                                       "tot_life_satisfaction_w6", "tot_smfq_w6",
                                                                       "kessler_parent_w6"))]


# dummify the data
dmy_covariates_blp <- dummyVars(" ~ .", data = covariates_blp)
trsf_covariates_blp <- data.frame(predict(dmy_covariates_blp, newdata = covariates_blp))

## examine the new data
head(trsf_covariates_blp)

# get scores from our fit causal forest 
CF.scores <- get_scores(tau.forest.allvars)

# create temporary dataframe with causal forest scores
temp_df.CF <- data.frame(CF.scores)
temp_df.CF <- cbind(temp_df.CF,trsf_covariates_blp)

# run ols
#temp_ols.CF = lm("CF.scores ~ .",data = trsf_W_blp)
temp_ols.CF = lm("CF.scores ~ .",data = temp_df.CF)
summary(temp_ols.CF)


## Sort the estimates in decreasing order
ordervars <- names(sort(coef(temp_ols.CF)))



## create the plot
dwplot <- dwplot(list(temp_ols.CF), vline = geom_vline(
  xintercept = 0,
  colour = "grey60",
  linetype = 2), 
  vars_order=ordervars) +
  scale_color_discrete(name = "ML Method", labels = c("Causal Forest")) +
  ggtitle("Predictors of Treatment Effect Heterogeneity") +
  theme(plot.title = element_text(face="bold"),
        legend.position="right",
        legend.title=element_blank()) 

# print the plot
dwplot
ggsave("CF.png")


#13. rerun TMLE with different exposure classifications


mcsData.exposure <- physical_activity_2plus_covid

mcsData.exposure.train <- mcsData.exposure[train.ind]
mcsData.exposure.test <- mcsData.exposure[-train.ind]

tmle.fit.ensemble.2plus <- tmle(Y = mcsData.outcome.test,
                                A = mcsData.exposure.test,
                                W = mcsData.covariates.test[,selected.covs],
                                family = "gaussian",
                                V = 3,
                                Q.SL.library = SL.library,
                                g.SL.library = SL.library,
                                verbose = T)



mcsData.exposure <- physical_activity_3plus_covid

mcsData.exposure.train <- mcsData.exposure[train.ind]
mcsData.exposure.test <- mcsData.exposure[-train.ind]

tmle.fit.ensemble.3plus <- tmle(Y = mcsData.outcome.test,
                                A = mcsData.exposure.test,
                                W = mcsData.covariates.test[,selected.covs],
                                family = "gaussian",
                                V = 3,
                                Q.SL.library = SL.library,
                                g.SL.library = SL.library,
                                verbose = T)


mcsData.exposure <- physical_activity_5plus_covid

mcsData.exposure.train <- mcsData.exposure[train.ind]
mcsData.exposure.test <- mcsData.exposure[-train.ind]

tmle.fit.ensemble.5plus <- tmle(Y = mcsData.outcome.test,
                                A = mcsData.exposure.test,
                                W = mcsData.covariates.test[,selected.covs],
                                family = "gaussian",
                                V = 3,
                                Q.SL.library = SL.library,
                                g.SL.library = SL.library,
                                verbose = T)



sens.analysis.results = data.frame(exposure = c("Any (guideline)", "2+ hours", "3+ hours", "5+ hours"),
                                   ATE = c(tmle.fit.ensemble$estimates$ATE$psi,
                                           tmle.fit.ensemble.2plus$estimates$ATE$psi,
                                           tmle.fit.ensemble.3plus$estimates$ATE$psi,
                                           tmle.fit.ensemble.5plus$estimates$ATE$psi),
                                   lower = c(tmle.fit.ensemble$estimates$ATE$CI[1],
                                             tmle.fit.ensemble.2plus$estimates$ATE$CI[1],
                                             tmle.fit.ensemble.3plus$estimates$ATE$CI[1],
                                             tmle.fit.ensemble.5plus$estimates$ATE$CI[1]),
                                   upper = c(tmle.fit.ensemble$estimates$ATE$CI[2],
                                             tmle.fit.ensemble.2plus$estimates$ATE$CI[2],
                                             tmle.fit.ensemble.3plus$estimates$ATE$CI[2],
                                             tmle.fit.ensemble.5plus$estimates$ATE$CI[2]))

sens.analysis.results$exposure <- factor(sens.analysis.results$exposure,
                                         levels = c("Any (guideline)",
                                                    "2+ hours",
                                                    "3+ hours",
                                                    "5+ hours"))


sens.g <- ggplot(sens.analysis.results,
                 aes(
                   x = exposure, y= ATE, colour=exposure)) +
  geom_point(position = position_dodge(width = .5), size=3) +
  geom_errorbar(aes(
    ymin = lower, ymax = upper), width = .5, position = "dodge", linewidth=1) +
  ylab("Impact on Kessler score") + xlab("Hours exercise per week") + theme() +
  geom_hline(yintercept = 0, linetype='dotted', linewidth=1) +
  ggtitle("Effect of exercise on psychological distress during Covid-19 pandemic")
sens.g

ggsave("sensitivity_analysis_plot.png")
