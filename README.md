# PRO2003 – Work Requirement 3
## Improve and Protect Your PostgreSQL Database

### Project overview

This project extends the **E-Commerce Order Management System** developed in PRO2003 Work Requirements 1 and 2. The original PostgreSQL database, `ecommerce_db`, contains six related tables: `customer`, `category`, `product`, `orders`, `order_item`, and `payment`.

Work Requirement 3 focuses on reviewing normalization, evaluating indexing performance, demonstrating multi-statement database operations, applying least-privilege permissions, and testing backup and restoration.

### Environment

- **Database management system:** PostgreSQL 18.6
- **Database client:** DBeaver 26.2.2
- **Original database:** `ecommerce_db`
- **Restoration test database:** `ecommerce_db_restore`
- **SQL dialect:** PostgreSQL

### Work completed and evidence

| Area | Implementation and verified result | Supporting files |
|---|---|---|
| Database normalization | Reviewed entity separation, primary and foreign keys, and potential redundancy relating to order-item subtotals | [`3NF_Review.md`](3NF_Review.md), `screenshots/WR3_01_Database_Structure.png` |
| Index performance | Compared `EXPLAIN ANALYZE` before and after testing `idx_product_price`; PostgreSQL chose sequential scans in both runs | [`Index_Performance_Explanation.md`](Index_Performance_Explanation.md), `screenshots/WR3_02_Before_Index.png`, `screenshots/WR3_03_After_Index.png` |
| Multi-statement operation | Used an atomic PL/pgSQL `DO` block to update order status and product inventory, then restore the original values through compensating updates | `screenshots/WR3_10_Transaction_Execution.png`, `screenshots/WR3_11_Transaction_Verification.png` |
| Role-based permissions | Created `ecommerce_readonly` as a `NOLOGIN` role with CONNECT, USAGE, and SELECT permissions; verified that it lacked INSERT, UPDATE, and DELETE privileges on the six tables | `screenshots/WR3_05_Readonly_Role.png`, `screenshots/WR3_06_Role_Permissions.png` |
| Backup and recovery | Created a PostgreSQL dump, restored it into the separate `ecommerce_db_restore` database, and verified the six table counts | [`Backup_Restore_Instructions.md`](Backup_Restore_Instructions.md), `screenshots/WR3_07_Backup_Completed.png` through `screenshots/WR3_09_Restore_Verification.png` |

### Database normalization (3NF)

The schema separates customers, categories, products, orders, order items, and payments into individual relations. Each table has a primary key, while foreign keys express relationships between records. The `order_item` table resolves the many-to-many relationship between orders and products without repeating product lists inside an order record.

The review identified `order_item.subtotal` as a possible source of redundancy **depending on how it is defined and maintained**. Whether it should be stored depends on business rules concerning historical sale prices, quantities, and discounts; it should not be removed without clarifying those rules. The detailed analysis is provided in [`3NF_Review.md`](3NF_Review.md).

### Query optimization and indexing

The evaluation used the following query:

```sql
SELECT product_id, product_name, price
FROM product
WHERE price > 100
ORDER BY price DESC;
```

An index on product price was evaluated:

```sql
CREATE INDEX idx_product_price ON product (price DESC);
```

Both captured execution plans used a **sequential scan** followed by sorting. Each returned **12 rows** and filtered out **36 rows**. The scan and sort node times were lower in the later test, but these observations **do not prove an index speedup**, because PostgreSQL did not select an index scan. With only 48 products, a sequential scan may be cheaper than using the index. See [`Index_Performance_Explanation.md`](Index_Performance_Explanation.md) for the measurements and interpretation.

### Multi-statement operation and transaction behavior

The submitted PL/pgSQL `DO` block performed coordinated updates to product stock and order status, verified that rows were updated, and then restored the original values using additional `UPDATE` statements. The verification query confirmed:

| Field | Final verified value |
|---|---|
| `order_id` | 1 |
| `order_status` | `Pending` |
| `product_id` | 19 |
| `stock_quantity` | 63 |

**Important distinction:** A `DO` statement is executed atomically, but the screenshots demonstrate **compensating updates**, not a successful explicit `ROLLBACK`. The work should not be described as proof of an explicit rollback. An actual `BEGIN`/`ROLLBACK` demonstration, if required, must be carried out in one consistent database session with transaction settings configured appropriately.

### Security: roles and permissions

A PostgreSQL role named `ecommerce_readonly` was created with `NOLOGIN`. The role received database-level `CONNECT`, schema-level `USAGE`, and `SELECT` permission on the six existing application tables. Verification returned:

| Permission | Verified |
|---|---|
| SELECT | Allowed |
| INSERT | Not allowed |
| UPDATE | Not allowed |
| DELETE | Not allowed |

Since the role uses `NOLOGIN`, it serves as a permission role rather than a standalone user account. These checks concern the tested six tables, not every possible object or future user membership.

### Backup and restoration verification

The `ecommerce_db` database was backed up using PostgreSQL's dump functionality and restored to a **separate** database named `ecommerce_db_restore`. The following restored row counts were confirmed in DBeaver:

| Table | Restored rows |
|---|---:|
| `customer` | 80 |
| `category` | 8 |
| `product` | 48 |
| `orders` | 160 |
| `order_item` | 320 |
| `payment` | 128 |
| **Total** | **744** |

These counts match the previously observed source counts. They verify successful recovery of the expected table populations, but do not amount to a row-by-row checksum comparison. The physical backup file was retained locally and is **not included in this GitHub repository**. See [`Backup_Restore_Instructions.md`](Backup_Restore_Instructions.md) for the procedure.

### Running or reviewing the work

1. Install PostgreSQL and DBeaver, and connect to the **original** `ecommerce_db` database.
2. If starting from an empty environment, reconstruct the schema and seed data using the separate Requirement 1 and Requirement 2 deliverables. **Do not rerun destructive setup scripts against data you want to preserve.**
3. Open [`PRO2003_Requirement_3.sql`](PRO2003_Requirement_3.sql) in DBeaver and review each section **before** executing it. Administrative statements may require the `postgres` account or suitable privileges; the script is not intended to be rerun indiscriminately.
4. For recovery testing, follow [`Backup_Restore_Instructions.md`](Backup_Restore_Instructions.md) and target `ecommerce_db_restore`, **not** the original database.
5. Compare results with the authentic screenshots in the `screenshots/` folder.

### Repository structure

```text
PRO2003-Work-Requirement-3/
├── PRO2003_Requirement_3.sql
├── README.md
├── 3NF_Review.md
├── Index_Performance_Explanation.md
├── Backup_Restore_Instructions.md
└── screenshots/
    ├── WR3_01_Database_Structure.png
    ├── WR3_02_Before_Index.png
    ├── WR3_03_After_Index.png
    ├── WR3_04_Transaction_Preparation.png
    ├── WR3_05_Readonly_Role.png
    ├── WR3_06_Role_Permissions.png
    ├── WR3_07_Backup_Completed.png
    ├── WR3_08_Restore_Completed.png
    ├── WR3_09_Restore_Verification.png
    ├── WR3_10_Transaction_Execution.png
    └── WR3_11_Transaction_Verification.png
```





