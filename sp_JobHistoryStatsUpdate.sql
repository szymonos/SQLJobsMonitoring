if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA = 'Jobs' and ROUTINE_NAME = 'JobHistoryStatsUpdate')
    drop proc Jobs.JobHistoryStatsUpdate
go

create proc Jobs.JobHistoryStatsUpdate
as
begin
    truncate table Jobs.JobHistoryStats

    insert into Jobs.JobHistoryStats (job_id, step_id, js_avg, js_stdev, js_min, js_max, js_cnt)
    select
        jh.job_id
       ,jh.step_id
       ,js_avg = cast(avg(Admin.dbo.JobDurationSec(jh.run_duration) * 1.0) as decimal(9, 2))
       ,js_stdev = cast(isnull(stdev(Admin.dbo.JobDurationSec(jh.run_duration) * 1.0), 0.0) as decimal(9, 2))
	   ,js_min = cast(isnull(min(Admin.dbo.JobDurationSec(jh.run_duration) * 1.0), 0.0) as decimal(9, 2))
	   ,js_max = cast(isnull(max(Admin.dbo.JobDurationSec(jh.run_duration) * 1.0), 0.0) as decimal(9, 2))
       ,js_cnt = count(jh.job_id)
    from
        msdb.dbo.sysjobhistory as jh with(nolock)
    where
        jh.run_status = 1
		and jh.run_duration >= 0
    group by
        jh.job_id
       ,jh.step_id
end
go