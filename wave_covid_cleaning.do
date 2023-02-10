cd "C:\users\lwp501\research\RAPPORT\data\

capture log close
log using wave_covid_cleaning_log, replace text

// program: wave_covid_cleaning.do
// task: clean relevant covid MCS datasets, and merge
// project: RAPPORT 
// author: Lewis Paton 
// code last updated: 07/02/2023

version 17
clear all
set linesize 80
macro drop _all

use "source\UKDA-8658-stata_MCS_covid\stata\stata13\covid-19_wave1_survey_cls.dta", clear

keep if CW1_COHORT==4 // MCS CM


gen CMrow = "_C1" if CW1_CNUM00 == 1
replace CMrow = "_C2" if CW1_CNUM00 == 2
replace CMrow = "_C3" if CW1_CNUM00 == 3
gen PID = MCSID + "_" + string(CW1_CNUM00) if (CW1_CNUM00 > 0)
replace PID = MCSID + CMrow if (CW1_CNUM00 > 0)

merge 1:1 PID using "derived\mcs6_included_PID.dta"

keep if _merge==3
drop _merge

//physical activity
rename CW1_Timeuse1_8_1 physical_activity_hours_covid
recode physical_activity_hours_covid (-8=.)

//kessler
foreach i in CW1_PHDE CW1_PHHO CW1_PHRF CW1_PHEE CW1_PHWO CW1_PHNE {
	recode `i' (-8=.) (1=4) (2=3) (3=2) (4=1) (5=0)
}

gen kessler_covid = CW1_PHDE + CW1_PHHO + CW1_PHRF + CW1_PHEE + CW1_PHWO + CW1_PHNE


//covid questions
gen ever_covid = .
replace ever_covid = 1 if CW1_COVID19==1 | CW1_COVID19 ==2
replace ever_covid = 0 if CW1_COVID19==4 
drop CW1_COVID19

rename CW1_COVIDSYMPT_23 covid_symptoms_reported 
recode covid_symptoms_reported (1=0) (2=1)

recode CW1_GAD2PHQ2_3 (-8=.) (1=0) (2=1) (3=2) (4=3)
recode CW1_GAD2PHQ2_4 (-8=.) (1=0) (2=1) (3=2) (4=3)


//phq2 covid
gen phq2_total_covid = CW1_GAD2PHQ2_3 + CW1_GAD2PHQ2_4

gen phq2_depressed_covid = .
replace phq2_depressed_covid = 1 if phq2_total >=3 & phq2_total !=.
replace phq2_depressed_covid = 0 if phq2_total <3 & phq2_total !=.

//keep only relevant variables
keep PID kessler_covid ever_covid covid_symptoms_reported phq2_total phq2_depressed physical_activity_hours_covid

rename PID id
//merge with mcs6and7_merged_clean for confounders
merge 1:1 id using "derived\mcs6and7_merged_clean.dta"

//keep only those with records in covid data
keep if _merge==3
drop _merge

save "derived\mcscovid_clean.dta", replace



//drop variables deemed not important for analysis, or individual items replaced by summed scores e.g. rosenberg self-esteem
drop depression_last30_days_w7 depression_age_w7 depression_treatment_current_w7 depression_diagnosed_w7 depression_treatment_ever_w7 obese* ///
cogtest_time_w6 communicate_mother_digital_w6 communicate_father_digital_w6 ///
bed_time_school_w6 wake_up_time_school_w6 bed_time_noschool_w6 wake_up_time_noschool_w6 time_to_fall_asleep_w6  ///
suspensions_total_w6 expulsions_total_w6 time_off_school_w6 weeks_off_school_w6 mental_health_w6  ///
illness_limit_activity_w6 medication_w6 parent_religion_w6 nsssec_w6 communicate_mother_digital_w7 communicate_father_digital_w7 freq_talk_to_TAIM_w7 ///
gender_id_w7 activity_theatre_w7 activity_watch_sport_w7 activity_music_w7 activity_live_music_w7 activity_read_w7 activity_youth_club_w7 ///
activity_library_w7 activity_museum_w7 activity_religious_w7 acitivity_friends_outside_w7 perception_of_weight_w7 exercised_weight_w7 food_weight_w7 ///
changes_weight_w7 height_w7 weight_w7 body_fat_percent_w7 sdq_emotional_self_w7 sdq_conduct_self_w7 sdq_hyper_self_w7 sdq_peer_self_w7 sdq_prosoc_self_w7 ///
sdq_totdiff_self_w7 sdq_emotional_parent_w7 sdq_conduct_parent_w7 sdq_hyper_parent_w7 sdq_peer_parent_w7 sdq_prosoc_parent_w7 sdq_totdiff_parent_w7 ///
height_w6 weight_w6 bmi_w7 body_fat_percent_w6 awaken_during_sleep_w6 social_prob_w6 good_english_w6 good_maths_w6 good_science_w6 ///
rosenberg_* feelings_* wellbeing_*  sdq_tot_diff_w6 sdq_emotion_w6 sdq_conduct_w6 sdq_hyper_w6 sdq_peerprob_w6 sdq_prosoc_w6 ///
cogtest_word_w6 cogtest_delay_aversion_w6 cogtest_delib_time_w6 cogtest_overall_prop_bet_w6 cogtest_qual_dec_making_w6 ///
cogtest_risk_adjust_w6 cogtest_risk_taking_w6 bike_w6 activity_cinema_w6 activity_music_w6 ///
activity_read_w6 activity_youthclub_w6 activity_museums_w6 activity_religious_w6 ocean* activity_watch_sport_w6
  
export delimited using "derived\mcscovid_clean.csv", replace nolab

export delimited using "C:\users\lwp501\research\RAPPORT\work\PAcovidMHcovid\mcscovid_clean.csv", replace nolab




