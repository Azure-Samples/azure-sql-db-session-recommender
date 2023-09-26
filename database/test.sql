-- exec dbo.stp_StoreSession
--     'Advanced content policies in SharePoint and OneDrive – RAC, DAG, SLM, ESP, and more ',
--     'Learn how to protect the content in your tenant with advanced content policies in SharePoint and OneDrive. '
-- ;

-- select * from dbo.Sessions

-- select * from dbo.SessionAbstractEmbeddings where session_id = 1

-- exec dbo.stp_FindRelatedSessions 'REST'


select *, search_datetime at time zone 'UTC' at time zone 'Pacific Standard Time' as search_datetime_local from dbo.SearchedText



--delete from dbo.SearchedText where searched_text = 'test'
--delete from dbo.SearchedText where id between 132 and 157

