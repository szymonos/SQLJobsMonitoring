if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA = 'Jobs' and TABLE_NAME = 'JobHistoryStats')
    drop table Jobs.JobHistoryStats
go

create table [Jobs].[JobHistoryStats](
	[job_id] [uniqueidentifier] not null,
	[step_id] [int] not null,
	[js_avg] [decimal](9, 2) not null,
	[js_stdev] [decimal](9, 2) not null,
	[js_min] [decimal](9, 2) not null,
	[js_max] [decimal](9, 2) not null,
	[js_cnt] [int] not null,
 constraint [PK_RunningStats] primary key clustered
(
	[job_id] asc,
	[step_id] asc
)with (pad_index = off, statistics_norecompute = off, ignore_dup_key = off, allow_row_locks = on, allow_page_locks = on) on [PRIMARY]
) on [PRIMARY]
go
