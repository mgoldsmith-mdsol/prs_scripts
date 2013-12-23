/* 
 * Author:	Michael Goldsmith
 * Date:	2013-FEB-27
 *
 * Site:	Novonordisk PROD
 * URL:		novonordisk.clinicalforce.com
 * AR#:		1-434662348
 * WR#:		207315  
 *
 */
	
/*
> select tag, value, display from dropdown_lookup
where (tag='accountingSubCode' and display='Investigator Fee-Ongoing')
 or  (tag='spendPurpose' and display='Bona Fide Clinical Trial - Gross Compensation')
 or  (tag='spendPurposeOther' and display='Clinical Trial Visit Fees')
 or  (tag='natureOfPayment' and display='Compensation for Research Project')

+ ----------------- + ---------- + ------------------------------------------------ +
| tag               | value      | display                                          |
+ ----------------- + ---------- + ------------------------------------------------ +
| accountingSubCode | 3          | Investigator Fee-Ongoing                         |
| natureOfPayment   | 40         | Compensation for Research Project                |
| spendPurpose      | 5          | Bona Fide Clinical Trial - Gross Compensation    |
| spendPurposeOther | 20         | Clinical Trial Visit Fees                        |
+ ----------------- + ---------- + ------------------------------------------------ +
4 rows

Per Alice Cheung (PM):
Novo has gotten back to me on the list of cost records with missing SPEND_PURPOSE and what the fields should be populated with.  
·         Account Sub-Code – Investigator Fees-Ongoing [accountingSubCode, 3 -> "Investigator Fee-Ongoing"]

·         Spend Purpose:  Bonafide Clinical Trial-Gross Compensation [spendPurpose, 5 -> "Bona Fide Clinical Trial - Gross Compensation"]

·         Spend Secondary Purpose: Clinical Trial Visit Fees [spendPurposeOther, 20 -> "Clinical Trial Visit Fees"]

·         Nature of Payment:  Compensation for Research Project [natureOfPayment, 40 -> "Compensation for Research Project"]



*/

UPDATE cost c
INNER JOIN activity a ON c.assoc_obj='activity' AND a.id=c.assoc_obj_id
INNER JOIN subject_def s ON a.assoc_obj='subject_def' AND s.id=a.assoc_obj_id
SET c.accounting_sub_code=3
	, c.nature_of_payment=40
	, c.spend_purpose=5
	, c.spend_purpose_other=20
WHERE c.spend_purpose IS NULL

/*
 * Expected results: 312 record(s) affected
 */
 
 
 /*
  * FOR TESTER: 
  *
  * The below query should yield 0 results when executed after UPDATE script above
  *
  
SELECT *
FROM cost c
INNER JOIN activity a ON c.assoc_obj='activity' AND a.id=c.assoc_obj_id
INNER JOIN subject_def s ON a.assoc_obj='subject_def' AND s.id=a.assoc_obj_id
WHERE c.spend_purpose IS NULL

 */
