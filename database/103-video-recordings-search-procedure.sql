create or alter procedure dbo.stp_search_video_recordings
@text nvarchar(max),
@top int = 10,
@min_similarity decimal(19,16) = 0.65
as
if (@text is null) return;

insert into dbo.video_recordings_searched_text (searched_text) values (@text);

declare @retval int, @response nvarchar(max);
declare @payload nvarchar(max);
set @payload = json_object('input': @text);

begin try
    exec @retval = sp_invoke_external_rest_endpoint
        @url = 'https://dm-open-ai.openai.azure.com/openai/deployments/embeddings/embeddings?api-version=2023-03-15-preview',
        @method = 'POST',
        @credential = [https://dm-open-ai.openai.azure.com],
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

with cteSearch as
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
        v2.video_recording_id, 
        -- Optimized as per https://platform.openai.com/docs/guides/embeddings/which-distance-function-should-i-use
        sum(v1.[vector_value] * v2.[vector_value]) as cosine_similarity
    from 
        cteSearch v1
    inner join 
        dbo.video_recording_abstract_embeddings v2 on v1.vector_value_id = v2.vector_value_id
    group by
        v2.video_recording_id
    order by
        cosine_similarity desc
)
select 
    a.id,
    a.source_id,
    a.title,
    a.abstract,
    r.cosine_similarity
from 
    cteSimilar r
inner join 
    dbo.video_recordings a on r.video_recording_id = a.id
where   
    r.cosine_similarity > @min_similarity
order by    
    r.cosine_similarity desc
go
