declare c cursor for
select 
    Title,
    Abstract
from 
    [dbo].[Airlift23-ENG sessions (2)]
where
    Abstract is not null and Title is not null

declare @ret int

declare @title nvarchar(1000), @abstract nvarchar(max)
open c
fetch next from c into @title, @abstract

while @@fetch_status = 0 begin
    set @title=trim(@title)
    set @abstract=trim(@abstract)
    print @title 
    exec @ret = dbo.stp_StoreSession @title, @abstract
    if (@ret = 0) waitfor delay '00:00:01'
    fetch next from c into @title, @abstract
end

close c
deallocate c
go

select * from dbo.Sessions order by title

