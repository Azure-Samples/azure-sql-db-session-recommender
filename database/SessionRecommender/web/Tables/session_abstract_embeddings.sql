CREATE TABLE [web].[session_abstract_embeddings] (
    [session_id]      INT              NOT NULL,
    [vector_value_id] INT              NOT NULL,
    [vector_value]    DECIMAL (19, 16) NOT NULL,
    FOREIGN KEY ([session_id]) REFERENCES [web].[sessions] ([id])
);


GO

CREATE CLUSTERED COLUMNSTORE INDEX [IXCC]
    ON [web].[session_abstract_embeddings];


GO

