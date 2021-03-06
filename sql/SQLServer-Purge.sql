IF OBJECT_ID ( 'dbo.v_SplitText' ) IS NOT NULL
EXEC sp_executesql N'DROP FUNCTION dbo.v_SplitText'

IF OBJECT_ID ( 'dbo.v_WaitType' ) IS NOT NULL
EXEC sp_executesql N'DROP FUNCTION dbo.v_WaitType'

IF OBJECT_ID ( 'dbo.x_CompareData' ) IS NOT NULL
EXEC sp_executesql N'DROP PROCEDURE dbo.x_CompareData'

IF OBJECT_ID ( 'dbo.x_CopyData' ) IS NOT NULL
EXEC sp_executesql N'DROP PROCEDURE dbo.x_CopyData'

IF OBJECT_ID ( 'dbo.x_DefaultConstraint' ) IS NOT NULL
EXEC sp_executesql N'DROP PROCEDURE dbo.x_DefaultConstraint'

IF OBJECT_ID ( 'dbo.x_FileConfiguration' ) IS NOT NULL
EXEC sp_executesql N'DROP PROCEDURE dbo.x_FileConfiguration'

IF OBJECT_ID ( 'dbo.x_FileSpeed' ) IS NOT NULL
EXEC sp_executesql N'DROP PROCEDURE dbo.x_FileSpeed'

IF OBJECT_ID ( 'dbo.x_FindDuplicates' ) IS NOT NULL
EXEC sp_executesql N'DROP PROCEDURE dbo.x_FindDuplicates'

IF OBJECT_ID ( 'dbo.x_IdentitySeed' ) IS NOT NULL
EXEC sp_executesql N'DROP PROCEDURE dbo.x_IdentitySeed'

IF OBJECT_ID ( 'dbo.x_OperationStatus' ) IS NOT NULL
EXEC sp_executesql N'DROP PROCEDURE dbo.x_OperationStatus'

IF OBJECT_ID ( 'dbo.x_ShowIndex' ) IS NOT NULL
EXEC sp_executesql N'DROP PROCEDURE dbo.x_ShowIndex'

IF OBJECT_ID ( 'dbo.x_ShowIndexColumn' ) IS NOT NULL
EXEC sp_executesql N'DROP PROCEDURE dbo.x_ShowIndexColumn'

IF OBJECT_ID ( 'dbo.x_SystemMemory' ) IS NOT NULL
EXEC sp_executesql N'DROP PROCEDURE dbo.x_SystemMemory'

IF OBJECT_ID ( 'dbo.x_SystemVersion' ) IS NOT NULL
EXEC sp_executesql N'DROP PROCEDURE dbo.x_SystemVersion'

IF OBJECT_ID ( 'dbo.x_ScheduleJob' ) IS NOT NULL
EXEC sp_executesql N'DROP PROCEDURE dbo.x_ScheduleJob'

IF OBJECT_ID ( 'dbo.x_ShowDefaultConstraint' ) IS NOT NULL
EXEC sp_executesql N'DROP PROCEDURE dbo.x_ShowDefaultConstraint'

IF OBJECT_ID ( 'dbo.x_ShowIdentitySeed' ) IS NOT NULL
EXEC sp_executesql N'DROP PROCEDURE dbo.x_ShowIdentitySeed'

GO
