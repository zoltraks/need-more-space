Need More Space
===============

Hello, comrade. 

Here you will find a set of utility functions for your database.

This repository contains scripts for installation of selected utility functions.

[Jump to **Microsoft SQL Server** tools](docs/source/sqlserver.md)

[Jump to **MySQL** tools](docs/source/mysql.md)

[Google!](https://www.google.com/search?q=need+more+space&tbm=isch)

What you get
------------

| Procedure | Description |
| --------- | ----------- |
| x_ShowIndex |  Show indexes in database. |
| x_ShowIndexColumn | Show index columns for tables in database. |
| x_OperationStatus | Show system operation status. |
| x_FileConfiguration | Show database files configuration. |
| x_SystemMemory | Show basic information about memory amount and state. |
| x_ShowIdentitySeed | Show identity seed value for tables in database. |
| x_ShowDefaultContraint | Show default contraints. |
| x_FindDuplicates | Find duplicates in table. |
| x_CopyData | Copy data from one table to another. |

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

Notes
-----

Scripts are saved in **UTF16-LE** encoding because GitHub preview lacks indentation with spaces when using **UTF-8** (with or without BOM). 
Sorry for that.
