# Case Study #2 - Pizza Runner
## 🍕 A. Pizza Metrics
### Data cleaning

**Temporary table `customer_orders_clean`**
- Create temporary table `customer_orders_clean`
- Add row numbers to indicate pizza number
- Convert string `'null'` and blank `''` values to `NULL`

```sql
CREATE TEMP TABLE IF NOT EXISTS customer_orders_clean AS
SELECT
  row_number() over() AS pizza_number,
  order_id,
  customer_id,
  pizza_id,
  CASE
    WHEN exclusions IN ('null', '') THEN NULL
    ELSE exclusions
  END AS exclusions,
  CASE
    WHEN extras IN ('null', '') THEN NULL
    ELSE extras
  END AS extras,
  order_time
FROM
  customer_orders;
```
| pizza_number | order_id | customer_id | pizza_id | exclusions | extras | order_time          |
|--------------|----------|-------------|----------|------------|--------|---------------------|
| 1            | 1        | 101         | 1        | null       | null   | 2020-01-01 18:05:02 |
| 2            | 2        | 101         | 1        | null       | null   | 2020-01-01 19:00:52 |
| 3            | 3        | 102         | 1        | null       | null   | 2020-01-02 23:51:23 |
| 4            | 3        | 102         | 2        | null       | null   | 2020-01-02 23:51:23 |
| 5            | 4        | 103         | 1        | 4          | null   | 2020-01-04 13:23:46 |
| 6            | 4        | 103         | 1        | 4          | null   | 2020-01-04 13:23:46 |
| 7            | 4        | 103         | 2        | 4          | null   | 2020-01-04 13:23:46 |
| 8            | 5        | 104         | 1        | 1          | null   | 2020-01-08 21:00:29 |
| 9            | 6        | 101         | 2        | null       | null   | 2020-01-08 21:03:13 |
| 10           | 7        | 105         | 2        | 1          | null   | 2020-01-08 21:20:29 |
| 11           | 8        | 102         | 1        | null       | null   | 2020-01-09 23:54:33 |
| 12           | 9        | 103         | 1        | 4          | 1, 5   | 2020-01-10 11:22:59 |
| 13           | 10       | 104         | 1        | null       | null   | 2020-01-11 18:34:49 |
| 14           | 10       | 104         | 1        | 2, 6       | 1, 4   | 2020-01-11 18:34:49 |

**Temporary table `runner_orders_clean`**
- `pickup_time`: convert `'null'` values to `NULL` and cast to timestamp
- `distance`: convert `'null'` values to `NULL`, remove 'km' suffix and cast to numeric type
- `duration`: convert `'null'` values to `NULL`, remove `'min', 'minute', 'minutes'` suffixes and cast to integer
- `cancellation`: convert `'null'` values to `NULL`

```sql
CREATE TEMP TABLE IF NOT EXISTS runner_orders_clean AS
SELECT
  order_id,
  runner_id,
  CASE
    WHEN pickup_time = 'null' THEN NULL
    ELSE pickup_time :: timestamp
  END AS pickup_time,
  CASE
    WHEN distance = 'null' THEN NULL
    ELSE rtrim(distance, 'km') :: numeric
  END AS distance,
  CASE
    WHEN duration = 'null' THEN NULL
    ELSE rtrim(duration, 'minutes') :: integer
  END AS duration,
  CASE
    WHEN cancellation IN ('null', '') THEN NULL
    ELSE cancellation
  END AS cancellation
FROM
  runner_orders;
```

| order_id | runner_id | pickup_time         | distance | duration | cancellation            |
|----------|-----------|---------------------|----------|----------|-------------------------|
| 1        | 1         | 2020-01-01 18:15:34 | 20       | 32       | null                    |
| 2        | 1         | 2020-01-01 19:10:54 | 20       | 27       | null                    |
| 3        | 1         | 2020-01-03 00:12:37 | 13.4     | 20       | null                    |
| 4        | 2         | 2020-01-04 13:53:03 | 23.4     | 40       | null                    |
| 5        | 3         | 2020-01-08 21:10:57 | 10       | 15       | null                    |
| 6        | 3         | null                | null     | null     | Restaurant Cancellation |
| 7        | 2         | 2020-01-08 21:30:45 | 25       | 25       | null                    |
| 8        | 2         | 2020-01-10 00:15:02 | 23.4     | 15       | null                    |
| 9        | 2         | null                | null     | null     | Customer Cancellation   |
| 10       | 1         | 2020-01-11 18:50:20 | 10       | 10       | null                    |

### 🚀 Answers

**1. How many pizzas were ordered?**

```sql
SELECT
  count(pizza_id) AS ordered_pizzas
FROM
  customer_orders_clean;
```

| ordered_pizzas |
|----------------|
| 14             |

**2. How many unique customer orders were made?**

```sql
SELECT
  count(DISTINCT order_id) as unique_orders
FROM
  customer_orders_clean;
```

| unique_orders |
|---------------|
| 10            |

**3. How many successful orders were delivered by each runner?**

```sql
SELECT
  runner_id,
  count(DISTINCT order_id)
FROM
  runner_orders_clean
WHERE
  cancellation IS NULL
GROUP BY
  runner_id;
```

| runner_id | count |
|-----------|-------|
| 1         | 4     |
| 2         | 3     |
| 3         | 1     |

**4. How many of each type of pizza was delivered?**

```sql
SELECT
  pizza_name,
  count(pizza_id)
FROM
  customer_orders_clean
  LEFT JOIN pizza_names USING(pizza_id)
  LEFT JOIN runner_orders_clean USING(order_id)
WHERE
  cancellation IS NULL
GROUP BY
  pizza_name
ORDER BY
  pizza_name;
```

| pizza_name | count |
|------------|-------|
| Meatlovers | 9     |
| Vegetarian | 3     |

**5. How many Vegetarian and Meatlovers were ordered by each customer?**

```sql
SELECT
  customer_id,
  sum(
    CASE
      WHEN pizza_name = 'Meatlovers' THEN 1
      ELSE 0
    END
  ) AS meatlovers_orders,
  sum(
    CASE
      WHEN pizza_name = 'Vegetarian' THEN 1
      ELSE 0
    END
  ) AS vegetarian_orders
FROM
  customer_orders_clean
  LEFT JOIN pizza_names USING(pizza_id)
GROUP BY
  customer_id
ORDER BY
  customer_id;
```

| customer_id | meatlovers_orders | vegetarian_orders |
|-------------|-------------------|-------------------|
| 101         | 2                 | 1                 |
| 102         | 2                 | 1                 |
| 103         | 3                 | 1                 |
| 104         | 3                 | 0                 |
| 105         | 0                 | 1                 |


**6. What was the maximum number of pizzas delivered in a single order?**

```sql
SELECT
  max(count) AS max_pizzas_in_single_order
FROM
  (
    SELECT
      order_id,
      count(order_id)
    FROM
      customer_orders_clean
    GROUP BY
      order_id
  ) a;
```

| max_pizzas_in_single_order |
|----------------------------|
| 3                          |

**7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?**

```sql
SELECT
  customer_id,
  sum(
    CASE
      WHEN exclusions IS NOT NULL
      OR extras IS NOT NULL THEN 1
      ELSE 0
    END
  ) AS CHANGED,
  sum(
    CASE
      WHEN exclusions IS NULL
      AND extras IS NULL THEN 1
      ELSE 0
    END
  ) AS unchanged
FROM
  customer_orders_clean
  LEFT JOIN runner_orders_clean USING(order_id)
  LEFT JOIN pizza_names USING(pizza_id)
WHERE
  cancellation IS NULL
GROUP BY
  customer_id
ORDER BY
  customer_id;
```

| customer_id | changed | unchanged |
|-------------|---------|-----------|
| 101         | 0       | 2         |
| 102         | 0       | 3         |
| 103         | 3       | 0         |
| 104         | 2       | 1         |
| 105         | 1       | 0         |

**8. How many pizzas were delivered that had both exclusions and extras?**

```sql
SELECT
  count(*)
FROM
  customer_orders_clean
  LEFT JOIN runner_orders_clean USING(order_id)
WHERE
  cancellation IS NULL
  AND (
    extras IS NOT NULL
    AND exclusions IS NOT NULL
  );
```
| count |
| --- |
| 1 |

**9.  What was the total volume of pizzas ordered for each hour of the day?**

```sql
WITH hours_series AS (
  SELECT
    generate_series(0, 23, 1) AS hour
)
SELECT
  hour,
  count(order_id) AS orders
FROM
  hours_series
  LEFT JOIN customer_orders_clean ON hours_series.hour = date_part('hour', order_time)
GROUP BY
  hour
ORDER BY
  hour;
```

| hour | orders |
|------|--------|
| 0    | 0      |
| 1    | 0      |
| 2    | 0      |
| 3    | 0      |
| 4    | 0      |
| 5    | 0      |
| 6    | 0      |
| 7    | 0      |
| 8    | 0      |
| 9    | 0      |
| 10   | 0      |
| 11   | 1      |
| 12   | 0      |
| 13   | 3      |
| 14   | 0      |
| 15   | 0      |
| 16   | 0      |
| 17   | 0      |
| 18   | 3      |
| 19   | 1      |
| 20   | 0      |
| 21   | 3      |
| 22   | 0      |
| 23   | 3      |

**10. What was the volume of orders for each day of the week?**

```sql
CREATE TEMP TABLE IF NOT EXISTS week_days (id INT, day_name varchar(12));

INSERT INTO
  week_days
VALUES
  (1, 'Monday'),
  (2, 'Tuesday'),
  (3, 'Wednesday'),
  (4, 'Thursday'),
  (5, 'Friday'),
  (6, 'Saturday'),
  (7, 'Sunday');

SELECT
  id AS day_id,
  day_name,
  count(order_id)
FROM
  week_days w
  LEFT JOIN customer_orders_clean c ON w.id = date_part('dow', c.order_time)
GROUP BY
  day_id,
  day_name
ORDER BY
  day_id;
```
| day_id | day_name  | count |
|--------|-----------|-------|
| 1      | Monday    | 0     |
| 2      | Tuesday   | 0     |
| 3      | Wednesday | 5     |
| 4      | Thursday  | 3     |
| 5      | Friday    | 1     |
| 6      | Saturday  | 5     |
| 7      | Sunday    | 0     |
