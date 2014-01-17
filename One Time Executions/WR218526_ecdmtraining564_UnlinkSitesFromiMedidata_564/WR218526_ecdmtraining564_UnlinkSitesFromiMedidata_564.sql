--********************************************************************************************************
-- Author*:			Jane Goldiner
-- Creation Date:	20 Feb 2013
-- Updated By:		Amit Patel
-- Updated Date:	21 May 2013
-- URL*:			ecdmtraining564.mdsol.com
-- Work Request*:	218526 
-- Rave Version Developed For*:		5.6.4
-- Patch Version Tested Against:	2013.1.0
-- Module*:							Sites, iMedidata
-- DT# (if applicable):				N/A
--********************************************************************************************************
-- Description*:
--	There is an identified duplication of ExternalID on the sites and studies table in Rave and mismatch with iMedidata.
--	This script will clear the ExternalSiteID and UUID which is then repopulated my iMedidata automatically.

-- Keywords: Sites, iMedidata, ExternalID, UUID
--********************************************************************************************************

---------- CREATE BK FOR USE -----------
----------------------------------------

if not exists ( select null from sys.objects where name = 'BK_218526_Sites' and type = 'U' )
begin
create table
	BK_218526_Sites (
		SiteID int,
		ExternalID int,
		ExternalSystemID int,
		UUID varchar(36),
		Updated dateTime,
		BK_Timestamp dateTime
	)
end

if not exists ( select null from sys.objects where name = 'BK_218526_StudySites' and type = 'U' )
begin
create table
	BK_218526_StudySites (
		StudySiteID int,
		ExternalID int,
		ExternalSystemID int,
		UUID varchar(36),
		Updated dateTime,
		BK_Timestamp dateTime
	)
end
go

---------------------------------------- 
------- DECLARE NEEDED VARIABLES -------
----------------------------------------

-- DateTime of change, to be inserted into audits.
DECLARE	@DT dateTime
SET		@DT = GetUTCDate()

-- The particular ID numbers for Sites and StudySites per this URL's reference tables.
DECLARE	@SiteTypeID int,
		@StudySiteTypeID int

		
SET		@SiteTypeID = ( select ObjectTypeID from ObjectTypeR where ObjectName = 'Medidata.Core.Objects.Site' )
SET		@StudySiteTypeID = ( select ObjectTypeID from ObjectTypeR where ObjectName = 'Medidata.Core.Objects.StudySite' )

-- The particular ID number for the Audit SubCategory named 'Updated', per this URL's reference tables.
DECLARE	@ascid_updated int
SET		@ascid_updated = ( select ID from AuditSubCategoryR where Name = 'Updated' )

-- The readable text and system text of the entry into the audit trails, for clearing both ExternalIDs and ExternalSystemIDs.
DECLARE	@auditValueExternalID varchar(2048),
		@auditReadableExternalID varchar(2200),
		@auditValueExternalSystemID varchar(2048),
		@auditReadableExternalSystemID varchar(2200),
		@auditReadableUUID varchar(450)
		
SET		@auditValueExternalID = 'ExternalID|0'		
SET		@auditReadableExternalID = 'Cleared ExternalID (WR 218526)'
SET		@auditValueExternalSystemID = 'ExternalSystemID|0'
SET		@auditReadableExternalSystemID = 'Cleared ExternalSystemID (WR 218526)'


-- Error handling for try/catch.
DECLARE	@error_number int,
		@error_message nvarchar(2000)
SET		@error_number = 0

----------------------------------------
------- SELECT INTO TEMP TABLES --------
----------------------------------------

-- 1.a Looking for Sites with duplicated ExternalIDs

select dbo.fnlocaldefault(siteNameID) SiteName, si.SiteID, si.SiteNumber,
	   si.ExternalID,si.ExternalSystemID,si.UUID, si.siteactive, si.Updated
into #SitesUnlink	
from Sites si 
/*
inner join (	select ExternalID
				from Sites
				where ExternalID > 0 
				group by ExternalID
				having COUNT(externalID)>1 ) dt on dt.ExternalID = si.ExternalID 
*/
where si.externalid in ('33777')
order by ExternalID

-- 2.a Select Study Sites assisgnments associated with the sites to unlink

select distinct ss.StudyID, ss.SiteID, ss.StudySiteID, ss.ExternalID,
				ss.ExternalSystemID, ss.UUID, ss.Updated 
into #SSActive
from studysites ss
inner join #SitesUnlink t on t.SiteID = ss.SiteID 
where ss.ExternalID > 0


----------------------------------------
---------- BEGIN TRANSACTION -----------
----------------------------------------

begin transaction
begin try
----------------------------------------
------ INSERT INTO BACKUP TABLES -------
----------------------------------------

-- Sites
insert into	BK_218526_Sites (	SiteID,ExternalID,ExternalSystemID,UUID,Updated,BK_Timestamp)
select	#SitesUnlink.SiteID,#SitesUnlink.ExternalID,#SitesUnlink.ExternalSystemID,#SitesUnlink.UUID,#SitesUnlink.Updated, @DT
from	#SitesUnlink

-- StudySites
insert into BK_218526_StudySites (StudySiteID, ExternalID, ExternalSystemID, UUID, Updated, BK_Timestamp	)
select 	#SSActive.StudySiteID,	#SSActive.ExternalID,	#SSActive.ExternalSystemID, #SSActive.UUID,	#SSActive.Updated,	@DT
from	#SSActive


----------------------------------------
--------- INSERT INTO AUDITS -----------
----------------------------------------

-- 1 of 4: ExternalSystemID for Sites
insert into	Audits (AuditUserID,
					ObjectID,
					ObjectTypeID,
					AuditSubCategoryID,
					Property,
					Value,
					Readable,
					AuditTime )
select distinct
				-2, -- System User
				#SitesUnlink.SiteID,
				@SiteTypeID,
				@ascid_updated,
				'', -- Property
				@auditValueExternalSystemID,
				@auditReadableExternalSystemID,
				@DT
from #SitesUnlink

-- 2 of 4: ExternalID for Sites
insert into Audits (
					AuditUserID,
					ObjectID,
					ObjectTypeID,
					AuditSubCategoryID,
					Property,
					Value,
					Readable,
					AuditTime
	)
select distinct
			-2, -- System User
			#SitesUnlink.SiteID,
			@SiteTypeID,
			@ascid_updated,
			'', -- Property
			@auditValueExternalID,
			@auditReadableExternalID,
			@DT
from  #SitesUnlink

-- 3 of 4: ExternalSystemID for StudySites
insert into Audits (
					AuditUserID,
					ObjectID,
					ObjectTypeID,
					AuditSubCategoryID,
					Property,
					Value,
					Readable,
					AuditTime			)
select
			-2, -- System User
			#SSActive.StudySiteID,
			@StudySiteTypeID,
			@ascid_updated,
			'', -- Property
			@auditValueExternalSystemID,
			@auditReadableExternalSystemID,
			@DT
from #SSActive

-- 4 of 4: ExternalID for StudySites
insert into	Audits (
					AuditUserID,
					ObjectID,
					ObjectTypeID,
					AuditSubCategoryID,
					Property,
					Value,
					Readable, 
					AuditTime )
select
			-2, -- System User
			#SSActive.StudySiteID,
			@StudySiteTypeID,
			@ascid_updated,
			'', -- Property
			@auditValueExternalID,
			@auditReadableExternalID,
			@DT
from #SSActive


----------------------------------------
--------------- UPDATE -----------------
----------------------------------------

-- Sites
update Sites
set	Sites.ExternalID = 0, 
	Sites.ExternalSystemID = 0, 
	Sites.UUID = NEWID(),
	Sites.Updated = @DT
from Sites
inner join #SitesUnlink on #SitesUnlink.SiteID = Sites.SiteID

-- StudySites
update 	StudySites
set	StudySites.ExternalID = 0, 
	StudySites.ExternalSystemID = 0, 
	StudySites.UUID = NEWID(),
	StudySites.Updated = @DT
from StudySites
inner join #SSActive on #SSActive.StudySiteID = StudySites.StudySiteID

------------------------------------------
------------ CLOSE TRANSACTION -----------
------------------------------------------

end try

begin catch
	select @error_number = error_number()
	select @error_message = error_message()
end catch

if @error_number = 0
	begin
		commit transaction
	end
else
	begin
		rollback transaction
		print @error_message
	end

----------------------------------------
--------- OUTPUTS FOR REVIEW -----------
----------------------------------------
--Sites
select
	dbo.fnlocaldefault(Sites.SiteNameID) as 'SiteName',
	Sites.SiteID,
	Sites.ExternalID as 'NewExternalID',
	#SitesUnlink.ExternalID as 'OldExternalID',
	Sites.ExternalSystemID as 'NewExternalSystemID',
	#SitesUnlink.ExternalSystemID as 'OldExternalSystemID',
	Sites.UUID as 'New UUID',
	#SitesUnlink.uuid as 'Old UUID',
	Sites.Updated as 'NewUpdated',
	#SitesUnlink.Updated as 'OldUpdated'
from	Sites
	inner join #SitesUnlink on #SitesUnlink.SiteID = Sites.SiteID

--studySites
select
	StudySites.SiteID,
	StudySites.StudySiteID,
	StudySites.ExternalID as 'NewExternalID',
	#SSActive.ExternalID as 'OldExternalID',
	StudySites.ExternalSystemID as 'NewExternalSystemID',
	#SSActive.ExternalSystemID as 'OldExternalSystemID',
	StudySites.UUID as 'New UUID',
	#SSActive.UUID as 'Old UUID',
	StudySites.Updated as 'NewUpdated',
	#SSActive.Updated as 'OldUpdated'
from StudySites
	inner join #SSActive on #SSActive.StudySiteID = StudySites.StudySiteID

-------------------------------------

--clear up
drop table #SSActive
drop table #SitesUnlink
