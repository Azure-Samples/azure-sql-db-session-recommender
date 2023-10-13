ALTER   procedure [dbo].[stp_StoreSession]
@title nvarchar(200),
@abstract nvarchar(max),
@session_id uniqueidentifier, 
@topic_id uniqueidentifier, 
@code varchar(50), 
@tid varchar(50)
as
set nocount on

declare @th as binary(64) = hashbytes('sha2_512', @title);
declare @ah as binary(64) = hashbytes('sha2_512', @abstract);

if (exists (select * from dbo.Sessions where title_hash = @th and abstract_hash = @ah)) begin
    print '> Session already exists';
    update dbo.Sessions set last_seen_in_source_data = sysdatetime() where title_hash = @th and abstract_hash = @ah
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

select @id = id from dbo.Sessions where title = @title; 

if (@id is null)
begin
    set @id = next value for dbo.GlobalId;
    insert into dbo.Sessions (id, title, abstract, title_hash, abstract_hash, last_seen_in_source_data, session_id, topic_id, tid, code) 
    values (@id, @title, @abstract, @th, @ah, sysutcdatetime(), @session_id, @topic_id, @tid, @code)
end else begin
    update dbo.Sessions set
         title = @title, abstract = @abstract, title_hash = @th, abstract_hash = @ah, 
         last_seen_in_source_data = sysutcdatetime(), session_id = @session_id, topic_id = @topic_id, 
         tid = @tid, code = @code
    where id = @id
    delete from dbo.SessionAbstractEmbeddings where session_id = @id
end

insert into dbo.SessionAbstractEmbeddings
    (session_id, vector_value_id, vector_value)
select
    @id, vector_value_id, vector_value
from
    #t

commit tran;
GO
