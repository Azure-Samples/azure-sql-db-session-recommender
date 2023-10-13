declare c cursor for
select 
    trim(Title) as Title,
    trim(Abstract) as Abstract,
    trim(Code) as Code,
    trim(TID) as TID,
    cast(trim(SessionID) as uniqueidentifier) as SessionID,
    cast(trim(TopicID) as uniqueidentifier) as TopicID
from 
    [dbo].[MasterSessionGrid-Approved (1) 1012 pull]
where
    Abstract is not null and Title is not null
and
    Publishing_Status = 'Full'
declare @ret int

declare @title nvarchar(1000), @abstract nvarchar(max), @session_id uniqueidentifier, @topic_id uniqueidentifier, @code varchar(50), @tid varchar(50)
open c
fetch next from c into @title, @abstract, @code, @tid, @session_id, @topic_id

while @@fetch_status = 0 begin
    print @title 
    exec @ret = dbo.stp_StoreSession @title, @abstract, @session_id, @topic_id, @code, @tid
    if (@ret = 0) waitfor delay '00:00:00.300'
    fetch next from c into @title, @abstract, @code, @tid, @session_id, @topic_id
end

close c
deallocate c
go

select * from dbo.Sessions order by title

