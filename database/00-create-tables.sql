drop table if exists dbo.[SessionAbstractEmbeddings];
drop table if exists dbo.[Sessions];
go

drop sequence if exists GlobalId;
create sequence GlobalId as int start with 1 increment by 1;
go

create table dbo.[Sessions]
(
    id int not null primary key default next value for GlobalId,
    title nvarchar(200) not null unique,
    abstract nvarchar(max) not null,
    title_hash binary(64) not null,
    abstract_hash binary(64) not null,
    last_seen_in_source_data datetime2 null
)
go

create table dbo.SessionAbstractEmbeddings
(
    session_id int not null,
    vector_value_id int not null,
    vector_value decimal(19,16) not null,
)
go
create clustered columnstore index IXCC on dbo.SessionAbstractEmbeddings
go

create table dbo.SearchedText
(
    id int identity not null primary key,
    searched_text nvarchar(max) not null,
    search_datetime datetime2 not null default(sysdatetime())
)
go