// program: master_cleaning.do
// task: merge relevant clean MCS data sets
// project: RAPPORT 
// author: Lewis Paton 
// code last updated: 03/02/2023

//run cleaning files

cd "G:\My Drive\research\RAPPORT\"
*cd "C:\users\lwp501\Google Drive\research\RAPPORT\

do "work\wave_6_cleaning.do" 

cd "G:\My Drive\research\RAPPORT\"
*cd "C:\users\lwp501\Google Drive\research\RAPPORT\

do "work\wave_7_cleaning.do"

// merge all wave 6 files into master wave 6

use "derived\mcs_sweep6_imd_e_2004_clean.dta", clear

append using "derived\mcs_sweep6_imd_s_2004_clean.dta"

append using "derived\mcs_sweep6_imd_w_2004_clean.dta"

append using "derived\mcs_sweep6_imd_n_2004_clean.dta"

save "derived\mcs_sweep6_imd_combined_clean.dta", replace

use "derived\mcs6_cm_derived_clean.dta", clear

merge 1:1 PID using "derived\mcs6_cm_interview_clean.dta"

drop _merge

merge 1:1 PID using "derived\mcs6_parent_cm_interview_clean.dta"

drop _merge 

merge 1:1 MCSID using "derived\mcs6_parent_derived_clean.dta"

drop _merge

merge 1:1 MCSID using "derived\mcs_sweep6_imd_combined_clean.dta"

drop _merge

save "derived\mcs6_merged_clean.dta", replace


// merge all wave 7 files into master wave 7

use "derived\mcs7_cm_interview_clean.dta", clear 

merge 1:1 PID using "derived\mcs7_cm_derived_clean.dta"

drop _merge


save "derived\mcs7_merged_clean.dta", replace



// merge w6 and w7 master

use "derived\mcs6_merged_clean.dta", clear

merge 1:1 PID using "derived\mcs7_merged_clean.dta"


drop _merge CMrow FELIG00 FRESP00 GCNUM00 FPNUM00 FCCREL00

rename MCSID id_mcs_family
rename PID id
rename FCNUM00 cm_number


order id id_mcs_family cm_number kessler* depression_*


save "derived\mcs6and7_merged_clean.dta", replace

// export clean dta file to csv for import to R

use "derived\mcs6and7_merged_clean.dta", clear

//drop variables deemed not important for analysis, or individual items replaced by summed scores e.g. rosenber self-esteem

drop depression_last30_days_w7 depression_age_w7 depression_treatment_current_w7 depression_diagnosed_w7 depression_treatment_ever_w7 obese* ///
cogtest_time_w6  communicate_mother_digital_w6 communicate_father_digital_w6 ///
bed_time_school_w6 wake_up_time_school_w6 bed_time_noschool_w6 wake_up_time_noschool_w6 time_to_fall_asleep_w6  ///
suspensions_total_w6 expulsions_total_w6 time_off_school_w6 weeks_off_school_w6 mental_health_w6  ///
illness_limit_activity_w6 medication_w6 parent_religion_w6 nsssec_w6 communicate_mother_digital_w7 communicate_father_digital_w7 freq_talk_to_TAIM_w7 ///
gender_id_w7 activity_theatre_w7 activity_watch_sport_w7 activity_music_w7 activity_live_music_w7 activity_read_w7 activity_youth_club_w7 ///
activity_library_w7 activity_museum_w7 activity_religious_w7 acitivity_friends_outside_w7 perception_of_weight_w7 exercised_weight_w7 food_weight_w7 ///
changes_weight_w7 height_w7 weight_w7 body_fat_percent_w7 sdq_emotional_self_w7 sdq_conduct_self_w7 sdq_hyper_self_w7 sdq_peer_self_w7 sdq_prosoc_self_w7 ///
sdq_totdiff_self_w7 sdq_emotional_parent_w7 sdq_conduct_parent_w7 sdq_hyper_parent_w7 sdq_peer_parent_w7 sdq_prosoc_parent_w7 sdq_totdiff_parent_w7 ///
height_w6 weight_w6 bmi_w7 body_fat_percent_w6 ocean_* awaken_during_sleep_w6 social_prob_w6 good_english_w6 good_maths_w6 good_science_w6 ///
rosenberg_* feelings_* wellbeing_*
  
export delimited using "derived\mcs6and7_merged_clean.csv", replace nolab

