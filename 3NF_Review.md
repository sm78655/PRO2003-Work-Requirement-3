# Third Normal Form (3NF) Review

**Domain:** E-Commerce Order Management System; tables: `customer`, `category`, `product`, `orders`, `order_item`, `payment`.

**First Normal Form (1NF):** The design represents customers, products, orders, order lines and payments as separate relations with scalar columns and individual primary keys. There are no repeating product columns within `orders`; each order's lines appear in `order_item`.

**Second Normal Form (2NF):** Each table uses one surrogate primary key (`*_id`), so there is no partial dependency on a *composite primary key*. The many-to-many relation between `orders` and `product` is correctly resolved by `order_item` with foreign keys `order_id` and `product_id`. This alone does not prove the absence of every business-level dependency.

**Third Normal Form (3NF):** Category details (`category_name`, `description`) are stored in `category`, not repeated in `product`; customer details are stored in `customer`, not copied into each order; product descriptions/prices are kept in `product`, and `orders` refers to a customer by ID. Thus the core design avoids obvious transitive dependencies and unnecessary duplication. Payments are stored separately so multiple payment rows can be associated with an order under the schema.

**Limitation / potential redundancy:** `order_item.subtotal` is stored alongside `quantity`, and product `price` is held in `product`. If subtotal is always recalculated as `quantity × product.price`, the stored subtotal creates potential inconsistency; a later price change could also make historical totals inaccurate. An improved design would store `unit_price_at_order` on each line, with a consistent policy for deriving or recording `subtotal`, and validate totals at the application level.
**Conclusion:** The six-table layout is broadly consistent with 3NF principles for its intended model, but subtotal semantics and historical prices require attention. No structural changes were made during Requirement 3 because the database was already populated and used in earlier requirements.
