
create   procedure [web].[upsert_session_abstract_embeddings]
@session_id int,
@embeddings nvarchar(max)
as

set xact_abort on
set transaction isolation level serializable

begin transaction
    delete from web.session_abstract_embeddings 
    where session_id = @session_id

    insert into web.session_abstract_embeddings
    select @session_id, cast([key] as int), cast([value] as float) 
    from openjson(@embeddings)

commit

GO

