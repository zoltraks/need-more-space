IF OBJECT_ID ('dbo.v_ColumnType', 'FN') IS NOT NULL
EXEC sp_executesql N'DROP FUNCTION dbo.v_ColumnType'

IF OBJECT_ID ('dbo.v_SplitText', 'TF') IS NOT NULL
EXEC sp_executesql N'DROP FUNCTION dbo.v_SplitText'

IF OBJECT_ID ('dbo.v_VersionList' , 'TF') IS NOT NULL
EXEC sp_executesql N'DROP FUNCTION dbo.v_VersionList'

IF OBJECT_ID ('dbo.v_WaitType' , 'TF') IS NOT NULL
EXEC sp_executesql N'DROP FUNCTION dbo.v_WaitType'

IF OBJECT_ID ('dbo.x_CompareData' , 'P') IS NOT NULL
EXEC sp_executesql N'DROP PROCEDURE dbo.x_CompareData'

IF OBJECT_ID ('dbo.x_CopyData' , 'P') IS NOT NULL
EXEC sp_executesql N'DROP PROCEDURE dbo.x_CopyData'

IF OBJECT_ID ('dbo.x_DefaultConstraint' , 'P') IS NOT NULL
EXEC sp_executesql N'DROP PROCEDURE dbo.x_DefaultConstraint'

IF OBJECT_ID ('dbo.x_FileConfiguration' , 'P') IS NOT NULL
EXEC sp_executesql N'DROP PROCEDURE dbo.x_FileConfiguration'

IF OBJECT_ID ('dbo.x_FileSpeed' , 'P') IS NOT NULL
EXEC sp_executesql N'DROP PROCEDURE dbo.x_FileSpeed'

IF OBJECT_ID ('dbo.x_FindDuplicates' , 'P') IS NOT NULL
EXEC sp_executesql N'DROP PROCEDURE dbo.x_FindDuplicates'

IF OBJECT_ID ('dbo.x_FindQuery' , 'P') IS NOT NULL
EXEC sp_executesql N'DROP PROCEDURE dbo.x_FindQuery'

IF OBJECT_ID ('dbo.x_IdentitySeed' , 'P') IS NOT NULL
EXEC sp_executesql N'DROP PROCEDURE dbo.x_IdentitySeed'

IF OBJECT_ID ('dbo.x_OperationStatus' , 'P') IS NOT NULL
EXEC sp_executesql N'DROP PROCEDURE dbo.x_OperationStatus'

IF OBJECT_ID ('dbo.x_ScheduleJob' , 'P') IS NOT NULL
EXEC sp_executesql N'DROP PROCEDURE dbo.x_ScheduleJob'

IF OBJECT_ID ('dbo.x_SessionStatus' , 'P') IS NOT NULL
EXEC sp_executesql N'DROP PROCEDURE dbo.x_SessionStatus'

IF OBJECT_ID ('dbo.x_ShowIndex' , 'P') IS NOT NULL
EXEC sp_executesql N'DROP PROCEDURE dbo.x_ShowIndex'

IF OBJECT_ID ('dbo.x_SystemConfiguration' , 'P') IS NOT NULL
EXEC sp_executesql N'DROP PROCEDURE dbo.x_SystemConfiguration'

IF OBJECT_ID ('dbo.x_SystemMemory' , 'P') IS NOT NULL
EXEC sp_executesql N'DROP PROCEDURE dbo.x_SystemMemory'

IF OBJECT_ID ('dbo.x_SystemVersion' , 'P') IS NOT NULL
EXEC sp_executesql N'DROP PROCEDURE dbo.x_SystemVersion'

GO

IF OBJECT_ID ('dbo.x_ShowDefaultConstraint' , 'P') IS NOT NULL
EXEC sp_executesql N'DROP PROCEDURE dbo.x_ShowDefaultConstraint'

IF OBJECT_ID ('dbo.x_ShowIdentitySeed' , 'P') IS NOT NULL
EXEC sp_executesql N'DROP PROCEDURE dbo.x_ShowIdentitySeed'

IF OBJECT_ID ('dbo.x_ShowIndexColumn' , 'P') IS NOT NULL
EXEC sp_executesql N'DROP PROCEDURE dbo.x_ShowIndexColumn'

IF OBJECT_ID ('v_ServerVersion' , 'TF') IS NOT NULL
EXEC sp_executesql N'DROP FUNCTION v_ServerVersion'

GO
