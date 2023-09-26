create or alter procedure dbo.stp_GetSessionsCountAggregate
as
select 
    count(*) as TotalSessionsCount 
from 
    dbo.Sessions
go