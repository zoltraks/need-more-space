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
| Show index column | Show index columns for tables in database. |
| Operation status | Show system operation status. |
| Find duplicates | Find duplicates in table. |
| File configuration | Show database files configuration. |
| System memory | Show basic information about memory amount and state. |
| Copy data | Copy data from one table to another. |

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
