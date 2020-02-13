SELECT c.relname As tname, CASE WHEN c.relkind = 'v' THEN 'view' ELSE 'table' END As type, 
    pg_get_userbyid(c.relowner) AS towner, t.spcname AS tspace, 
    n.nspname AS sname,  d.description
   FROM pg_class As c
   LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
   LEFT JOIN pg_tablespace t ON t.oid = c.reltablespace
   LEFT JOIN pg_description As d ON (d.objoid = c.oid AND d.objsubid = 0)
   WHERE c.relkind IN('r', 'v')
   ORDER BY n.nspname, c.relname ;