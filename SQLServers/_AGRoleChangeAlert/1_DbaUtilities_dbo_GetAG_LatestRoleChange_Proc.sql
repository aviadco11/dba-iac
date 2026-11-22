USE [DBAUtilities]
GO
/****** Object:  StoredProcedure [dbo].[GetAG_LatestRoleChange]    Script
Date: 5/6/2022 10:39:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




create or alter  procedure [dbo].[GetAG_LatestRoleChange]( @pMailProfile
varchar(64) = 'CRB EXCH'
--,@pEmail VARCHAR(1000) = '<<email>>;') --<<email>>;<<email>>'')
  ,@pEmail varchar(1000) = '<<email>>')

as
 ----create job that only runs when the Ag Role change that uses the code
below.
begin
--declare @pMailProfile VARCHAR(64) = 'CRB EXCH'
--declare @pEmail VARCHAR(1000) = '<<email>>'
declare @vInstance varchar(64);
declare @body1 nvarchar(max)


set nocount on
   set @vInstance = @@servername;
   declare @vSubject varchar(100) = 'AG Role Change Alert '+@vInstance;

   ---- instructions
   set @body1='<H3> The '+@vInstance+' AG Role Change Occured.</H3>';
   set @body1+='<H5>*Listing all role changes within the last 60
minutes</H5>';
   ---- table attributes
   set @body1=@body1+'<table border="2" cellspacing="2" cellpadding="2">';
   ---- column headers
   set @body1=@body1+'<tbody align="left" style="font-family:Arial;
font-size:11">
  <TR>
<TH>TimeStamp</TH>
<TH>Availability Group Name</TH>
<TH style="background-color:#FFFFBD">Changed State</TH>
<TH>Databases</TH>
</TR>
</tbody>';


Drop table if exists #AlwaysOnHealth;
Drop table if exists #AlwaysOnHealth2;

DECLARE @FileName NVARCHAR(4000)
SELECT @FileName =
target_data.value('(EventFileTarget/File/@name)[1]','nvarchar(4000)')
FROM (
SELECT
CAST(target_data AS XML) target_data
FROM sys.dm_xe_sessions s
JOIN sys.dm_xe_session_targets t
ON s.address = t.event_session_address
WHERE s.name = N'AlwaysOn_health'
) ft

 SELECT
XEData.value('(event/@timestamp)[1]','datetime2(3)') AS event_timestamp,
XEData.value('(event/data[@name="previous_state"]/text)[1]',
'varchar(255)') AS previous_state,
XEData.value('(event/data[@name="current_state"]/text)[1]', 'varchar(255)')
AS current_state,
XEData.value('(event/data[@name="availability_replica_name"]/value)[1]',
'varchar(255)') AS availability_replica_name,
XEData.value('(event/data[@name="availability_group_name"]/value)[1]',
'varchar(255)') AS availability_group_name
INTO #AlwaysOnHealth
FROM (
SELECT CAST(event_data AS XML) XEData, *
FROM sys.fn_xe_file_target_read_file(@FileName, NULL, NULL, NULL)
WHERE
object_name = 'availability_replica_state_change'
or object_name = 'error_reported'
) event_data
--WHERE XEData.value('(event/data[@name="current_state"]/text)[1]',
'varchar(255)') = 'PRIMARY_NORMAL'
-- and DATEADD(day, DATEDIFF(day, 0,
(XEData.value('(event/@timestamp)[1]','datetime2(3)'))), 0) = DATEADD(day,
DATEDIFF(day, 0, GETDATE()), 0)
-- or XEData.value('(event/data[@name="current_state"]/text)[1]',
'varchar(255)') = 'SECONDARY_NORMAL'
-- and DATEADD(day, DATEDIFF(day, 0,
(XEData.value('(event/@timestamp)[1]','datetime2(3)'))), 0) = DATEADD(day,
DATEDIFF(day, 0, GETDATE()), 0)
WHERE XEData.value('(event/data[@name="current_state"]/text)[1]',
'varchar(255)') is not null
and DATEADD(day, DATEDIFF(day, 0,
(XEData.value('(event/@timestamp)[1]','datetime2(3)'))), 0) = DATEADD(day,
DATEDIFF(day, 0, GETDATE()), 0)
or XEData.value('(event/data[@name="current_state"]/text)[1]',
'varchar(255)') is not null
and DATEADD(day, DATEDIFF(day, 0,
(XEData.value('(event/@timestamp)[1]','datetime2(3)'))), 0) = DATEADD(day,
DATEDIFF(day, 0, GETDATE()), 0)

--where XEData.value('(event/data[@name="error_number"]/value)[1]', 'int')
 in (35202,1480)  --- (1480, 35264, 35265, 41404, 41405)
-- OR XEData.value('(event/data[@name="severity"]/value)[1]', 'int') >= 19
ORDER BY event_timestamp DESC;


;WITH AGs
AS
(
select grp.ag_name,
  grp.ag_id,
DBName = STUFF((
SELECT DISTINCT ', ' + d.name
FROM sys.databases d
left outer join sys.dm_hadr_database_replica_states  as hdr on
hdr.database_id = d.database_id
Left outer join sys.dm_hadr_name_id_map as grp2 on grp.ag_id = hdr.group_id
WHERE  grp.ag_name = grp2.ag_name
FOR XML PATH ('')), 1, 1, '')
--sd.name
from sys.databases as sd
left outer join sys.dm_hadr_database_replica_states  as hdrs on
hdrs.database_id = sd.database_id
left outer join sys.dm_hadr_name_id_map as grp on grp.ag_id = hdrs.group_id
where grp.ag_name is not Null
GROUP BY grp.ag_name
,grp.ag_id
)

Select  --AH.event_timestamp,
CONVERT(datetime,SWITCHOFFSET(CONVERT(datetimeoffset,AH.event_timestamp),DATENAME(TzOffset,
SYSDATETIMEOFFSET()))) as Event_Timestamp_DT,
cast(CONVERT(datetime,SWITCHOFFSET(CONVERT(datetimeoffset,AH.event_timestamp),DATENAME(TzOffset,
SYSDATETIMEOFFSET()))) as varchar(30)) as Event_Timestamp,
---AH.Previous_State,
--case
-- when AH.current_state LIKE '%Secondary%' then 'SECONDARY'
-- when AH.current_state lIKE '%Primary%' then 'PRIMARY'
-- else AH.current_state end as [Changed State],
AH.current_state as [Changed State],
---AH.Availability_Replica_Name,
AH.Availability_Group_Name,
Coalesce(AGs.DBName,'No_Databases') as dBname
into #AlwaysOnHealth2
from #AlwaysOnHealth AH
left join AGs on AH.availability_group_name = AGs.ag_name
where
CONVERT(datetime,SWITCHOFFSET(CONVERT(datetimeoffset,AH.event_timestamp),DATENAME(TzOffset,
SYSDATETIMEOFFSET()))) > dateadd(mi,-60,getdate())
order by 1 desc

--select * from #AlwaysOnHealth2
--select * from #AlwaysOnHealth
--order by 1 desc

 -- data
   SELECT @body1=@body1 +'<tbody align="left" style="font-family:Arial;
font-size:11">
<TR>
<TD>'+Event_Timestamp+'</TD>
<TD>'+Availability_Group_Name+'</TD>
<TD>'+[Changed State]+'</TD>
<TD>'+COALESCE(DBName,'No_Databases')+'</TD>
</TR>
</tbody>'
    FROM #AlwaysOnHealth2
   ORDER BY Event_Timestamp_DT DESC

  --select @body1

  declare @changedstate varchar(40)

  ;with lastevent
  as
  (
  --select max(event_Timestamp_DT)as event_timestamp,[Changed State]
  --from #AlwaysOnHealth2
  --group by [Changed State]
  select [Changed State] ,event_Timestamp_DT
  from #AlwaysOnHealth2
  where event_Timestamp_DT  in (select max(event_Timestamp_DT) from
#AlwaysOnHealth2)

  )

  select @changedstate = [Changed State] from lastevent
  --select @changedstate

  --Send an html formatted e-mail to notify of restart if Primary
  if  (@changedstate like ('%PRIMARY%')
or @changedstate like ('%Forwarder%')
or @changedstate like ('%Global%'))
  begin
   EXEC msdb.dbo.sp_send_dbmail
       @profile_name = @pMailProfile,
       @recipients = @pEmail,
       @subject = @vSubject,
       @body = @body1,
  @body_format = 'HTML';
end

SET NOCOUNT OFF
END;
