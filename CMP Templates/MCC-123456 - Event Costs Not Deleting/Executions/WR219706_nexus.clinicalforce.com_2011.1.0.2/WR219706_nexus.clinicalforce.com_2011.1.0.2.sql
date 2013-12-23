/*
--************************************************************************************************
-- Author:			Michael Goldsmith
-- Creation Date:	20d3-09-26
-- Updated by:		
-- Update Date:		
-- Work Request: 	12978
-- AR#:				1-461587169
-- URL: 			heartware-ctms.imedidata.com
--************************************************************************************************
 
--************************************************************************************************
-- Description: The purpose of this script is to delete all event costs where the linked activity
-- definition does not exist within the assigned activity template for the respective study.

-- Keywords: Event Costs, Activity Templates, Cost Generation
--************************************************************************************************
*/

DELETE FROM ec USING drugtrial_def dt
JOIN trigger_control tc ON tc.assigned_obj_id=dt.id and tc.assigned_obj='drugtrial_def' and  tc.data_object='activity'
JOIN event_cost ec ON ec.trigger_control_id=tc.id
LEFT OUTER JOIN(
     /* Find all billable template records per active study */
    SELECT dt.name STUDY, tc.id TRIGGER_CONTROL_ID, aadt.ACTIVITY_DFN_ID
    FROM trigger_control tc
    INNER JOIN drugtrial_def dt ON tc.assigned_obj_id=dt.id and tc.assigned_obj='drugtrial_def' and dt.active='Y'
     JOIN assigned_activity_tmpl aat on aat.assigned_obj_id=dt.id
     JOIN assigned_activity_detail_tmpl aadt on aadt.assigned_activity_tmpl_id=aat.id and aadt.billing_event='Y'
    WHERE tc.data_object='activity'
 )X
 ON X.TRIGGER_CONTROL_ID=ec.trigger_control_id and ec.linked_obj_id=X.ACTIVITY_DFN_ID and ec.linked_obj='activity_dfn'
WHERE dt.active='Y' and X.ACTIVITY_DFN_ID IS NULL

/*
--
-- Expected Results: 760 row(s) affected
--
*/
