declare c cursor for
select 
    Title,
    Abstract
from 
    [dbo].[Airlift23-ENG sessions (2)]
where
    Abstract is not null

declare @title nvarchar(1000), @abstract nvarchar(max)
open c
fetch next from c into @title, @abstract

while @@fetch_status = 0 begin
    print @title 
    exec dbo.stp_StoreSession @title, @abstract
    waitfor delay '00:00:01'
    fetch next from c into @title, @abstract
end

close c
deallocate c
go

select * from dbo.Sessions order by title

