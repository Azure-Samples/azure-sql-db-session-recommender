drop table if exists dbo.video_recording_abstract_embeddings;
drop table if exists dbo.video_recordings;
go

create table [dbo].[video_recordings]
(
	[id] [int] not null,
	[title] [nvarchar](200) not null,
	[abstract] [nvarchar](max) not null,
	[title_hash] [binary](64) not null,
	[abstract_hash] [binary](64) not null,
	[source_id] [nvarchar](100) not null,
	[source_last_seen] [datetime2](7) not null
)
alter table [dbo].[video_recordings] add primary key clustered ([id] asc)
alter table [dbo].[video_recordings] add default (next value for [GlobalId]) for [id]
alter table [dbo].[video_recordings] add default (sysutcdatetime()) for [source_last_seen]
go

create table dbo.video_recording_abstract_embeddings
(
    video_recording_id int not null foreign key references dbo.video_recordings(id),
    vector_value_id int not null,
    vector_value decimal(19,16) not null,
)
go

create clustered columnstore index IXCC on dbo.video_recording_abstract_embeddings with drop_existing
go

drop table if exists dbo.video_recordings_searched_text;
create table dbo.video_recordings_searched_text
(
    id int identity not null primary key,
    searched_text nvarchar(max) not null,
    search_datetime datetime2 not null default(sysdatetime())
)
go