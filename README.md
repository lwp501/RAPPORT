# RAPPORT
Repository for cleaning and analysis code for RAPPORT project

Included are the following cleaning files:

i) wave_6_cleaning.do - Stata code for cleaning the Millennium Cohort Study wave 6 (aged 14) datasets
ii) wave_7_cleaning.do - Stata code for cleaning the Millennium Cohort Study wave 7 (aged 17) datasets
iii) master_cleaning.do - Stata code for merging Millennium Cohort Study wave 6 and wave 7 files, and outputing a .csv for analysis 
iv) wave_covid_cleaning.do - Stata code for cleaning data from Wave 1 of the Covid-19 survey, merging with wave 6 and 7 data. and outputting a .csv for analysis

Included are the following analysis files:

v) analysis_RAPPORT_PA14_MH17.R - R code for performing TMLE and Causal Forest analyses for the impact of physical activity at age 14 on mental health at age 17 
vi) analysis_RAPPORT_PA17_MH17.R - R code for performing TMLE and Causal Forest analyses for the impact of physical activity at age 17 on mental health at age 17 
vii) analysis_RAPPORT_PAcovid_MHcovid.R - R code for performing TMLE and Causal Forest analyses for the impact of physical activity during the Covid-19 pandemic on mental health during the Covid-19 pandemic
