cd "C:\users\lwp501\research\RAPPORT\data\

capture log close
log using wave_6_cleaning_log, replace text

// program: wave_6_cleaning.do
// task: clean relevant wave 6 MCS datasets, and merge
// project: RAPPORT 
// author: Lewis Paton 
// code last updated: 10/02/2023

version 17
clear all
set linesize 80
macro drop _all

// key variables from (datasets) to include from [active ingreditents] :
// activities grid (CM_interview) [engagement with the arts] FCCINE00  FCSPOR00 FCBAND00 FCRJOY00 FCORGA00 FCMUSM00 
// cognitive test (CM_cognitive_assessment/derived) [problems solving] FCCMCOGA - FCCMCOGT ?
// frequency parent talks to CM about things important (parent_CM_interview) [self-disclosure, communication in families] FPTAIM00
// parental religion (parent_derived) how often attend religious service (CM_interview) [spiritual and religious beliefs] FCRLSV00
// CM bed time (CM_interview), how long to fall asleep (CM_interview) [circadian rhythms] FCSLWK00 FCWUWK00 FCSLWE00 FCWUWE00 FCSLLN00 FCSLTR00
// CM medication (parent_CM_interview) [use of SSRIs] FPCLTR00
// feelings grid/rosenberg grid (CM_interview) [various ingredients relating to emotion, loneliness etc] FCSATI00 FCGDQL00 FCDOWL00 FCVALU00 
// FCGDSF00 FCMDSA00 FCMDSB00 FCMDSC00 FCMDSD00 FCMDSE00 FCMDSF00 FCMDSG00 FCMDSH00  FCMDSI00 FCMDSJ00 FCMDSK00 FCMDSL00 FCMDSM00
// how often communivate with parents via digital media (CM_interview) [digital quality social connection] FCPHMA00 FCPHPA00
// I have friends and family who help me feel safe etc (CM_interview) [family support/loneliness] FCSAFF00 FCTRSS00 FCNCLS00
// wellbeing grid (CM_interview) [school connectedness] FCSCWK00 FCWYLK00 FCFMLY00 FCFRNS00 FCSCHL00 FCLIFE00
// IMD socioeconmic data (IMD_x_2004) [money] NSSEC (parent_derived)
// IMD rural/urban classification (IMD_x_2004), allowed unsupervised outside (CM_interview), [access to green space] FIERURUR FINRURUR FISRURUR FIWRURUR FCPLWE00 FCPLWK00


// #1
// decide included CMs 
use "source\UKDA-8156-stata_MCS_wave6\stata\stata13\mcs6_cm_interview.dta", clear


// MCSID is family ID - some families have 2 children in the MCSID (n=142 in this dataset are second children)
// To avoid nesting of data, take a random sample of those families with 2 children in 
// ie keep all those MCSIDs which are unique
// for those that are not unique (ie 2 instances of MCSID) take one child at random
// also, need to create a unique ID by combining MCSID and FCNUM00 to identify included CMs in other datasets

set seed 2435676

keep MCSID FCNUM00

/* taken from user guide */
gen CMrow = "_C1" if FCNUM00 == 1
replace CMrow = "_C2" if FCNUM00 == 2
replace CMrow = "_C3" if FCNUM00 == 3
gen PID = MCSID + "_" + string(FCNUM00) if (FCNUM00 > 0)
replace PID = MCSID + CMrow if (FCNUM00 > 0)

duplicates tag MCSID, gen(multi_children)

generate random = runiform()

egen included = max(random), by(MCSID)

keep if random==included

keep PID

save "derived\mcs6_included_PID.dta", replace

// #2
// clean mcs6_cm_interview.dta

use "source\UKDA-8156-stata_MCS_wave6\stata\stata13\mcs6_cm_interview.dta", clear 


// define labels
label define yesno 0 "No" 1 "Yes"
label define gender 0 "Female" 1 "Male"


//keep only those in mcs6_included_PID.dta

gen CMrow = "_C1" if FCNUM00 == 1
replace CMrow = "_C2" if FCNUM00 == 2
replace CMrow = "_C3" if FCNUM00 == 3
gen PID = MCSID + "_" + string(FCNUM00) if (FCNUM00 > 0)
replace PID = MCSID + CMrow if (FCNUM00 > 0)

merge 1:1 PID using "derived\mcs6_included_PID.dta"

keep if _merge==3
drop _merge

rename FCCSEX00 male_w6
recode male_w6 2=0
label values male_w6 gender

drop FCCDBM00 FCCDBY00 // month of birth and year of birth

rename FCCAGE00 age_w6

//drop variables relating to consent to measure physical attributes 
drop FCVERSF0 FCINTROA FCCHIC0A FCCHIC0B FCCHIC0C FCCHIC0D FCCHIC0E ///
FCCHAC0A FCCHAC0B FCCHAC0C FCCHAC0D FCCHAC0E 

rename FCHTCM00 height_w6
replace height_w6=. if height_w6==-1 | height_w6==-5 // codes for missing categories

//drop other variables relating to height, time of measurement etc.
drop FCHTCM1D FCHTCMOR FCHTCMPE FCHTFT00 FCHTIN00 FCHTCCKA FCHTCCKB ///
FCHTCCKC FCHTCCKD FCHKHTCK FCUNHT00 FCHTAT00 FCHTATCK FCHTM100 FCHTM200 ///
FCHTTMCK FCHTRL0A FCHTRL0B FCHTRL0C FCHTRL0D FCHTRL0E FCHTRL0F FCHTRL0G ///
FCHTRL0H FCHTRL0I FCHTRL0J FCHTRL0K FCHTRL0L FCHTRL0M FCHTRL0N FCHTEL00 // 

//drop variables relating to pacemaker in CM
drop FCBFCK00 FCBFCKCK

rename FCWTCM00 weight_w6
replace weight_w6=. if weight_w6==-1

//drop other variables relating to weight
drop FCWTCM1D FCWTCMOR FCWTCMPE FCWTST00 FCWTPO00 FCWTC1CK FCWTC2CK ///
FCWTC3CK FCWTC4CK FCWTCMCK FCWTUN00

rename FCBFPC00 body_fat_percent_w6
replace body_fat_percent_w6=. if body_fat_percent_w6==-1 | ///
body_fat_percent_w6 ==-5

//drop other variables relating to body fat % measurement
drop FCBFPCD0 FCBFPCCK FCBDFMCK FCFEET00 FCNOBF00 FCWTAT00 FCWTATCK FCWTSC00 ///
FCWTRL0A FCWTRL0B FCWTRL0C FCWTRL0D FCWTRL0E FCWTRL0F FCWTRL0G FCWTRL0H ///
FCWTRL0I FCWTRL0J FCWTEL00 

//drop checks for measurements recorded within MCS
drop FCPMRC0A FCPMRC0B FCPMRC0C FPPMRC0D

// drop variables relating to interview (length, location, consent etc)
drop FCCRHM00 FCVERSG0 FCLSCSG0 FCLMNSG0 FCLMBDG0 FCSESSG0 FCYPARCN FCYYCON0 /// 
FCSLFCMP FCWHINTD

rename FCPHEX00 physical_activity_days_w6
recode physical_activity_days_w6 (-9=.) (-8=.) (-1=.) 


// define variable whether meeting government guidelines or not
// https://www.nhs.uk/live-well/exercise/exercise-guidelines/physical-activity-guidelines-children-and-young-people/
// set 'every day' and '5-6 days' as compliant with guidelines

gen physical_activity_guideline_w6 = .
replace physical_activity_guideline_w6 = 1 if physical_activity_days_w6 == 1 | ///
physical_activity_days_w6 ==2
replace physical_activity_guideline_w6 = 0 if physical_activity_days_w6 == 3 | ///
physical_activity_days_w6 == 4 | physical_activity_days_w6 ==5

label values physical_activity_guideline_w6 yesno

label variable physical_activity_guideline_w6 "compliant with gov guidelines for PA, based on self-reported days of PA"

gen physical_activity_anydays_w6 = .
replace physical_activity_anydays_w6 = 1 if physical_activity_days_w6 >=1 & physical_activity_days_w6 <=4
replace  physical_activity_anydays_w6 = 0 if physical_activity_days_w6==5
label values physical_activity_anydays_w6 yesno

label variable physical_activity_anydays_w6 "self-report any days of PA last week"


rename FCSAFD00 area_safety_w6 

gen safe_area_w6 = .
replace safe_area_w6 = 1 if area_safety_w6==1 | area_safety_w6==2
replace safe_area_w6 = 0 if area_safety_w6==3 | area_safety_w6==4

drop area_safety_w6
 
// drop variables relating to spending money
drop FCWMON0A FCWMON0B FCWMON0C FCWMON0D FCWMON0E FCWMON0F FCWMON0G ///
FCWMON0H FCWMON0I FCWMON0J FCWMON0K FCWMON0L FCWMON0M FCWMON0N ///
FCWMON0O FCWMON0P FCWMON0Q FCWMON0R

//drop variables relating to consent to collect contact details
drop FCTUDD0A FCTUDD0B FCTUDD0C FCTUDR00 FCTUDE00 FCTUDF00 /// 
FCTUDS00 FCMPHO00 FCYPEM00


// drop ethnicity variables - take from cm_derived.dta
drop FCETHE00_R20 FCETHW00_R5 FCETHS00_R5 FCETHN00_R5

// activities grid 

drop FCINTROB // entry flag

rename FCCINE00 activity_cinema_w6
rename FCSPOR00 activity_watch_sport_w6
rename FCBAND00 activity_music_w6
rename FCRJOY00 activity_read_w6
rename FCORGA00 activity_youthclub_w6
rename FCMUSM00 activity_museums_w6
rename FCRLSV00 activity_religious_w6

label define activities 0 "Never/almost never" 1 "Once year or less" 2 "Several times year" ///
3 "Once a month" 4 "Once a week" 5 "Most days"

foreach i in activity_* {
	recode `i' (1=5) (2=4) (4=2) (5=1) (6=0) (-9=.) (-8=.) (-1=.)
	label values `i' activities 
}

gen reg_watch_sport_w6 = .
replace reg_watch_sport_w6 = 1 if activity_watch_sport_w6 == 3 | activity_watch_sport_w6 == 4 | activity_watch_sport_w6 == 5
replace reg_watch_sport_w6 = 0 if activity_watch_sport_w6 == 0 | activity_watch_sport_w6 == 1 | activity_watch_sport_w6 == 2

//drop identity & friends flag
drop FCINTROE FCINTROF

//drop languages 
drop FCLANF0A FCLANF0B FCLANF0C FCLANF0D FCLANF0E FCLANF0F FCLANF0G ///
FCLANF0H FCLANF0I FCLANF0K FCLANF0L FCLANF0M FCLANF0O FCLANF0P FCLANF0Q ///
FCLANF0R FCLANF0S FCLANF0T FCLANF0U FCLANF0V FCLANF0W FCLANW00 FCWESM00


//drop religions
drop FCRELE00 FCRELW00 FCRELS00 FCRELN00

/* 
http://eprints.gla.ac.uk/147754/1/147754.pdf
Item responses on seven point scale, ranging from not at all happy to completely happy
Responses summed to provide continuous score from 5 to 20
Higher scores indicate higher life satisfaction
*/


rename FCSCWK00 wellbeing_schoolwork_w6
rename FCWYLK00 wellbeing_looks_w6
rename FCFMLY00 wellbeing_family_w6
rename FCFRNS00 wellbeing_friends_w6
rename FCSCHL00 wellbeing_school_w6
rename FCLIFE00 wellbeing_life_w6

foreach i in wellbeing_* {
	*recode `i' (-9=.) (-8=.) (-1=.) (1=6) (2=5) (3=4) (4=3) (5=2) (6=1) (7=0)
	recode `i' (-9=.) (-8=.) (-1=.) (1=7) (2=6) (3=5) (5=3) (6=2) (7=1)
}


gen tot_life_satisfaction_w6 = wellbeing_schoolwork_w6 + wellbeing_looks_w6 + wellbeing_family_w6 + wellbeing_friends_w6 + wellbeing_school_w6 + wellbeing_life_w6

rename FCSATI00 rosenberg_satisfied_w6 
rename FCGDQL00 rosenberg_good_qualities_w6 
rename FCDOWL00 rosenberg_do_things_well_w6 
rename FCVALU00 rosenberg_person_value_w6 
rename FCGDSF00 rosenberg_feel_good_w6 

/* 
http://eprints.gla.ac.uk/147754/1/147754.pdf
Item responses on four point scale, ranging from strongly disagree to strongly agree
Responses summed to provide continuous score from 5 to 20
Higher scores indicate higher self-esteem
*/

foreach i in rosenberg_* {
	recode `i' (-9=.) (-8=.) (-1=.) (1=4) (2=3) (3=2) (4=1)
}

gen tot_self_esteem_w6 = rosenberg_satisfied_w6 + rosenberg_good_qualities_w6 + rosenberg_do_things_well_w6 + rosenberg_person_value_w6 + rosenberg_feel_good_w6


/* Short Moods and Feelings Questionnaire 
The MFQ is scored by summing together the point values of responses for each item. The response choices and their designated point values are as follows:

"not true" = 0 points
"sometimes true" = 1 point
"true" = 2 points

Higher scores on the MFQ suggest more severe depressive symptoms.

Scores on the short version of the MFQ range from 0 to 26. Scoring a 12 or higher on the short version may indicate the presence of depression in the respondent.
*/

rename FCMDSA00 feelings_miserable_w6
rename FCMDSB00 feelings_enjoy_w6
rename FCMDSC00 feelings_tired_w6
rename FCMDSD00 feelings_restless_w6
rename FCMDSE00 feelings_no_good_w6
rename FCMDSF00 feelings_cried_w6
rename FCMDSG00 feelings_concentration_w6
rename FCMDSH00 feelings_hated_self_w6
rename FCMDSI00 feelings_bad_person_w6
rename FCMDSJ00 feelings_lonely_w6
rename FCMDSK00 feelings_nobody_loved_me_w6
rename FCMDSL00 feelings_not_as_good_w6
rename FCMDSM00 feelings_everything_wrong_w6

foreach i in feelings_* {
	recode `i' (-9=.) (-8=.) (-1=.) (1=0) (2=1) (3=2)
}


gen tot_smfq_w6 = feelings_miserable_w6 + feelings_enjoy_w6 + feelings_tired_w6 + feelings_restless_w6 + feelings_no_good_w6 + ///
feelings_cried_w6 + feelings_concentration_w6 + feelings_hated_self_w6 + feelings_bad_person_w6 + feelings_lonely_w6 + ///
feelings_nobody_loved_me_w6 + feelings_not_as_good_w6 + feelings_everything_wrong_w6





rename FCHARM00 self_harmed_w6
recode self_harmed_w6 (-9=.) (-8=.) (-1=.) (2=0)
label values self_harmed_w6 yesno

// drop aspirations
drop FCCARR00_TR3 FCCARR01_TR3 FCCARR02_TR3 FCCARR03_TR3 FCCARR04_TR3 ///
FCCARR05_TR3 FCCARR06_TR3 FCCARR07_TR3 FCCARR08_TR3 FCCARR09_TR3 ///
FCCARR10_TR3 FCCARR11_TR3

//drop flags
drop FCINTROJ FCOEIT00

//activities
rename FCTVHO00 hours_day_TV_w6 
recode hours_day_TV_w6 (-9=.) (-8=.) (-1=.) (1=0) (2=1) (3=2) (4=3) (5=4) (6=5) (7=6) (8=7)

rename FCCOMH00 hours_day_videogame_w6 
recode hours_day_videogame_w6 (-9=.) (-8=.) (-1=.) (1=0) (2=1) (3=2) (4=3) (5=4) (6=5) (7=6) (8=7)

rename FCCMEX00 own_computer_w6 
recode own_computer_w6 (-8=.) (-1=.) (2=0)

rename FCINTH00 use_internet_w6 
recode use_internet_w6 (-9=.) (-8=.) (-1=.) (1=0) (2=1) (3=2) (4=3) (5=4) (6=5) (7=6) (8=7)

rename FCSOME00 hours_week_socialmedia_w6 
recode hours_week_socialmedia_w6  (-9=.) (-8=.) (-1=.) (1=0) (2=1) (3=2) (4=3) (5=4) (6=5) (7=6) (8=7)

rename FCCYCF00 bike_w6
recode bike_w6  (-9=.) (-8=.) (-1=.) (1=6) (2=5) (3=4) (4=3) (5=2) (6=1) (7=0) (8=0) /* cat 7 and 8 both referred to not using a bike*/

//drop cycle flags
drop FCCYCT00 FCCONF00


//drop moral attitudes 
drop FCINTROC FCROLE00 FCIMWK00 FCPLAB00 FCBTNG00 FCWELK00 ///
FCWHRD00 FCFGHT00 FCSPNT00 FCSTEL00 FCCOPY00

// educational attitudes 

rename FCGDPE00 good_PE_w6
recode good_PE_w6 (-9=.) (-8=.) (-1=.) (1=0) (2=0) (3=1) (4=1)

rename FCENGL00 good_english_w6
recode good_english_w6 (-9=.) (-8=.) (-1=.) (1=0) (2=0) (3=1) (4=1)

rename FCMTHS00 good_maths_w6 
recode good_maths_w6 (-9=.) (-8=.) (-1=.) (1=0) (2=0) (3=1) (4=1)

rename FCSCIE00 good_science_w6
recode good_science_w6 (-9=.) (-8=.) (-1=.) (1=0) (2=0) (3=1) (4=1)

rename FCHWKM00 homework_w6
recode homework_w6 (-9=.) (-8=.) (-1=.) (1=0) (2=1) (3=2) (4=3) (5=4)


rename FCSCBE00 edu_mot_try_best_w6 
rename FCSINT00 edu_mot_scl_interesting_w6 
rename FCSUNH00 edu_mot_scl_unhappy_w6 
rename FCSTIR00 edu_mot_scl_tiring_w6 
rename FCSCWA00 edu_mot_scl_wastetime_w6 
rename FCMNWO00 edu_mot_diff_conc_w6 


foreach i in edu_mot_* {
	recode `i' (-9=.) (-8=.) (-1=.) (1=3) (3=1) (4=0)
}

drop FCINTROD FCWLSH00 FCOPTE00 FCOPWE0A ///
FCOPWE0B FCOPWE0C FCOPWE0D FCHLPC00 FCQTRM00  ///
FCMISB00 FCMISO00 FCTRUA00 FCTRUF00 ///
FCATQL00 FCSTYY00 FCSTYN00 FCSTYU00

//drop handedness 
drop FCHAND00

// family relations

rename FCPHMA00 communicate_mother_digital_w6
rename FCPHPA00 communicate_father_digital_w6

drop FCRLQM00 FCRLQF00 FCQUAM00 FCQUAF00 FCMAAB00 FCCOMO00 FCSEMA00 ///
FCSTMA00 FCPAAB00 FCCOFA00 FCSEFA00 FCSTPA00 FCGRSE00


//friendships  
rename FCPLWE00 outside_weekends_w6
rename FCPLWK00 outside_schoolnight_w6

rename FCNUFR00 close_friends_w6
recode close_friends_w6 (-9=.) (-8=.) (-1=.) (2=0)

drop FCOUTW00 FCOTWI00 FCOTWD00 FCFRSM00 ///
FCFRSS00 FCFRBY00 FCFRGL00 FCFRTH00 FCPEWH00 FCPETR00 FCSTFR0A

//sexual relations 
drop FCBGFR00 FCROMG00 FCROMB00 FCHHND00 FCKISS00 FCCDDL00 FCTUCH00 ///
FCTCHO00 FCTCHP00 FCTCOP00 FCORAL00 FCORLO00 FCSEXX00 FCCONP0A

//risky behaviours 
drop FCINTROG FCSMOK00 FCAGSM00 FCECIG00 FCSMFR00 FCALCD00 FCALAG00 FCALCN00 ///
FCALNF00 FCALFV00 FCAGFV00 FCALFN00 FCDRFN00 FCCANB00 FCOTDR00 FCCANO00 ///
FCDRFR00 FCGAMA00 FCGMBL00 FCGAEM00 FCGAMJ00

//discipline grid
drop FCDIST00 FCDISG00 FCDISP00

//what do if worried
rename FCWRRY0A worried_keeptoself_w6 

rename FCWRRY0B worried_parent_w6 

rename FCWRRY0C worried_sibling_w6 

rename FCWRRY0D worried_friend_w6 

rename FCWRRY0E worried_relative_w6 

rename FCWRRY0F worried_teacher_w6 

rename FCWRRY0G worried_adult_w6

foreach i in worried_* {
	recode `i' (-9=.) (-8=.) (-1=.) 
}


//socialsupport grid

rename FCSAFF00 family_friends_safe_w6
recode family_friends_safe_w6 (-9=.) (-8=.) (-1=.) (1=2) (2=1) (3=0)

rename FCTRSS00 someone_trust_w6
recode someone_trust_w6 (-9=.) (-8=.) (-1=.) (1=2) (2=1) (3=0)

rename FCNCLS00 noone_close_to_w6
recode noone_close_to_w6 (-9=.) (-8=.) (-1=.) (1=2) (2=1) (3=0)

//bullying
drop FCBULB00 FCBULP00 FCHURT00 FCPCKP00 FCCYBU00 FCCYBO00

//victims grid
drop FCVICG00 FCVICA00 FCVICC00 FCVICE00 FCVICF0A

//crime
drop FCSTNT00 FCAWNT00 FCRUDE00 FCRUDN00 FCRUDNCK FCSTOL00 FCSTON00 FCSTONCK ///
FCSPRY00 FCSPRN00 FCSPRNCK FCDAMG00 FCDAMN00 FCDAMNCK FCKNIF00 FCROBH00 ///
FCHITT00 FCWEPN00 FCSTLN00 FCPOLS00 FCCAUT00 FCARES00 FCGANG00 FCHACK00 ///
FCHAKN00 FCHAKNCK FCVIRS00 FCVIRN00

//health

rename FCSLWK00 bed_time_school_w6
rename FCWUWK00 wake_up_time_school_w6
rename FCSLWE00 bed_time_noschool_w6
rename FCWUWE00 wake_up_time_noschool_w6
rename FCSLLN00 time_to_fall_asleep_w6
rename FCSLTR00 awaken_during_sleep_w6


gen sometimes_wake_sleep_w6 = .
replace sometimes_wake_sleep_w6 = 1 if awaken_during_sleep_w6 == 1 | awaken_during_sleep_w6 == 2 | awaken_during_sleep_w6 == 3 | awaken_during_sleep_w6 == 4
replace sometimes_wake_sleep_w6 = 0 if awaken_during_sleep_w6 == 5 | awaken_during_sleep_w6 == 6


drop FCVIRNCK FCINTROH FCBRKN00 FCFRUT00 FCVEGI00 FCBRED00 FCMILK00 FCASWD00 ///
FCSWTD00 FCTKWY00 FCCGHE00 FCGLAS00 FCEYEG00 FCYGLS00 FCHEAR00 FCHAID00 ///
FCEARD00 FCDENY00 FCBRSH00 FCWEGT00 FCEXWT00 FCETLS00 FCLSWT00 FCPUHG00 FCPUBH00 ///
FCPUSK00 FCPUVC00 FCPUFH00 FCPUBR00 FCPUMN00 FCAGMN0A

//risk/patience/trust
rename FCRISK00 risks_willing_w6 
recode risks_willing_w6 (-9=.) (-8=.) (-1=.)

rename FCPTNT00 patience_w6 
recode patience_w6 (-9=.) (-8=.) (-1=.)

rename FCTRST0A trust_w6
recode trust_w6 (-9=.) (-8=.) (-1=.)

//flag 
drop FCINTROI


save "derived\mcs6_cm_interview_clean.dta", replace


// #3 
// clean mcs6_cm_derived.dta

use "source\UKDA-8156-stata_MCS_wave6\stata\stata13\mcs6_cm_derived.dta", clear 

//keep only those in mcs6_included_PID.dta

gen CMrow = "_C1" if FCNUM00 == 1
replace CMrow = "_C2" if FCNUM00 == 2
replace CMrow = "_C3" if FCNUM00 == 3
gen PID = MCSID + "_" + string(FCNUM00) if (FCNUM00 > 0)
replace PID = MCSID + CMrow if (FCNUM00 > 0)

merge 1:1 PID using "derived\mcs6_included_PID.dta"

keep if _merge==3
drop _merge


//drop interview data
drop FCINTM00 FCINTY00 

//drop sex, age - taken from cm_interview
drop FCCSEX00 FCCDBM00 FCCDBY00 FCCAGE00 FCMCS6AG


rename FDCE0600 ethnicity_6cat

rename FDCE0800 ethnicity_8cat
rename FDCE1100 ethnicity_11cat

drop ethnicity_8cat ethnicity_11cat

recode ethnicity_6cat (-9=.) (-8=.) (-1=.)

gen nw_w6=.
replace nw_w6=1 if ethnicity_6cat >=2 & ethnicity_6cat <=6
replace nw_w6=0 if ethnicity_6cat==1

drop ethnicity_6cat


rename FCBMIN6 bmi_w6
replace bmi_w6=. if bmi_w6==-1

// drop school information (school ID, grammar school, data collected)
drop FDSCHL0A FDSCHL0B FCANONSCLID1 FCANONSCLID2 FCGRAM0A FCGRAM0B


// drop cut-off points for defining obesity
drop FCOVWGT6 FCOBESE6 FCUNDWU6 FCOVWTU6 FCOBESU6

rename FCOBFLG6 obese_IOTF_w6
rename FCUK90O6 obese_UK90_w6

recode obese_IOTF_w6 (-1=.)
recode obese_UK90_w6 (-1=.)

rename FCWRDSC cogtest_word_w6
replace cogtest_word_w6=. if cogtest_word_w6==-3 | cogtest_word_w6==-1

drop FCGTOUTCM // test completed flag

rename FCGTTTIME cogtest_time_w6
rename FCGTDELAY cogtest_delay_aversion_w6

rename FCGTDTIME cogtest_delib_time_w6
rename FCGTOPBET cogtest_overall_prop_bet_w6
rename FCGTQOFDM cogtest_qual_dec_making_w6 
rename FCGTRISKA cogtest_risk_adjust_w6 
rename FCGTRISKT cogtest_risk_taking_w6

foreach i in cogtest_time_w6 cogtest_delay_aversion_w6 cogtest_delib_time_w6 cogtest_overall_prop_bet_w6 cogtest_qual_dec_making_w6 cogtest_risk_adjust_w6 cogtest_risk_taking_w6 {
    replace `i'=. if `i'==-9
}


rename FEMOTION sdq_emotion_w6 
rename FCONDUCT sdq_conduct_w6
rename FHYPER sdq_hyper_w6 
rename FPEER sdq_peerprob_w6 
rename FPROSOC sdq_prosoc_w6 
rename FEBDTOT sdq_tot_diff_w6

foreach i in sdq_emotion_w6 sdq_conduct_w6 sdq_hyper_w6 sdq_peerprob_w6 sdq_prosoc_w6 sdq_tot_diff_w6 {
    replace `i' = . if `i'==-1
}



save "derived\mcs6_cm_derived_clean.dta", replace


// CM cog assess
use "source\UKDA-8156-stata_MCS_wave6\stata\stata13\mcs6_cm_cognitive_assessment.dta", clear 



// #4 
// clean mcs6_parent_derived.dta

use "source\UKDA-8156-stata_MCS_wave6\stata\stata13\mcs6_parent_derived.dta", clear 


rename FDRLG00 parent_religion_w6

rename FD07S00 nsssec_w6

rename FDKESSL kessler_parent_w6
recode kessler_parent_w6 (-1=.)

//keep main respondent role
keep if FELIG00==1


keep MCSID FPNUM00  parent_religion_w6 nsssec_w6 kessler_parent_w6


save "derived\mcs6_parent_derived_clean.dta", replace  

// #5
// clean mcs6_parent_cm_interview.dta

use "source\UKDA-8156-stata_MCS_wave6\stata\stata13\mcs6_parent_cm_interview.dta", clear 


/* data contains responses from both parents, so need to keep just one of them */

//keep main respondent role
keep if FELIG00==1


//keep only those in mcs6_included_PID.dta

gen CMrow = "_C1" if FCNUM00 == 1
replace CMrow = "_C2" if FCNUM00 == 2
replace CMrow = "_C3" if FCNUM00 == 3
gen PID = MCSID + "_" + string(FCNUM00) if (FCNUM00 > 0)
replace PID = MCSID + CMrow if (FCNUM00 > 0)

merge 1:1 PID using "derived\mcs6_included_PID.dta"

keep if _merge==3
drop _merge





//drop age, sex - taken from CM interview
drop FCCSEX00 FCCDBM00 FCCDBY00 FCCAGE00


// drop school data
drop FPSTSC00 FPDIFY00 FPNOWH00 FPSTWY00 FPSTWM00 FPSTWERR FPLINTCK FPCHK1CK

rename FPSCTY00 school_fee_paying_w6
recode school_fee_paying_w6 (-1=.) (2=0)
label values school_fee_paying_w6 yesno

// drop reason for fee school attending 
drop FPCHK2CK FPWPRV0A FPWPRV0B FPWPRV0C FPWPRV0D FPWPRV0E FPWPRV0F /// 
FPWPRV0G FPWPRV0H FPWPRV0I FPWPRV0J FPWPRV0K FPWPRV0L FPWPRV0M FPWPRV0N ///
FPWPRV0O FPWPRV0P FPWPRV0Q FPWPRV0R FPWPRV0S FPWPRV0T FPWPRV0U FPWPRV0V

rename FPSCSX00 same_sex_school_w6
recode same_sex_school_w6 (-8=.) (-1=.) (2=0)
label values same_sex_school_w6 yesno

rename FPFTHS00 faith_school_w6
recode faith_school_w6 (-8=.) (-1=.) (1=0) (2=1) (3=1) (4=1) (5=1) (6=1) (7=1)
/*create binary variable, v.small numbers of yes for some religions*/
label values faith_school_w6 yesno

//drop faith school evidence flag, and language in school 
drop FPFHDE00 FPLNWA00 FPLNSC00 FPLNNI00

rename FPSASC00 changed_school_w6
recode changed_school_w6 (-1=.) (1=0) (2=1) (3=.)
label values changed_school_w6 yesno

//drop reasons for moving school 
drop FPCSWH0A FPCSWH0B FPCSWH0C FPCSWH0D FPCSWH0E FPCSWH0F FPCSWH0G ///
FPCSWH0H FPCSWH0I FPCSWH0J FPCSWH0K FPCSWH0L FPCSWH0M FPCSWH0N FPCSWH0O ///
FPCSWH0P FPCSWH0Q FPCSWH0R FPCSWH0S FPCSWH0T FPCSWH0U FPSOTH00 FPNOTH00

rename FPTSUS00 ever_suspended_school_w6
recode ever_suspended_school_w6 (-9=.) (-1=.) (2=0)
label values ever_suspended_school_w6 yesno

rename FPNSUS00 suspensions_total_w6
replace suspensions_total_w6 =. if suspensions_total_w6 <0

rename FPTEXC00 ever_expelled_school_w6
recode ever_expelled_school_w6 (-9=.) (-1=.) (2=0)
label values ever_expelled_school_w6 yesno

rename FPNEXC00 expulsions_total_w6

rename FPSABS00 time_off_school_w6
recode time_off_school_w6 (-9=.) (-1=.) (2=0)
label values time_off_school_w6 yesno

rename FPWABS00 weeks_off_school_w6
replace weeks_off_school_w6 =. if weeks_off_school_w6 <0

//drop reasons for time off 
drop FPRABS00 FPADNH0A FPADNH0B FPADNH0C FPADNH0D FPADNH0E FPADNH0F ///
FPADNH0G FPADNH0H FPADNH0I FPADNH0J FPADNH0K FPADNH0L FPADNH0M FPADNH0N ///
FPADNH0O FPADNH0P FPADNH0Q FPADNH0R FPADNH0S FPCHWSCK

rename FPCSEN00 sen_w6
recode sen_w6 (-1=.) (2=0)
label values sen_w6 yesno

// drop educational support 
drop FPSENS00 FPSNPL00 FPRASN0A FPRASN0B FPRASN0C FPRASN0D /// 
FPRASN0E FPRASN0F FPRASN0G FPRASN0H FPRASN0I FPRASN0J FPRASN0K ///
FPRASN0L FPRASN0M FPRASN0N FPRASN0O FPRASN0P FPRASN0Q FPRASN0R ///
FPRASN0S FPRASN0T FPRASN0U FPRASN0V FPRASN0W FPRASN0X FPRASN0Y ///
FPRASN0Z FPRASN1A FPRASN1B FPRSEN0A FPRSEN0B FPRSEN0C FPRSEN0D FPRSEN0E ///
FPRSEN0F FPRSEN0G FPRSEN0H FPRSEN0I FPRSEN0J FPRSEN0K FPRSEN0L FPRSEN0M ///
FPRSEN0N FPRSEN0O FPRSEN0P FPRSEN0Q FPRSEN0R FPRSEN0S FPRSEN0T FPRSEN0U ///
FPRSEN0V FPRSEN0W FPRSEN0X FPRSEN0Y FPRSEN0Z FPRSEN1A FPRSEN1B

//drop university questions, and extra lessons
drop FPASMI00 FPASLU00 FPASUX0A FPASUX0B FPASUX0C FPASUX0D FPASUX0E FPASUX0F ///
FPASUX0G FPASUX0H FPASUX0I FPASUX0J FPASUX0K FPASUX0L FPASUX0M FPASUX0N ///
FPASUX0O FPASUX0P FPASUX0Q FPASUX0R FPASUX0S FPASUX0T FPASUX0U FPASUX0V ///
FPASUX0W FPASUX0X FPASUX0Y FPASUX0Z FPASUX1A FPINEV00 FPINWE0A FPINWE0B ///
FPINWE0C FPINWE0D FPINWE0E FPINMT00 FPINWH00 FPEXTW0A FPEXTW0B FPEXTW0C ///
FPEXTW0D FPEXTW0E FPEXTU0A FPEXTU0B FPEXTU0C FPEXTU0D FPTUPY00

rename FPTRSC00 active_travel_school_w6 
recode active_travel_school_w6 (-1=.) (1=0) (2=0) (3=0) (4=1) (5=1)


// drop other transport questions
drop FPTRHO00 FPTRDI00 FPTRTI00

// drop free school meals for now - discrepancy between 2 variables //
drop FPSCHD00 FPFREM00 FPELFR00 

// household questions //

rename FPTAIM00 freq_talk_to_CM_w6
recode freq_talk_to_CM_w6 (-8=.) (-1=.) (1=5) (2=4) (4=2) (5=1) (6=0)


rename FPBROW0A own_bedroom_w6
recode own_bedroom_w6 (-1=.) (2=0)

drop FPACHM00 //chores

rename FPWHET00 always_know_where_CM_out_w6 
recode always_know_where_CM_out_w6  (-8=.) (-1=.) (2=0) (3=0) (4=0)

rename FPWHOT00 always_know_who_CM_out_w6 
recode always_know_who_CM_out_w6  (-8=.) (-1=.) (2=0) (3=0) (4=0)

rename FPWHAT0A  always_know_what_CM_out_w6 
recode always_know_what_CM_out_w6  (-8=.) (-1=.) (2=0) (3=0) (4=0)

// already have binary school-fee paying variable - drop school fees
drop FPFEEP00 


// drop health flag 
drop FPINTR00

rename FPCLSI00 longterm_ill_w6
recode longterm_ill_w6 (-8=.) (-1=.) (2=0)
label values longterm_ill_w6 yesno

// individual conditions - low response rates, but potential useful data re mental & physical health 
// rename mental health and behavioural problems, drop rest for now

rename FPCLSM0G mental_health_w6
recode mental_health_w6 (-1=.)

rename FPCLSM0I social_prob_w6
recode social_prob_w6 (-1=.)



drop FPCLSM0A FPCLSM0B FPCLSM0C FPCLSM0D FPCLSM0E FPCLSM0F FPCLSM0H FPCLSM0J ///
FPCLSM0K FPCLSM0L FPCLSM0M FPCLSM0N FPCLSM0O FPCLSM0P FPCLSM0Q FPCLSM0R ///
FPCLSM0S FPCLSM0T FPCLSM0U FPCLSM0V FPCLSM0W FPCLSM0X FPCLSM0Y FPCLSM0Z ///
FPCLSM1A FPCLSM1B FPCLSM1C FPCLSM1D

rename FPCLSL00 illness_limit_activity_w6

rename FPCLTR00 medication_w6

drop FPCLSP00 FPPCRP00 FPREGB00 FPLNPR0A FPLNPR0B FPLNPR0C FPLNPR0D ///
FPLNEVA0 FPLNEVB0 FPLNEVC0 FPASMA00 FPECZM00 FPHAFV00 FPMEAS00 FPCHIC00 ///
FPTUBR00 FPWHOP00 FPADHD00 FPAUTS00 FPMEDA00 FPMDLN00

//drop accident data 
drop FPACCA00 FPCH10CK FPACWT0A FPACWT0B FPACWT0C FPACWT0D FPACWT0E ///
FPACWT0F FPACWT0G FPACWT0H FPACWT0I FPACWT0J FPACWT0K FPACWT0L FPACWT0M ///
FPACWT0N FPACWT0O FPACWT0P FPACWT0Q FPACWT0R FPACWT0S FPACWT0T FPACWT0U ///
FPACWT0V FPACWT0W FPACWT0X FPACWT0Y FPACWT0Z FPACWT1A FPACWT1B FPACWT1C ///
FPACWT1D FPACWT1E FPACWT1F FPACWT1G FPACWT1H FPACWT1I FPACWT1J FPACWT1K ///
FPACWT1L FPACWT1M FPACWT1N FPACWT1O FPACWT1P FPACWT1Q FPACCH00 FPADMA00 FPCH20CK


// drop vaccination data 
drop FPHPVV00 FPHPVY0A FPHPVY0B FPHPVY0C FPHPVY0D FPHPVY0E FPHPVY0F ///
FPHPVY0G FPHPVY0H FPHPVY0I FPHPVY0J FPHPVY0K FPHPVY0L FPHPVY0M FPHPVY0N ///
FPHPVY0O FPHPVY0P FPIMMS0A FPIMMS0B FPIMMS0C FPIMMS0D FPIMMS0E FPIMMS0F ///
FPIMMS0G FPIMMS0H FPIMMS0I FPIMMS0J FPIMMS0K FPIMMS0L FPIMMS0M FPIMMS0N ///
FPIMMS0O FPIMMS0P FPIMMS0Q FPIMMS0R FPIMMS0S FPIMMS0T FPIMMS0U FPIMMS0V ///
FPIMMS0W FPIMMS0X FPIMMS0Y FPIMMS0Z FPIMMS1A


//drop data on parental-child relationship

drop FPSCHC00 FPQARP00 FPEMOT00 FPALAC00 FPALHO00 FPCHTI00 FPCHTN0A FPCHTN0B ///
FPCHTN0C FPCHTN0D FPCHTN0E FPCHTN0F FPCHTN0G FPCHTN0H FPCHTN0I FPSDPF00 ///
FPSDRO00 FPSDHS00 FPSDSR00 FPSDTT00 FPSDSP00 FPSDOR00 FPSDMW00 FPSDHU00 ///
FPSDFS00 FPSDGF00 FPSDFB00 FPSDUD00 FPSDLC00 FPSDDC00 FPSDNC00 FPSDKY00 ///
FPSDOA00 FPSDPB00 FPSDVH00 FPSDST00 FPSDCS00 FPSDGB00 FPSDFE00 FPSDTE00


save "derived\mcs6_parent_cm_interview_clean.dta", replace


// #6. IMD data

use "source\UKDA-8156-stata_MCS_wave6\stata\stata13\mcs_sweep6_imd_e_2004.dta", clear

rename FIMDINCE IMD_income_decile_w6 

gen urban_w6 = .
replace urban_w6 = 1 if FIERURUR == 4 | FIERURUR == 5 
replace urban_w6 = 0 if FIERURUR == 1 | FIERURUR == 2 | FIERURUR == 3 | FIERURUR ==6
label variable urban_w6 "Urban yes/no - urban in in 'less sparse' ONS classification'"

keep MCSID IMD_income_decile_w6 urban_w6

save "derived\mcs_sweep6_imd_e_2004_clean.dta", replace

use "source\UKDA-8156-stata_MCS_wave6\stata\stata13\mcs_sweep6_imd_s_2004.dta", clear

rename FISIMDIN IMD_income_decile_w6 

gen urban_w6 = .
replace urban_w6 = 1 if FISRURUR == 1 | FISRURUR == 2 
replace urban_w6 = 0 if FISRURUR == 3 | FISRURUR == 4 | FISRURUR == 5 | FISRURUR ==6

keep MCSID IMD_income_decile_w6 urban_w6

save "derived\mcs_sweep6_imd_s_2004_clean.dta", replace


use "source\UKDA-8156-stata_MCS_wave6\stata\stata13\mcs_sweep6_imd_w_2004.dta", clear

rename FIWIMDSC IMD_income_decile_w6 

gen urban_w6 = .
replace urban_w6 = 1 if FIWRURUR == 4 | FIWRURUR == 5 
replace urban_w6 = 0 if FIWRURUR == 1 | FIWRURUR == 2 | FIWRURUR == 3 | FIWRURUR ==6

keep MCSID IMD_income_decile_w6 urban_w6

save "derived\mcs_sweep6_imd_w_2004_clean.dta", replace

use "source\UKDA-8156-stata_MCS_wave6\stata\stata13\mcs_sweep6_imd_n_2004.dta", clear

rename FIMDINCN IMD_income_decile_w6 

gen urban_w6=.
replace urban_w6 = 1 if FINRURUR==2
replace urban_w6 = 0 if FINRURUR==1


keep MCSID IMD_income_decile_w6 urban_w6

save "derived\mcs_sweep6_imd_n_2004_clean.dta", replace


log close 
exit
