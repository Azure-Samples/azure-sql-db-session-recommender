create or alter procedure dbo.stp_FindRelatedSessions
@text nvarchar(max)
as
declare @retval int, @response nvarchar(max);
declare @payload nvarchar(max);
set @payload = json_object('input': @text);

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
    select top (10)
        v2.session_id, 
        -- Optimized as per https://platform.openai.com/docs/guides/embeddings/which-distance-function-should-i-use
        sum(v1.[vector_value] * v2.[vector_value]) as cosine_distance 
    from 
        cteVector v1
    inner join 
        dbo.SessionAbstractEmbeddings v2 on v1.vector_value_id = v2.vector_value_id
    group by
        v2.session_id
    order by
        cosine_distance desc
)
select 
    a.id,
    a.title,
    a.abstract,
    r.cosine_distance
from 
    cteSimilar r
inner join 
    dbo.Sessions a on r.session_id = a.id
order by    
    r.cosine_distance desc
go
