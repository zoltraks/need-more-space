CHANGES
=======

2020-11-05
----------

Added options ``@Output`` and ``@Retain`` to give ability of saving results of **x_FileSpeed* to output table for further reporting.

2020-11-01
----------

Changed **SqlServer** procedure **x_ShowIndex** for displaying index information to optionally include column names and removed **x_ShowIndexColumn** as it became obsolete.

Added new procedure for **SqlServer** for showing I/O bottlenecks **x_FileSpeed**.

2020-08-26
----------

Added new procedure for **SqlServer** for comparing data in tables **x_CompareData**.

Hope you will like it.

2020-08-24
----------

Added new function for **SqlServer** for easy text splitting **v_SplitText**.

2020-04-01
----------

Added new procedure for **SqlServer** to help scheduling jobs **x_ScheduleJob**.

Check this out.

2020-03-14
----------

Changed names for x_IdentitySeed from x_ShowIdentitySeed, x_DefaultConstraint from x_ShowDefaultConstraint.

Introduced purge script for removal.

2020-03-07
----------

Added new function for **SqlServer** to help copying table data **x_CopyData**.

Check this out.

2020-03-05
----------

Fix EXECUTE operation in **SqlServer** scripts using following expression ``^EXECUTE \((N'[^']+')\)`` with ``EXEC sp_executesql $1``.

2019-11-01
----------

Publication of repository

2018-07-03
----------

Repository created
