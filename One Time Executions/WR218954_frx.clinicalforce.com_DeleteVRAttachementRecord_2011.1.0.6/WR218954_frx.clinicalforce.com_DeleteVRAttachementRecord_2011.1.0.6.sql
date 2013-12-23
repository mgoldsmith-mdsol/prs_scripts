/*
--************************************************************************************************
-- Author:			Michael Goldsmith
-- Creation Date:	2013-05-24
-- Updated by:		
-- Update Date:		
-- Work Request: 	218954
-- AR#:				1-447497136
-- URL: 			frx.clinicalforce.com
--************************************************************************************************
 
--************************************************************************************************
-- Description: The purpose of this script is to delete the record in the attachments table for a
-- given visit report, allowing the workflow rule 'VISIT-REPORT-LOCKED-MISSING-ATTACHMENT' to be
-- run and regenerate the visit report.

-- Keywords: Visit Report, Attachment, PDF, Corrupt File
--************************************************************************************************
*/	

DELETE FROM f 
USING attachments f
INNER JOIN visit_report vr ON f.assoc_obj='visit_report' AND f.assoc_obj_id=vr.id
INNER JOIN site_def s ON vr.assoc_obj='site_def' AND vr.assoc_obj_id=s.id
INNER JOIN drugtrial_def d ON d.id=s.drugtrial_id
INNER JOIN activity a ON a.id=vr.activity_id
WHERE d.name='LAC-MD-31'
AND s.name='1153'
AND a.name='IMV 11'

/*
--
-- Expected Results: 1 row(s) affected
--
*/

/*
--************************************************************************************************
-- Before execution:

> SELECT f.*
FROM attachments f
INNER JOIN visit_report vr ON f.assoc_obj='visit_report' AND f.assoc_obj_id=vr.id
INNER JOIN site_def s ON vr.assoc_obj='site_def' AND vr.assoc_obj_id=s.id
INNER JOIN drugtrial_def d ON d.id=s.drugtrial_id
INNER JOIN activity a ON a.id=vr.activity_id
WHERE d.name='LAC-MD-31'
AND s.name='1153'
AND a.name='IMV 11';

+ -------- + ----------------- + -------------- + ---------- + ----------- + ----------------- + ------------- + ----------------------------------------------------------- + ------------ + --------- + --------- + ---------------- + ------------------ + -------------------------- + -------------- + ------------ + --------- + ------------- + -------------- + ---------------------- + ------------------------ + ---------------- + -------------------- + ------------------ + ----------- + ----------------- + ------------- + ------------------- + ------------------- + ---------- + ---------------- + --------------------- + -------------------- +
| ID       | ASSOC_OBJ_ID      | ASSOC_OBJ      | OWNER      | LOCKED      | LOCKED_BY_ID      | FILENAME      | SAVED_AS                                                    | VERSION      | FKEY      | ITEM      | IS_UPLOADED      | IS_DOWNLOADED      | FILE_LAST_UPDATE_DATE      | FILE_DATA      | COUNTRY      | TYPE      | CATEGORY      | GROUP_REF      | DELTA_RESOURCE_ID      | CREATED_RESOURCE_ID      | DESCRIPTION      | LAST_UPDT_BY_ID      | CREATED_BY_ID      | ACTIVE      | ARCHIVE_FLAG      | DEL_FLAG      | CREATE_DATE         | USER_TIME_ZONE      | TZ_ID      | UPDATE_DATE      | AUTO_UPDATE_DATE      | AUTO_UPDATE_SRC      |
+ -------- + ----------------- + -------------- + ---------- + ----------- + ----------------- + ------------- + ----------------------------------------------------------- + ------------ + --------- + --------- + ---------------- + ------------------ + -------------------------- + -------------- + ------------ + --------- + ------------- + -------------- + ---------------------- + ------------------------ + ---------------- + -------------------- + ------------------ + ----------- + ----------------- + ------------- + ------------------- + ------------------- + ---------- + ---------------- + --------------------- + -------------------- +
| 27380589 | 26344687          | visit_report   | system     | Y           |                   | IMV 11.pdf    | visit_report-26344687-20130327-160513000985-6898-IMV 11.pdf |              | 0         |           | N                | N                  |                            |                |              |           |               |                |                        |                          |                  |                      |                    | Y           | N                 | N             | 2013-03-27 16:05:14 | 0                   |            |                  |                       |                      |
+ -------- + ----------------- + -------------- + ---------- + ----------- + ----------------- + ------------- + ----------------------------------------------------------- + ------------ + --------- + --------- + ---------------- + ------------------ + -------------------------- + -------------- + ------------ + --------- + ------------- + -------------- + ---------------------- + ------------------------ + ---------------- + -------------------- + ------------------ + ----------- + ----------------- + ------------- + ------------------- + ------------------- + ---------- + ---------------- + --------------------- + -------------------- +
1 rows

--************************************************************************************************
-- After execution expected results:

> SELECT f.*
FROM attachments f
INNER JOIN visit_report vr ON f.assoc_obj='visit_report' AND f.assoc_obj_id=vr.id
INNER JOIN site_def s ON vr.assoc_obj='site_def' AND vr.assoc_obj_id=s.id
INNER JOIN drugtrial_def d ON d.id=s.drugtrial_id
INNER JOIN activity a ON a.id=vr.activity_id
WHERE d.name='LAC-MD-31'
AND s.name='1153'
AND a.name='IMV 11';

0 row(s) returned

--************************************************************************************************
*/
