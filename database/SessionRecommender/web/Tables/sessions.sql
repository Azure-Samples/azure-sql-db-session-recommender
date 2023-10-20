CREATE TABLE [web].[sessions] (
    [id]           INT            DEFAULT (NEXT VALUE FOR [web].[global_id]) NOT NULL,
    [title]        NVARCHAR (200) NOT NULL,
    [abstract]     NVARCHAR (MAX) NOT NULL,
    [last_updated] DATETIME2 (7)  NULL,
    PRIMARY KEY CLUSTERED ([id] ASC),
    UNIQUE NONCLUSTERED ([title] ASC)
);
GO

ALTER TABLE [web].[sessions] ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = OFF);
GO

