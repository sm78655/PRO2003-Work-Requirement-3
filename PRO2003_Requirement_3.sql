-- PRO2003 Work Requirement 3 | E-commerce Order Management System
-- Run against the ORIGINAL ecommerce_db, as postgres/owner.
-- Run sections separately. Do not rerun Requirement 1 schema: it drops tables.
-- Backup/restore is done with pg_dump/pg_restore, not SQL.

-- 1. SCHEMA REVIEW (read-only)
SELECT table_name, column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema='public'
  AND table_name IN ('customer','category','product','orders','order_item','payment')
ORDER BY table_name, ordinal_position;

-- 2A. BEFORE INDEX: only run DROP if idx_product_price is your demonstration index.
-- DROP INDEX IF EXISTS public.idx_product_price;
-- EXPLAIN (ANALYZE, BUFFERS) SELECT product_id, product_name, price
-- FROM public.product WHERE price > 100 ORDER BY price DESC;
-- The BEFORE plan was captured in WR3_02_Before_Index.png, BEFORE index creation.

-- 2B. AFTER INDEX (idempotent)
CREATE INDEX IF NOT EXISTS idx_product_price ON public.product (price DESC);
ANALYZE public.product;
EXPLAIN (ANALYZE, BUFFERS)
SELECT product_id, product_name, price
FROM public.product
WHERE price > 100
ORDER BY price DESC;
-- Both observed plans used Seq Scan + quicksort; do not claim the index made it faster.

-- 3. MULTI-STATEMENT ATOMIC OPERATION (original demonstrated approach)
-- Precondition observed: order 1 = Pending; product 19 stock = 63.
-- This block applies two related UPDATEs and then restores the original data
-- with compensating UPDATEs. It is NOT an explicit ROLLBACK demonstration.
-- A failure anywhere in the DO statement causes PostgreSQL to roll back that statement.
DO $$
DECLARE
    old_stock INTEGER;
    old_status VARCHAR(20);
    updated_rows INTEGER;
BEGIN
    SELECT stock_quantity INTO old_stock
      FROM public.product WHERE product_id=19 FOR UPDATE;
    SELECT order_status INTO old_status
      FROM public.orders WHERE order_id=1 FOR UPDATE;
    IF old_stock IS NULL OR old_stock < 3 OR old_status IS DISTINCT FROM 'Pending' THEN
        RAISE EXCEPTION 'Invalid order state or insufficient inventory';
    END IF;
    UPDATE public.product SET stock_quantity=stock_quantity-3 WHERE product_id=19;
    GET DIAGNOSTICS updated_rows = ROW_COUNT;
    IF updated_rows <> 1 THEN RAISE EXCEPTION 'Inventory update failed'; END IF;
    UPDATE public.orders SET order_status='Processing' WHERE order_id=1;
    GET DIAGNOSTICS updated_rows = ROW_COUNT;
    IF updated_rows <> 1 THEN RAISE EXCEPTION 'Order update failed'; END IF;
    RAISE NOTICE 'Transaction updates successful';
    UPDATE public.product SET stock_quantity=old_stock WHERE product_id=19;
    UPDATE public.orders SET order_status=old_status WHERE order_id=1;
    RAISE NOTICE 'Original values restored successfully';
END $$;

SELECT o.order_id, o.order_status, p.product_id, p.stock_quantity
FROM public.orders o CROSS JOIN public.product p
WHERE o.order_id=1 AND p.product_id=19;

-- OPTIONAL explicit ROLLBACK demo: run in ONE SQL session with autocommit disabled,
-- and inspect state before rollback. Do not execute blindly statement by statement
-- in DBeaver Auto mode (causes 'no transaction in progress').
-- BEGIN;
-- UPDATE public.product SET stock_quantity=stock_quantity-3
-- WHERE product_id=19 AND stock_quantity>=3;
-- UPDATE public.orders SET order_status='Processing'
-- WHERE order_id=1 AND order_status='Pending';
-- SELECT stock_quantity FROM public.product WHERE product_id=19;
-- SELECT order_status FROM public.orders WHERE order_id=1;
-- ROLLBACK;

-- 4. RESTRICTED ROLE & LEAST PRIVILEGE (run as a privileged user)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='ecommerce_readonly') THEN
        CREATE ROLE ecommerce_readonly NOLOGIN;
    END IF;
END $$;
GRANT CONNECT ON DATABASE ecommerce_db TO ecommerce_readonly;
GRANT USAGE ON SCHEMA public TO ecommerce_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO ecommerce_readonly;
-- Protect later-created tables (applies to tables created by the current grantor):
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO ecommerce_readonly;

SELECT rolname, rolcanlogin, rolsuper, rolcreatedb, rolcreaterole
FROM pg_roles WHERE rolname='ecommerce_readonly';
SELECT table_name,
 has_table_privilege('ecommerce_readonly','public.'||table_name,'SELECT') AS can_select,
 has_table_privilege('ecommerce_readonly','public.'||table_name,'INSERT') AS can_insert,
 has_table_privilege('ecommerce_readonly','public.'||table_name,'UPDATE') AS can_update,
 has_table_privilege('ecommerce_readonly','public.'||table_name,'DELETE') AS can_delete
FROM information_schema.tables
WHERE table_schema='public' AND table_type='BASE TABLE'
ORDER BY table_name;

-- 5. AFTER RESTORING, connect THIS QUERY to ecommerce_db_restore (NOT original).
-- SELECT (SELECT COUNT(*) FROM customer) AS customers,
--        (SELECT COUNT(*) FROM category) AS categories,
--        (SELECT COUNT(*) FROM product) AS products,
--        (SELECT COUNT(*) FROM orders) AS orders,
--        (SELECT COUNT(*) FROM order_item) AS order_items,
--        (SELECT COUNT(*) FROM payment) AS payments;
