if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA = 'Jobs' and TABLE_NAME = 'JobActiveStats')
    drop view Jobs.JobActiveStats
go

set quoted_identifier on

set ansi_nulls on
go

create view Jobs.JobActiveStats
as
select
   Server = serverproperty('ServerName')
   ,[dd hh:mm:ss] = dbo.Sec2Time(jj.JobDurSec, 1)
   ,JobAvg = dbo.Sec2Time(jj.JobAvgSec, 1)
   ,JobWrn = dbo.Sec2Time((jj.JobAvgSec + jj.JobStdDevSec), 1)
   ,JobMax = dbo.Sec2Time(jj.JobMaxSec, 1)
   ,JobPct = case jj.JobAvgSec
             when 0 then 0.00
             else cast(jj.JobDurSec * 1.0 / jj.JobAvgSec as decimal(5, 2))end
   ,JobLimit = case jj.JobAvgSec
               when 0 then 0.00
               else cast(jj.JobDurSec / (jj.JobAvgSec + jj.JobStdDevSec) as decimal(5, 2))end
   ,JobTh = case jj.JobMaxSec when 0 then 0.00 else cast(jj.JobDurSec * 1.0 / (jj.JobMaxSec * 1.1) as decimal(5, 2))end
   ,JobError = case when jj.JobDurSec > jj.JobMaxSec then 1.0 else 0.0 end
   ,jj.SPID
   ,Block = jj.blocked
   ,jj.JobName
   ,Step = cast(jj.StepId as varchar(5)) + ' / ' + cast(jj.StepMax as varchar(5))
   ,jj.StepName
   ,StepDuration = dbo.Sec2Time(jj.StepDurSec, 1)
   ,StepAvg = dbo.Sec2Time(jj.StepAvgSec, 1)
   ,StepWrn = dbo.Sec2Time((jj.StepAvgSec + jj.StepStdDevSec), 1)
   ,StepMax = dbo.Sec2Time(jj.StepMaxSec, 1)
   ,StepPct = case jj.StepAvgSec
              when 0 then 0.00
              else cast(jj.StepDurSec * 1.0 / jj.StepAvgSec as decimal(5, 2))end
   ,StepLimit = case jj.StepAvgSec
                when 0 then 0.00
                else cast(jj.StepDurSec / (jj.StepAvgSec + jj.StepStdDevSec) as decimal(5, 2))end
   ,StepTh = case jj.StepMaxSec when 0 then 0.00 else cast(jj.StepDurSec / (jj.StepMaxSec * 1.1) as decimal(5, 2))end
   ,StepError = case when jj.StepDurSec > jj.StepMaxSec then 1.0 else 0.0 end
   ,jj.DBName
   ,jj.LoginName
   ,JobStart = convert(char(19), jj.start_execution_date, 120)
   ,StepStart = convert(char(19), jj.StepStart, 120)
   ,Cmd = jj.cmd
   ,WaitResource = isnull(jj.waitresource, '')
   ,jj.JobDescription
from
    Jobs.JobActiveStatsRaw as jj
