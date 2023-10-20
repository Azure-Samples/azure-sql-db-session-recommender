CREATE TABLE [web].[user_session_favorites] (
    [user_id]    INT NOT NULL,
    [session_id] INT NOT NULL,
    PRIMARY KEY CLUSTERED ([user_id] ASC, [session_id] ASC)
);


GO

