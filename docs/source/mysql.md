MySQL
=====

MySQL lacks support for optional parameters, so most of them are not using any. Look at this famous [Bug #15975](https://bugs.mysql.com/bug.php?id=15975). And because of that you will not find useful **@Help** or **@Pretend** parameters. You need to check this documentation for descriptions instead.

Have fun.

Show storage engine size
------------------------

[Installation script for x_ShowStorageEngineSize](../../sql/MySQL/x_ShowStorageEngineSize.sql)

Display size taken by data and index for all storage engines used.

```sql
CALL `x_ShowStorageEngineSize`() ;
```

| Engine | Tables | Schema | Rows | Data [GB] | Index [GB] | Total [GB] |
| ------ | ------ | ------ | ---- | --------- | ---------- | ---------- |
| InnoDB | 34 | mysql | 3276 | 0.00 | 0.00 | 0.00 |
| PERFORMANCE_SCHEMA | 103 | performance_schema | 4727990 | 0.00 | 0.00 | 0.00 |
| CSV | 2 | mysql | 4 | 0.00 | 0.00 | 0.00 |
