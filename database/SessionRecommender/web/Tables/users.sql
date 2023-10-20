CREATE TABLE [web].[users] (
    [id]                             INT             DEFAULT (NEXT VALUE FOR [web].[global_id]) NOT NULL,
    [identity_provider]              NVARCHAR (100)  NOT NULL,
    [indetity_provider_user_id]      NVARCHAR (100)  NOT NULL,
    [identity_provider_user_details] NVARCHAR (1000) NOT NULL,
    PRIMARY KEY CLUSTERED ([id] ASC)
);


GO

