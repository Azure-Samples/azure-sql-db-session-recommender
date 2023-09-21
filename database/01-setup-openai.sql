/*
    Create database master key
*/
if not exists(select * from sys.symmetric_keys where [name] = '##MS_DatabaseMasterKey##')
begin
    create master key
end

/*
    Create database credentials to store API key
*/
if exists(select * from sys.[database_scoped_credentials] where name = 'https://dm-open-ai.openai.azure.com')
begin
	drop database scoped credential [https://dm-open-ai.openai.azure.com];
end
create database scoped credential [https://dm-open-ai.openai.azure.com]
with identity = 'HTTPEndpointHeaders', secret = '{"api-key":"a13bcd59f76640ddbd574525d5d48113"}';
go
