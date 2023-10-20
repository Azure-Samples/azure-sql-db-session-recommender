CREATE TABLE [web].[searched_text] (
    [id]               INT            IDENTITY (1, 1) NOT NULL,
    [searched_text]    NVARCHAR (MAX) NOT NULL,
    [search_datetime]  DATETIME2 (7)  DEFAULT (sysdatetime()) NOT NULL,
    [ms_rest_call]     INT            NULL,
    [ms_vector_search] INT            NULL,
    PRIMARY KEY CLUSTERED ([id] ASC)
);


GO

