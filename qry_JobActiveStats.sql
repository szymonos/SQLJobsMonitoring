/*
exec Jobs.JobHistoryStatsUpdate
kill 119
*/

select ja.JobMax ,ja.[dd hh:mm:ss] + ' ' + case when ja.JobTh > 1 then nchar(0x25A0) when ja.JobLimit > 1 then nchar(0x25C8) else nchar(0x25CB)end as JDuration ,ja.JobWrn ,ja.Block ,ja.SPID ,ja.JobName ,ja.Step ,ja.StepMax ,ja.StepDuration + ' ' + case when ja.StepTh > 1 then nchar(0x25A0) when ja.StepLimit > 1 then nchar(0x25C8) else nchar(0x25CB)end as StDuration ,ja.StepWrn ,ja.StepName ,ja.DBName ,ja.Cmd ,ja.WaitResource
from Admin.Jobs.JobActiveStats as ja order by ja.JobStart;
