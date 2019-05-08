if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA = 'dbo' and ROUTINE_NAME = 'JobDurationSec')
    drop function dbo.JobDurationSec
go

create function dbo.JobDurationSec (
    @jd as int
)
returns int
as
begin
    declare @jds int

    begin
        select
            @jds = @jd % 100 + (@jd % 10000 - @jd % 100) / 10 * 6 + (@jd - @jd % 10000) / 100 * 36
    end

    return @jds
end
go
