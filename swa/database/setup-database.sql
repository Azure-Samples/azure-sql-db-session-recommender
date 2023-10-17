:setvar OpenAIUrl https://.openai.azure.com
:setvar OpenAIKey 

/*
    Enable change tracking on the database
*/
if not exists(select * from sys.change_tracking_databases where database_id = db_id()) begin
    declare @sql nvarchar(max) = 'alter database ' + quotename(db_name()) + ' set change_tracking = on (change_retention = 2 days, auto_cleanup = on)'
    exec(@sql)
end
go

/*
    Create database master key
*/
if not exists(select * from sys.symmetric_keys where [name] = '##MS_DatabaseMasterKey##')
begin
    create master key
end
go

/*
    Create database credentials to store API key
*/
if exists(select * from sys.[database_scoped_credentials] where name = '$(OpenAIUrl)')
begin
	drop database scoped credential [$(OpenAIUrl)];
end
go

create database scoped credential [$(OpenAIUrl)]
with identity = 'HTTPEndpointHeaders', secret = '{"api-key":"$(OpenAIKey)"}';
go

/*
    Create schema
*/
create schema [netconf2023] authorization dbo;
go

/*
    Create sequence
*/
create sequence netconf2023.global_id as int start with 1 increment by 1;
go

/*
    Create tables
*/
CREATE TABLE [netconf2023].[sessions] (
    [id]           INT            DEFAULT (NEXT VALUE FOR [netconf2023].[global_id]) NOT NULL,
    [title]        NVARCHAR (200) NOT NULL,
    [abstract]     NVARCHAR (MAX) NOT NULL,
    [last_updated] DATETIME2 (7)  NULL,
    PRIMARY KEY CLUSTERED ([id] ASC),
    UNIQUE NONCLUSTERED ([title] ASC)
);
go

ALTER TABLE [netconf2023].[sessions] ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = OFF);
go

CREATE TABLE [netconf2023].[session_abstract_embeddings] (
    [session_id]      INT              NOT NULL,
    [vector_value_id] INT              NOT NULL,
    [vector_value]    DECIMAL (19, 16) NOT NULL,
    FOREIGN KEY ([session_id]) REFERENCES [netconf2023].[sessions] ([id])
);
go

CREATE CLUSTERED COLUMNSTORE INDEX IXCC ON [netconf2023].session_abstract_embeddings;
go

CREATE TABLE [netconf2023].[searched_text] (
    [id]               INT            IDENTITY (1, 1) NOT NULL,
    [searched_text]    NVARCHAR (MAX) NOT NULL,
    [search_datetime]  DATETIME2 (7)  DEFAULT (sysdatetime()) NOT NULL,
    [ms_rest_call]     INT            NULL,
    [ms_vector_search] INT            NULL,
    PRIMARY KEY CLUSTERED ([id] ASC)
);
go

/*
    Create procedures
*/
create or alter procedure [netconf2023].[find_sessions]
@text nvarchar(max),
@top int = 10,
@min_similarity decimal(19,16) = 0.65
as
if (@text is null) return;

declare @sid as int;
insert into netconf2023.searched_text (searched_text) values (@text);
set @sid = scope_identity()

declare @startTime as datetime2(7) = sysdatetime()

declare @retval int, @response nvarchar(max);
declare @payload nvarchar(max);
set @payload = json_object('input': @text);

begin try
    exec @retval = sp_invoke_external_rest_endpoint
        @url = '$(OpenAIUrl)/openai/deployments/embeddings/embeddings?api-version=2023-03-15-preview',
        @method = 'POST',
        @credential = [$(OpenAIUrl)],
        @payload = @payload,
        @response = @response output;
end try
begin catch
    select 
        'SQL' as error_source, 
        error_number() as error_code,
        error_message() as error_message
    return;
end catch

if (@retval != 0) begin
    select 
        'OPENAI' as error_source, 
        json_value(@response, '$.result.error.code') as error_code,
        json_value(@response, '$.result.error.message') as error_message,
        @response as error_response
    return;
end;

declare @endTime1 as datetime2(7) = sysdatetime();
update [netconf2023].[searched_text] set ms_rest_call = datediff(ms, @startTime, @endTime1) where id = @sid;

with cteVector as
(
    select 
        cast([key] as int) as [vector_value_id],
        cast([value] as float) as [vector_value]
    from 
        openjson(json_query(@response, '$.result.data[0].embedding'))
),
cteSimilar as
(
    select top (@top)
        v2.session_id, 
        -- Optimized as per https://platform.openai.com/docs/guides/embeddings/which-distance-function-should-i-use
        sum(v1.[vector_value] * v2.[vector_value]) as cosine_similarity
    from 
        cteVector v1
    inner join 
        netconf2023.session_abstract_embeddings v2 on v1.vector_value_id = v2.vector_value_id
    group by
        v2.session_id
    order by
        cosine_similarity desc
)
select 
    a.id,
    a.title,
    a.abstract,
    r.cosine_similarity
from 
    cteSimilar r
inner join 
    netconf2023.sessions a on r.session_id = a.id
where   
    r.cosine_similarity > @min_similarity
order by    
    r.cosine_similarity desc

declare @endTime2 as datetime2(7) = sysdatetime()
update [netconf2023].[searched_text] set ms_vector_search = datediff(ms, @endTime1, @endTime2) where id = @sid
go

create or alter procedure netconf2023.get_sessions_count
as
select count(*) as total_sessions from netconf2023.sessions;
go

create or alter procedure [netconf2023].[upsert_session_abstract_embeddings]
@session_id int,
@embeddings nvarchar(max)
as

set xact_abort on
set transaction isolation level serializable

begin transaction

    update netconf2023.sessions set last_updated = sysdatetime() where id = @session_id

    delete from netconf2023.session_abstract_embeddings 
    where session_id = @session_id

    insert into netconf2023.session_abstract_embeddings
    select @session_id, cast([key] as int), cast([value] as float) 
    from openjson(@embeddings)

commit
go

/* 
Create user
*/
if not exists(select * from sys.database_principals where name = 'session_recommender_app')
begin
    create user session_recommender_app with password = 'unEno!h5!&*KP420xds&@P901afb$^M'
    grant select on schema::netconf2023 to session_recommender_app
    grant execute on schema::netconf2023 to session_recommender_app
end
go