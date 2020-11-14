
--
-- Create indexes
--

IF NOT EXISTS ( SELECT 1 FROM sys.indexes WHERE [name] = 'UX_FirstName_SecondName_LastName' AND [object_id] = OBJECT_ID('dbo.[Contact]') )
CREATE UNIQUE NONCLUSTERED INDEX UX_FirstName_SecondName_LastName ON dbo.[Contact]
(
	FirstName , SecondName , LastName
)
;
