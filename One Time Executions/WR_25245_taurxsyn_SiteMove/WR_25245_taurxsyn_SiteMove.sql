/*******************************************************************************************************
-- Author*:							Alex Tierney
-- Creation Date:					January 08, 2013
-- Rave Version Developed For*:		5.6.5
-- Patch Version Tested Against:	2013.2.0+
-- Module*:							Sites, iMedidata
-- WR#:								25245
-- DT# (if applicable):				N/A
--********************************************************************************************************
--********************************************************************************************************
-- Script will take the below steps.  Note step 2 and 5 are used to avoid a FK constraint.  Site 314 
-- will end as active and connected to iMedi.  Site 247 will no longer be connected to iMedidata.  Studysites
-- originally on 247 will move to 314 and vice versa


1) 314 study sites, removal external details
2) 314 study sites move to non in use siteID
3) activate site 314
4) 247 study sites to 314 site
5) 314 study sites from other siteID to 247, remove studysitenumber as well
6) inactivate all userstudysites for study sites in question
7) scramble sitenubmer and uuid for site 247 

-- Script is needed here as alterations to StudySites linked to iMedidata are no longer allowed in 2013.2+
********************************************************************************************************/
----------------------------------------
---------- CREATE BK FOR USE -----------
----------------------------------------

if not exists ( select null from sys.objects where name = 'BK_WR_25245_StudySites' and type = 'U' )
begin
create table
	BK_WR_25245_StudySites 
	(
	[StudySiteID][int],
	[StudyID][int],
	[SiteID][int],
	[Created][datetime],
	[Updated][datetime],
	[CRFVersionID][int],
	[StudySiteActive][bit],
	[EnrollmentCap][int],
	[EnrollmentTarget][int],
	[ServerSyncDate][datetime],
	[Deleted][bit],
	[IsDDE][bit],
	[StudySiteNumber][varchar](20),
	[IsUserDeactivated][bit],
	[DefaultLabType][int],
	[AllowUnitsOnly][bit],
	[ExternalID][int],
	[ExternalSystemID][int],
	[LastExternalUpdateDate][datetime],
	[UUID][varchar](36),
	[ExecutionDate] [datetime]
	)
end

if not exists ( select null from sys.objects where name = 'BK_WR_25245_Sites' and type = 'U' )
begin
create table
	BK_WR_25245_Sites 
	(	
	[SiteID] [int] ,
	[SiteNumber] [nvarchar](50) ,
	[SiteActive] [bit],
	[Updated] [datetime],
	[ExternalID] [int],
	[AddressLine1] [nvarchar](255),
	[AddressLine2] [nvarchar](255),
	[AddressLine3] [nvarchar](255),
	[City] [nvarchar](255),
	[State] [nvarchar](255),
	[PostalCode] [nvarchar](50),
	[Country] [nvarchar](255),
	[Telephone] [nvarchar](32),
	[Fax] [nvarchar](32) ,
	[OID] [varchar](50) ,
	[Created] [datetime]  ,
	[ServerSyncDate] [datetime] ,
	[SiteGroupID] [int] ,
	[SiteNameID] [int]  ,
	[ExternalSystemID] [int]  ,
	[LastExternalUpdateDate] [datetime] ,
	[eTag] [varchar](500) ,
	[UUID] [varchar](36),
	[ExecutionDate] [datetime]
	)
end

if not exists ( select null from sys.objects where name = 'BK_WR_25245_UserStudySites' and type = 'U' )
begin
create table
	BK_WR_25245_UserStudySites 
	(
	[UserStudySitesID] [int],
	[UserID] [int],
	[StudySiteID] [int],
	[IsUserStudySiteActive] [bit],
	[Created] [datetime],
	[Updated] [datetime],
	[ServerSyncDate] [datetime] ,
	[UUID] [varchar](36),
	[LastExternalUpdateDate] [datetime],
	[ExecutionDate] [datetime]
	)
end

go
---------------------------------------- 
------- DECLARE NEEDED VARIABLES -------
----------------------------------------
DECLARE	@DT dateTime
SET		@DT = GetUTCDate()
DECLARE	@StudySiteTypeID int
SET		@StudySiteTypeID = ( select ObjectTypeID from ObjectTypeR where ObjectName = 'Medidata.Core.Objects.StudySite' )
DECLARE	@SiteTypeID int
SET		@SiteTypeID = ( select ObjectTypeID from ObjectTypeR where ObjectName = 'Medidata.Core.Objects.Site' )
DECLARE @UserTypeID int
SET		@UserTypeID = ( select ObjectTypeID from ObjectTypeR where ObjectName = 'Medidata.Core.Objects.User' )
DECLARE	@ascid_updated int
SET		@ascid_updated = ( select ID from AuditSubCategoryR where Name = 'Updated' )


declare @TestSite7 int
set		@TestSite7 = (select siteID from sites si where dbo.fnlocaldefault(si.sitenameID) = 'Syn Batch Uploader Test Site #98' and si.siteID = 7)
declare	@Target314 int
set 	@Target314 = (select siteID from sites si where dbo.fnlocaldefault(si.sitenameID) = '240 - Cognition Health Ltd' and si.siteID = 314)
declare	@Source247 int
set 	@Source247 = (select siteID from sites si where dbo.fnlocaldefault(si.sitenameID) = '240 - Cognition Health Ltd' and si.siteID = 247)


-- Error handling for try/catch.
DECLARE	@error_number int,
		@error_message nvarchar(2000)
SET		@error_number = 0

----------------------------------------
---------- BEGIN TRANSACTION -----------
----------------------------------------
begin transaction
begin try

----------------------------------------
------- SELECT INTO TEMP TABLES --------
----------------------------------------
select 
	 dbo.fnlocaldefault(si.sitenameID) SiteName
	,ss.siteID 
	,ss.studysiteID 
	,ss.ExternalID SourceExternalID
into #SitesInQuestion
from sites si 
	join studysites ss
	on ss.siteID = si.siteID
where 1=1
	and ss.siteID in (@Source247,@Target314)



----------------------------------------
------ INSERT INTO BACKUP TABLES -------
----------------------------------------
insert into
	BK_WR_25245_UserStudySites
select distinct 
	uss.UserStudySitesID,uss.UserID,uss.StudySiteID,uss.IsUserStudySiteActive,uss.Created,uss.Updated,uss.ServerSyncDate,uss.UUID,uss.LastExternalUpdateDate,@DT
from userstudysites uss
	join #SitesInQuestion xx 
	on  uss.StudysiteID = xx.studysiteID

insert into
	BK_WR_25245_Sites 
select distinct
	si.SiteID  ,si.SiteNumber  ,si.SiteActive ,si.	Updated ,si.ExternalID ,si.AddressLine1 ,si.AddressLine2 ,si.AddressLine3 ,si.City ,si.State ,si.PostalCode ,si.Country ,si.Telephone ,si.Fax  ,si.OID  ,si.Created   ,si.ServerSyncDate  ,si.SiteGroupID ,si.SiteNameID  ,si.ExternalSystemID ,si.LastExternalUpdateDate ,si.eTag ,si.UUID ,@DT
from sites si
	join #SitesInQuestion xx 
	on xx.siteID = si.siteID
	
insert into
	BK_WR_25245_StudySites
select distinct
	ss.StudySiteID,ss.StudyID,ss.SiteID,ss.Created,ss.Updated,ss.CRFVersionID,ss.StudySiteActive,ss.EnrollmentCap,ss.EnrollmentTarget,ss.ServerSyncDate,ss.Deleted,ss.IsDDE,ss.StudySiteNumber,ss.IsUserDeactivated,ss.DefaultLabType,ss.AllowUnitsOnly,ss.ExternalID,ss.ExternalSystemID,ss.LastExternalUpdateDate,ss.UUID,@DT
from StudySites ss
	join #SitesInQuestion xx 
	on  ss.StudysiteID = xx.studysiteID
	 
----------------------------------------
--------- INSERT INTO AUDITS -----------
----------------------------------------
--audit action 1,2 and 5
insert into audits (Property, Value, Readable, AuditUserID, AuditTime, ObjectID, ObjectTypeid, auditsubcategoryid)
select distinct '', '', 'StudySite moved to correct SiteID and disconnected from iMedidata as part of corrective action with iMedidata Site Sync. (WR 25245)',  -2, @DT, ss.StudySiteID, @StudySiteTypeID, @ASCID_Updated
from StudySites ss
	join #SitesInQuestion xx 
	on  ss.StudySiteID = xx.StudySiteID
where 1=1
	and xx.SiteID = @Target314

--action 3 and 7
insert into audits (Property, Value, Readable, AuditUserID, AuditTime, ObjectID, ObjectTypeid, auditsubcategoryid)
select distinct '', '', 'Site updated as part of corrective action with iMedidata Site Sync. (WR 25245)',  -2, @DT, si.siteID, @SiteTypeID, @ASCID_Updated
from sites si
	join #SitesInQuestion xx 
	on xx.siteID = si.siteID


--audit action 4 
insert into audits (Property, Value, Readable, AuditUserID, AuditTime, ObjectID, ObjectTypeid, auditsubcategoryid)
select distinct '', '', 'StudySite moved to correct SiteID as part of corrective action with iMedidata Site Sync. (WR 25245)',  -2, @DT, ss.StudySiteID, @StudySiteTypeID, @ASCID_Updated
from StudySites ss
	join #SitesInQuestion xx 
	on  ss.StudySiteID = xx.StudySiteID
where 1=1
	and xx.SiteID = @Source247 

--audit action 6
insert into audits (Property, Value, Readable, AuditUserID, AuditTime, ObjectID, ObjectTypeid, auditsubcategoryid)
select distinct '', '', 'User removed from StudySiteID '+cast(uss.studysiteID as nvarchar(20))+' to allow for corrective action with iMedidata Site Sync. (WR 25245)',  -2, @DT, uss.UserID, @UserTypeID, @ASCID_Updated
from userstudysites uss
	join #SitesInQuestion xx 
	on  uss.StudysiteID = xx.studysiteID

----------------------------------------
------------UPDATE/DELETE---------------
----------------------------------------
update ss --actions 1 and 2
set ss.ExternalID = 0, ss.externalsystemID = 0, ss.uuid = NEWID(), ss.Updated = @DT, ss.siteID = @TestSite7
from StudySites ss
	join #SitesInQuestion xx 
	on  ss.StudySiteID = xx.StudySiteID
where 1=1
	and xx.SiteID = @Target314

update si --action 3
set si.siteactive =1 , si.Updated = @DT
from sites si
	join #SitesInQuestion xx 
	on xx.siteID = si.siteID
	and si.siteactive = 0
	
update ss --actions 4
set ss.siteID = @Target314, ss.updated = @DT
from StudySites ss
	join #SitesInQuestion xx 
	on  ss.StudySiteID = xx.StudySiteID
where 1=1
	and xx.SiteID = @Source247 


update ss --actions 5
set ss.siteID = @Source247, ss.studysitenumber = ''
from StudySites ss
	join #SitesInQuestion xx 
	on  ss.StudySiteID = xx.StudySiteID
where 1=1
	and ss.SiteID = @TestSite7
	
update uss --action 6
set uss.IsUserStudySiteActive = 0, uss.updated = @DT
from userstudysites uss
	join #SitesInQuestion xx 
	on  uss.StudysiteID = xx.studysiteID

update si --action 7
set si.sitenumber ='DNE_'+cast(NEWID() as nvarchar(36)), si.Updated = @DT, si.uuid =NEWID()
from sites si
	join #SitesInQuestion xx 
	on xx.siteID = si.siteID
where 1=1
	and si.siteID = @Source247
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
		-- print @error_message
	end
else
	begin
		rollback transaction
		print @error_message
	end

----------------------------------------
--------- OUTPUTS FOR REVIEW -----------
----------------------------------------
select 
'action taken-->' as info, 
readable Action, 
ObjectName as ObjectType,
ObjectID, 
us.login UserLogin,
us.email UserEmail
from vaudits v
join objecttypeR ob on ob.objecttypeID = v.objecttypeID
left join users us on us.userID = v.objectID and ob.objectname = 'Medidata.Core.Objects.User'
where v.audittime = @DT and v.locale ='eng'
order by v.objecttypeID

select
dbo.fnlocaldefault(ProjectName) Project,
dbo.fnlocaldefault(environmentnameID) Env,
dbo.fnlocaldefault(sitenameID) Site,
ss.StudySiteID,
ss.siteID NewSiteID,
bk.siteID OldSiteID,
ss.ExternalID NewExternalID,
bk.ExternalID OldExternalID,
si.SiteActive CurrentSiteActive,
si.SiteNumber CurrentSiteNumber,
ss.studysitenumber Newstudysitenumber,
bk.studysitenumber Oldstudysitenumber,
count(subjectID) CurrentSubjectCount
from projects pr
join studies st
	on st.projectid = pr.projectid
left join studysites ss
	on ss.studyid = st.studyid
join sites si
	on si.siteid = ss.siteid
join BK_WR_25245_StudySites bk
	on bk.studysiteID = ss.studysiteID
left join subjects su 
	on su.studysiteID = ss.studysiteID
group by dbo.fnlocaldefault(pr.projectname),
	dbo.fnLocalDefault(st.environmentnameid) ,
	dbo.fnlocaldefault(si.sitenameid),
	ss.StudySiteID,
	ss.SiteID,
	bk.siteID,
	ss.externalid,
	bk.ExternalID,
	si.siteactive,
	si.sitenumber,
	ss.studysitenumber,
	bk.studysitenumber
order by ss.siteID


drop table #SitesInQuestion
