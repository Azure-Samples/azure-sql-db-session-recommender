
create   procedure web.get_sessions_count
as
select count(*) as total_sessions from web.sessions;

GO

