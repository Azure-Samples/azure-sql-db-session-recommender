drop table if exists dbo.SessionAbstractEmbeddings;
drop table if exists dbo.[Sessions];
go

drop sequence if exists GlobalId;
create sequence GlobalId as int start with 1 increment by 1;
go

create table dbo.[Sessions]
(
    id int not null primary key default next value for GlobalId,
    title nvarchar(100) not null unique,
    abstract nvarchar(max) not null
)
go

create table dbo.SessionAbstractEmbeddings
(
    session_id int not null,
    vector_value_id int not null,
    vector_value decimal(14,12) not null,
)
go
create clustered columnstore index IXCC on dbo.SessionAbstractEmbeddings
go