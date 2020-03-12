Cartoon Database
=====================

This is example database for the cartoon heroes.

```sql
EXEC DBAtools.dbo.x_FileConfiguration @Database='CARTOON';
GO
DBCC IND ('CARTOON' , 'dbo.HERO' , -1)
GO
DBCC TRACEON(3604)
DBCC PAGE ('CARTOON' , 1 , 312 , 3) WITH TABLERESULTS
GO
```

| Name | Size (MB) | Autogrowth | Growth (MB) | Growth (%) | State | Limit (MB) | Number | Type | File |
| - | - | - | - | - | - | - | - | - | - |
| Cartoon | 8 | UNLIMITED | 64 | 0 | ONLINE | -1 | 1 | DATA | C:\DATA\Microsoft SQL Server\Data\Cartoon.mdf |
| Cartoon_log | 8 | LIMITED | 64 | 0 | ONLINE | 2048 | 2 | LOG | C:\DATA\Microsoft SQL Server\Log\Cartoon_log.ldf |

![](/media/shot/20_03_12_cartoon_01.png)

```
0000000000000000:   30000c00 01000000 d4bd0a15 06000003 0023002d  0.......Ô½.......#.-
0000000000000014:   0039004d 00690063 006b0065 0079004d 006f0075  .9.M.i.c.k.e.y.M.o.u
0000000000000028:   00730065 00440069 0073006e 00650079 00        .s.e.D.i.s.n.e.y.
```

```
0000000000000000:   30000c00 02000000 7cc60a07 06000003 0023002b  0.......|Æ.......#.+
0000000000000014:   00370044 006f006e 0061006c 00640044 00750063  .7.D.o.n.a.l.d.D.u.c
0000000000000028:   006b0044 00690073 006e0065 007900             .k.D.i.s.n.e.y.
```

```
0000000000000000:   30000c00 03000000 82200b07 06000003 0023002d  0....... .......#.-
0000000000000014:   0045004a 006f0068 006e006e 00790042 00720061  .E.J.o.h.n.n.y.B.r.a
0000000000000028:   0076006f 00570061 0072006e 00650072 00200042  .v.o.W.a.r.n.e.r. .B
000000000000003C:   0072006f 0073002e 00                          .r.o.s...
```
