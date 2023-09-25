---
layout: post
title: Getting a User's Table Privileges in PostgreSQL
categories: [Blog]
tags: [postgresql]
---

When working with postgreSQL (or any database management system, for that matter) oftentimes you want to see which tables a user has access to, and what they can do with those tables. One of the ways to accomplish this is with the `INFORMATION_SCHEMA` tables. For instance, let's say we want to see what tables `testuser1` has access to:

```
SELECT 
    grantee,
    table_schema AS schema,
    table_name,
    privilege_type AS privilege,
    grantor
FROM information_schema.table_privileges
WHERE grantee = 'testuser1';
```

In my database, this gives me the following results:

```
  grantee  | schema | table_name | privilege  | grantor  
-----------+--------+------------+------------+----------
 testuser1 | public | table3     | INSERT     | postgres
 testuser1 | public | table3     | SELECT     | postgres
 testuser1 | public | table3     | UPDATE     | postgres
 testuser1 | public | table3     | DELETE     | postgres
 testuser1 | public | table3     | TRUNCATE   | postgres
 testuser1 | public | table3     | REFERENCES | postgres
 testuser1 | public | table3     | TRIGGER    | postgres
 testuser1 | public | table1     | SELECT     | postgres
(8 rows)
```

Essentially, `testuser1` can `SELECT` on `table1`, and has all prileges on `table3`. The `grantor` is the role that _gave_ these roles to `testuser1` (the "grantee"). This is a quick way to check a user's table permissions!
