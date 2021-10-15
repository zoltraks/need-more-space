<!--
<style>
table {
    width: 100%;
}
.table-20 table td:first-child  { width: 20%; min-width: 150px; }
</style>
-->
Need More Space
===============

Hello, comrade. 

Here you will find a set of utility functions for your database.

This repository contains scripts for installation of selected utility functions.

```
First coffee then rocket science
```

[Jump to **Microsoft SQL Server** tools →](docs/source/sqlserver.md)

[Jump to **MySQL** tools →](docs/source/mysql.md)

[Google!](https://www.google.com/search?q=need+more+space&tbm=isch)

What you get
------------

This repository contains database management scripts.

Designed to be used by administrators and developers for doing maintenance or other special database tasks.

## Microsoft SQL Server ##

[Installation script for all functions **SQLServer-All.sql** →](sql/SQLServer-All.sql)
[download](https://raw.githubusercontent.com/zoltraks/need-more-space/master/sql/SQLServer-All.sql)

<div class="table-20">

| Procedure | Description |
| --------- | ----------- |
| [x_CompareData](docs/source/sqlserver.md#compare-data) | Compare data from one table with another. |
| [x_CopyData](docs/source/sqlserver.md#copy-data) | Copy data from one table to another. |
| [x_DefaultContraint](docs/source/sqlserver.md#default-constraint) | Show default contraints. |
| [x_FileConfiguration](docs/source/sqlserver.md#file-configuration) | Show database files configuration. |
| [x_FileSpeed](docs/source/sqlserver.md#file-speed) | Show I/O speed of database files. |
| [x_FindDuplicates](docs/source/sqlserver.md#find-duplicates) | Find duplicates in table. |
| [x_FindQuery](docs/source/sqlserver.md#find-query) | Find specific query in Query Store. |
| [x_IdentitySeed](docs/source/sqlserver.md#identity-seed) | Show identity seed value for tables in database. |
| [x_OperationStatus](docs/source/sqlserver.md#operation-status) | Show system operation status. |
| [x_ScheduleJob](docs/source/sqlserver.md#schedule-job) | Add job and schedule execution plan. |
| [x_SessionStatus](docs/source/sqlserver.md#session-status) | Show current active sessions with information about state and transaction isolation level. |
| [x_ShowIndex](docs/source/sqlserver.md#show-index) | Show indexes and optionally columns included for one or more tables. |
| [x_SystemMemory](docs/source/sqlserver.md#system-memory) | Show basic information about memory amount and state. |
| [x_SystemVersion](docs/source/sqlserver.md#system-version) | Show version information. |

</div>

<div class="table-20">

| Function | Description |
| -------- | ----------- |
| [v_ColumnType](docs/source/sqlserver.md#column-type) | Script definition for data type. |
| [v_SplitText](docs/source/sqlserver.md#split-text) | Split text to table. |
| [v_WaitType](docs/source/sqlserver.md#wait-types) | Return table of wait type descriptions. |

</div>

## MySQL ##

<div class="table-20">

| Procedure | Description |
| --------- | ----------- |
| [x_ShowStorageEngineSize](docs/source/mysql.md#show-storage-engine-size) | Display size taken by data and index for all storage engines used. |

</div>

## SQLite ##

Are you joking?

You may however check [**schema**](schema/) catalog for some database create scripts.


Changes
-------

[List of changes](CHANGES.md)

Build
-----

You may use script [merge.sh](script/merge.sh) to build all SQL scripts into **All** files.

```
MINGW64 /need-more-space/script (master)
$ ./merge.sh
```

Works also with "Git Bash".

Tips
----

[Read more here →](docs/source/tips.md)

Notes
-----

Scripts are saved in **UTF16-LE** encoding for some reasons. 
One is that currently GitHub preview lacks indentation with spaces when using **UTF-8** (checked with or without BOM).
