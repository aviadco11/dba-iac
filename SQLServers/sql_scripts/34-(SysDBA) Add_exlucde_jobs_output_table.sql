use DBAUtilities
go

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name =
'ListJobsExcludeOutput' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
CREATE TABLE [dbo].[ListJobsExcludeOutput](
[JobName_Exclude_Output] [nvarchar](300) NOT NULL,
CONSTRAINT [PK_ListJobsExcludeOutput] PRIMARY KEY CLUSTERED
(
[JobName_Exclude_Output] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF,
ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

END


INSERT INTO [ListJobsExcludeOutput] ([JobName_Exclude_Output])
VALUES
    ('(SysDBA) AG Role Change Alert'),
('(SysDBA) Alert On Long Running Query'),
('(SysDBA) Check Mail Status'),
('(SysDBA) CheckAGHealth'),
('(SysDBA) Collect Tempdb Size'),
('(SysDBA) Set all Agent job owners to sa'),
('(SysDBA) Alert On Long Running SQL Agent Job');