if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA = 'Jobs' and TABLE_NAME = 'JobActiveStatsRaw')
    drop view Jobs.JobActiveStatsRaw
go

create view Jobs.JobActiveStatsRaw
as
with jsid
as (
   select
       p.spid
      ,s.job_id
      ,job_name = j.name
      ,s.step_id
      ,s.step_name
      ,loginame = rtrim(p.nt_username)
	  ,dbname = db_name(p.dbid)
      ,waitresource = rtrim(p.waitresource)
      ,cmd = rtrim(p.cmd)
      ,p.blocked
	  ,QueryText = left(q.text, 444) --Power BI baloon tip can show only 444 characters
   from
       sys.sysprocesses as p
	   cross apply sys.dm_exec_sql_text(p.sql_handle) as q
       inner join msdb.dbo.sysjobsteps as s with(nolock)
           on convert(varchar(max), convert(binary(16), s.job_id), 1) = substring(p.program_name, 30, 34)
              and s.step_id = stuff(left(p.program_name, len(p.program_name) - 1), 1, 71, '')
       inner join msdb.dbo.sysjobs as j with(nolock)
           on j.job_id = s.job_id
   where
       p.spid > 50 and p.program_name like 'SQLAgent - TSQL JobStep (Job %' and p.loginame <> ''
   )
select
    JobDurSec = abs(datediff(second, ja.start_execution_date, getdate())) * 1.0
   ,JobAvgSec = isnull(jstat.js_avg, 0)
   ,JobStdDevSec = isnull(jstat.js_stdev, 0)
   ,JobMaxSec = isnull(jstat.js_max, 0)
   ,SPID = isnull(jsid.spid, 0)
   ,JobName = j.name
   ,StepId = isnull(jsid.step_id, isnull(ja.last_executed_step_id, 0) + 1)
   ,StepMax = (select
                   max(sjs.step_id)
               from
                   msdb.dbo.sysjobsteps as sjs with(nolock)
               where
                   sjs.job_id = ja.job_id)
   ,StepName = isnull(jsid.step_name, js.step_name)
   ,StepStart = case
                when jsid.step_id = 1 then ja.start_execution_date
                else isnull(ja.last_executed_step_date, getdate())end
   ,StepDurSec = case
                 when jsid.step_id = 1 then abs(datediff(second, ja.start_execution_date, getdate())) * 1.0
                 else abs(datediff(second, coalesce(ja.last_executed_step_date, ja.start_execution_date, getdate()), getdate())) * 1.0 end
   ,StepAvgSec = isnull(sstat.js_avg, 0) + isnull(sstat1.js_avg, 0)			-- include summarized statistics for current and last step
   ,StepStdDevSec = isnull(sstat.js_stdev, 0) + isnull(sstat1.js_stdev, 0)	-- because table sysjobactivity doesn't provide information
   ,StepMaxSec = isnull(sstat.js_max, 0) + isnull(sstat1.js_max, 0)			-- about current step start time
   ,DBName = isnull(jsid.dbname, js.database_name)
   ,LoginName = jsid.loginame
   ,ja.start_execution_date
   ,cmd = isnull(jsid.cmd, js.subsystem)
   ,jsid.waitresource
   ,blocked = isnull(jsid.blocked, 0)
   ,JobDescription = j.description
   ,jsid.QueryText
   ,IsBlock = 0
from
    msdb.dbo.sysjobactivity as ja with(nolock)
    inner join msdb.dbo.sysjobs as j with(nolock)
        on j.job_id = ja.job_id
    left outer join msdb.dbo.sysjobsteps as js with(nolock)
        on js.job_id = ja.job_id and js.step_id = isnull(ja.last_executed_step_id, 0) + 1
    left outer join jsid
        on jsid.job_id = ja.job_id
    left outer join Jobs.JobHistoryStats as jstat with(nolock)
        on jstat.job_id = ja.job_id and jstat.step_id = 0
    left outer join Jobs.JobHistoryStats as sstat with(nolock)
        on sstat.job_id = ja.job_id and sstat.step_id = coalesce(jsid.step_id, ja.last_executed_step_id + 1, 1)
    left outer join Jobs.JobHistoryStats as sstat1 with(nolock) --include job statistics
        on sstat1.job_id = ja.job_id and sstat1.step_id = isnull(jsid.step_id - 1, ja.last_executed_step_id)
where
    ja.run_requested_source <> 3 --SOURCE_BOOT
	and ja.session_id = (select top (1)
                         session_id
                     from
                         msdb.dbo.syssessions with(nolock)
                     order by
                         agent_start_date desc) and ja.start_execution_date is not null and ja.stop_execution_date is null
union
/* Include information about processes blocking jobs */
select
    JobDurSec = datediff(second, p.login_time, getdate())
   ,JobAvgSec = 0
   ,JobStdDevSec = 0
   ,JobMaxSec = 0
   ,SPID = p.spid
   ,JobName = '*Blocking from host: ' + p.hostname + '*'
   ,StepId = null
   ,StepMax = null
   ,StepName = p.program_name
   ,StepStart = p.last_batch
   ,StepDurSec = datediff(second, p.last_batch, getdate())
   ,StepAvgSec = 0
   ,StepStdDevSec = 0
   ,StepMaxSec = 0
   ,DBName = db_name(p.dbid)
   ,LoginName = p.nt_username
   ,start_execution_date = p.login_time
   ,p.cmd
   ,p.waitresource
   ,p.blocked
   ,JobDescription = null
   ,QueryText = left(q.text, 444) --Power BI baloon tip can show only 444 characters
   ,IsBlock = 1
from
    sys.sysprocesses as p
    cross apply sys.dm_exec_sql_text(p.sql_handle) as q
    inner join jsid
        on p.spid = jsid.blocked
where
	p.program_name not like 'SQLAgent - TSQL JobStep (Job %'
go
