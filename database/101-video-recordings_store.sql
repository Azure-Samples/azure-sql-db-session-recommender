create or alter procedure dbo.stp_store_video_recording
@source_id nvarchar(100),
@title nvarchar(200),
@abstract nvarchar(max)
as
set nocount on

declare @th as binary(64) = hashbytes('sha2_512', @title);
declare @ah as binary(64) = hashbytes('sha2_512', @abstract);

if (exists (select * from dbo.video_recordings where (title_hash = @th and abstract_hash = @ah) and source_id = @source_id)) begin
    print '> Session already exists';
    update dbo.video_recordings set source_last_seen = sysutcdatetime() where source_id = @source_id;
    return -1;
end

/*
    Get the embeddings for the input text by calling the OpenAI API
*/
declare @retval int, @response nvarchar(max);
declare @payload nvarchar(max) = json_object('input': @abstract);
exec @retval = sp_invoke_external_rest_endpoint
    @url = 'https://dm-open-ai.openai.azure.com/openai/deployments/embeddings/embeddings?api-version=2023-03-15-preview',
    @method = 'POST',
    @credential = [https://dm-open-ai.openai.azure.com],
    @payload = @payload,
    @response = @response output;

if (@retval <> 0) begin
    print @response;
    throw 50000, 'Error calling OpenAI API', 1;
end;

--select @title, @response
/*
    Extract the title vectors from the JSON and store them in a table
*/
drop table if exists #t;
select 
    cast([key] as int) as [vector_value_id],
    cast([value] as float) as [vector_value]
into    
    #t
from 
    openjson(@response, '$.result.data[0].embedding')
;

set xact_abort on;
set transaction isolation level serializable
begin tran

declare @id as int;

select @id = id from dbo.video_recordings where source_id = @source_id;

if (@id is null)
begin
    set @id = next value for dbo.GlobalId;
    insert into dbo.video_recordings (id, title, abstract, title_hash, abstract_hash, source_id) values (@id, @title, @abstract, @th, @ah, @source_id)
end else begin
    update dbo.video_recordings set title = @title, abstract = @abstract, title_hash = @th, abstract_hash = @ah where id = @id
    delete from dbo.video_recording_abstract_embeddings where video_recording_id = @id
end

insert into dbo.video_recording_abstract_embeddings
    (video_recording_id, vector_value_id, vector_value)
select
    @id, vector_value_id, vector_value
from
    #t

commit tran;