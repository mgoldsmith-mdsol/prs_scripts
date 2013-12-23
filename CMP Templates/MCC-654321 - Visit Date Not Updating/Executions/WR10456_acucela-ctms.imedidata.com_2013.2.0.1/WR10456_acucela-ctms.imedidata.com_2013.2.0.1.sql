/*
--************************************************************************************************
-- Author:			Michael Goldsmith
-- Creation Date:	2013-09-04
-- Updated by:		
-- Update Date:		
-- Work Request: 	10236s
-- URL: 			aptivsolutions-ctms.imedidata.com
--************************************************************************************************
 
--************************************************************************************************
-- Description: The purpose of this script is to correct the visit date and submission
-- deadline for study: 'Pioneer Pivotal Trial', Site: '012'. 

-- Per Nick Cariato @ Aptiv: 
-- "... a previous CRA accidently put the visit date in system for the PSV as 07May2014 and should
-- have been 07May2013."

-- Keywords: Visit Report, Attachment, PDF, Visit Date, Submission Deadline
--************************************************************************************************
*/

/*
 * Retreive initial values
*/
select vr.ID AS "visit_report_id"
    , vr.VISIT_DATE
    , rs.id AS "report_status_id"
    , rs.submission_deadline
    , vr.CRA_ID
    ,(select id from attachments where assoc_obj='visit_report' and assoc_obj_id=vr.id and active='Y' and owner='system' and fkey=0 limit 1) as ATTACHMENT_ID 
from drugtrial_def dt
inner JOIN site_def ao ON ao.drugtrial_id=dt.id and dt.active='Y'
INNER JOIN visit_report vr ON vr.assoc_obj_id=ao.id
left outer join report_status rs on vr.id=rs.assoc_obj_id and rs.assoc_obj='visit_report' and rs.active_version='Y' 
WHERE vr.assoc_obj='site_def'
AND ao.DRUGTRIAL_ID=271519
AND vr.ASSOC_OBJ_ID=325984
AND vr.ID=335025;

/* Expected results:
--  cra_id  visit_report_id    VISIT_DATE             report_status_id   submission_deadline    ATTACHMENT_ID
--  236715  335025             05/07/2014 00:00:00    335026             05/28/2014 00:00:00    341767
*/

/* 
-- Delete attachment record 
*/
DELETE FROM attachments WHERE id=341767;

INSERT INTO delete_log(DEL_ID, TARGET, RESOURCE_ID, IP_ADDRESS, DEL_SQL, ENTRY_DATE, OLC_COMPATIBLE, ARCHIVE_FLAG, DEL_FLAG, CREATE_DATE, USER_TIME_ZONE, TZ_ID, UPDATE_DATE, AUTO_UPDATE_DATE, AUTO_UPDATE_SRC)
VALUES (NULL, 'attachments: 341767', 236715, NULL, 'delete from attachments where id=341767', CURRENT_TIMESTAMP, 'Y', 'N', 'N', CURRENT_TIMESTAMP, NULL, NULL, NULL, NULL, 'CMP: AR # 1-453333429');

/* 
-- Update visit date
*/
UPDATE visit_report SET VISIT_DATE='05/07/2014 00:00:00', LAST_UPDT_BY_ID=236715, UPDATE_DATE=CURRENT_TIMESTAMP WHERE id=335025;

INSERT INTO history(DEL_ID, ROW_ID, TARGET, IP_ADDRESS, RESOURCE_ID, NOTES, ENTRY_DATE, ARCHIVE_FLAG, DEL_FLAG, CREATE_DATE, USER_TIME_ZONE, TZ_ID, UPDATE_DATE, AUTO_UPDATE_DATE, AUTO_UPDATE_SRC)
VALUES (NULL, 335025, 'visit_report', NULL, 236715, 'UPDATE visit_report SET VISIT_DATE=''05/07/2013 00:00:00'', LAST_UPDT_BY_ID=236715, UPDATE_DATE=CURRENT_TIMESTAMP WHERE id=335025', CURRENT_TIMESTAMP, 'N', 'N', CURRENT_TIMESTAMP, NULL, NULL, NULL, NULL, 'CMP: AR # 1-453333429');


/* 
-- Update submission deadline
*/
UPDATE report_status SET submission_deadline='05/28/2013 00:00:00', LAST_UPDT_BY_ID=236715, UPDATE_DATE=CURRENT_TIMESTAMP WHERE id=335026;

INSERT INTO history(DEL_ID, ROW_ID, TARGET, IP_ADDRESS, RESOURCE_ID, NOTES, ENTRY_DATE, ARCHIVE_FLAG, DEL_FLAG, CREATE_DATE, USER_TIME_ZONE, TZ_ID, UPDATE_DATE, AUTO_UPDATE_DATE, AUTO_UPDATE_SRC)
VALUES (NULL, 335026, 'report_status', NULL, 236715, 'UPDATE report_status SET submission_deadline=''05/28/2013 00:00:00'', LAST_UPDT_BY_ID=236715, UPDATE_DATE=CURRENT_TIMESTAMP WHERE id=335026', CURRENT_TIMESTAMP, 'N', 'N', CURRENT_TIMESTAMP, NULL, NULL, NULL, NULL, 'CMP: AR # 1-453333429');

/*
* Return expected results to confirm successful
*/
select vr.ID AS "visit_report_id"
    , vr.VISIT_DATE
    , rs.id AS "report_status_id"
    , rs.submission_deadline
    , vr.CRA_ID
    ,(select id from attachments where assoc_obj='visit_report' and assoc_obj_id=vr.id and active='Y' and owner='system' and fkey=0 limit 1) as ATTACHMENT_ID 
from drugtrial_def dt
inner JOIN site_def ao ON ao.drugtrial_id=dt.id and dt.active='Y'
INNER JOIN visit_report vr ON vr.assoc_obj_id=ao.id
left outer join report_status rs on vr.id=rs.assoc_obj_id and rs.assoc_obj='visit_report' and rs.active_version='Y' 
WHERE vr.assoc_obj='site_def'
AND ao.DRUGTRIAL_ID=271519
AND vr.ASSOC_OBJ_ID=325984
AND vr.ID=335025;

/* Expected results:
--  cra_id  visit_report_id   VISIT_DATE              report_status_id    submission_deadline      ATTACHMENT_ID
--  236715  335025            05/07/2013 00:00:00     335026              05/28/2013 00:00:00      NULL
*/