drop table if exists #s;
create table #s (source_id int, title nvarchar(200), abstract nvarchar(max));

declare @retval int, @response nvarchar(max)
declare @url nvarchar(1000) = N'https://happy-water-0ba0aae03.3.azurestaticapps.net/data-api/rest/talks'

while (@url != '')
begin
    print 'Retrieving from: ' + @url;

    exec @retval = sp_invoke_external_rest_endpoint
        @url = @url,
        @method = 'GET',
        @response = @response output

    set @url = json_value(@response, '$.result.nextLink');
    set @url = replace(@url, 'http://', 'https://');
    set @url = replace(@url, '/rest/talks', '/data-api/rest/talks')

    if (@retval = 0) begin
        insert into #s
            (source_id, title, abstract)
        select 
            [Id] as source_id,
            [Name] as title,
            [Abstract] as abstract
        from 
            openjson(@response, '$.result.value') with 
            (
                [Id] int,
                [Name] nvarchar(200),
                [Abstract] nvarchar(max)
            )
        where trim(nullif([Abstract],'')) is not null
    
        if (@@rowcount = 0) set @url = ''
    end else begin
        select @retval, @response;
    end

end

select count(*) from #s;
go


declare c cursor for
select 
    source_id,
    title,
    abstract
from 
    #s
;

declare @ret int, @source_id nvarchar(100), @title nvarchar(1000), @abstract nvarchar(max);

open c;
fetch next from c into @source_id, @title, @abstract;

while @@fetch_status = 0 begin
    print @title 
    exec @ret = dbo.stp_store_video_recording @source_id, @title, @abstract
    if (@ret = 0) waitfor delay '00:00:01'
    fetch next from c into @source_id, @title, @abstract
end

close c
deallocate c
go

select * from dbo.video_recordings
--select * from dbo.video_recording_abstract_embeddings

