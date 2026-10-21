# Index Performance Evaluation

**Query:** `SELECT product_id, product_name, price FROM product WHERE price > 100 ORDER BY price DESC;`

**Index tested:** `CREATE INDEX idx_product_price ON product (price DESC);`

| Observation | Before index | After index |
|---|---|---|
| Access method | Sequential Scan on product | Sequential Scan on product |
| Sort | Quicksort, 25 KB | Quicksort, 25 KB |
| Returned / filtered-out rows | 12 / 36 | 12 / 36 |
| Sequential scan actual time | 0.438–0.440 ms | 0.032–0.036 ms |
| Sort node actual time | 0.810–0.811 ms | 0.073–0.074 ms |

**Interpretation:** PostgreSQL chose a `Seq Scan` and explicit sorting in both measured runs, although an index on `price DESC` was available in the second run. For a table of only 48 rows, accessing the full table can be cheaper than the overhead of an index traversal. The observed times fell on the second run, but this cannot be attributed to the index because the query plan did not use it; warm buffers/caches, planning overhead and natural timing noise may explain the difference. The captured figures describe the scan and sort *nodes*, not full end-to-end execution times; the bottom of the plans should be captured if total execution times are to be reported.

**Conclusion:** The index is valid and may be worth reevaluating when the product table becomes much larger, especially for selective range predicates or sorted queries. This specific comparison provides no evidence that PostgreSQL benefited from it. Evidence: `WR3_02_Before_Index.png`, `WR3_03_After_Index.png`.
