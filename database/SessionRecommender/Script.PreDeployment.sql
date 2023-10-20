if not exists(select * from sys.symmetric_keys where [name] = '##MS_DatabaseMasterKey##')
begin
    create master key
end
go

if exists(select * from sys.[database_scoped_credentials] where name = '$(OpenAIUrl)')
begin
	drop database scoped credential [$(OpenAIUrl)];
end
go

create database scoped credential [$(OpenAIUrl)]
with identity = 'HTTPEndpointHeaders', secret = '{"api-key":"$(OpenAIKey)"}';
go
