# PostgreSQL Backup and Restore Procedure

These steps describe the DBeaver PostgreSQL 18 procedure used in the requirement.

1. Connect to the **original** `ecommerce_db` database. Right-click the database (not the parent Databases folder) and choose **Tools → Backup** / PostgreSQL dump.
2. Select **Complete backup**, including schema and data. Use a PostgreSQL **Custom** backup format. Record the actual filename and directory locally. Keep the `.backup` file safe; it is not included in this package.
3. Run `pg_dump`. Keep a screenshot of the completed progress log (`WR3_07_Backup_Completed.png`).
4. In a `postgres` maintenance-database connection, run `CREATE DATABASE ecommerce_db_restore;` **only if not already present**. Do not drop the original `ecommerce_db`.
5. Connect DBeaver directly to `ecommerce_db_restore`. Right-click the actual database → **Tools → Restore**. Select the saved custom backup, leave **Create database** and **Clean** unchecked, and choose **Discard objects owner** as appropriate for the target. Confirm the destination is the restore database.
6. Run restore and review the full progress log for errors (`WR3_08_Restore_Completed.png`). A line saying a task finished does not, on its own, rule out warnings or failures elsewhere in the log.
7. Connected to `ecommerce_db_restore`, execute:

```sql
SELECT (SELECT COUNT(*) FROM customer) AS customers,
       (SELECT COUNT(*) FROM category) AS categories,
       (SELECT COUNT(*) FROM product) AS products,
       (SELECT COUNT(*) FROM orders) AS orders,
       (SELECT COUNT(*) FROM order_item) AS order_items,
       (SELECT COUNT(*) FROM payment) AS payments;
```

Observed restored row counts: **80 customers, 8 categories, 48 products, 160 orders, 320 order items, 128 payments (744 total)**. Screenshot: `WR3_09_Restore_Verification.png`. This confirms table existence and matching counts, but not a full byte-by-byte integrity comparison.

**Command-line alternative** (PowerShell, adjust the actual path):

```powershell
& "C:\Program Files\PostgreSQL\18\bin\pg_restore.exe" -h localhost -p 5432 -U postgres -d ecommerce_db_restore --no-owner --no-privileges "C:\path\to\your-actual-backup.backup"
```

Do not place passwords inside commands or commit real credentials or backup copies containing sensitive information.
