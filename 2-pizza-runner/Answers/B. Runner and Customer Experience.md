# Case Study #2 - Pizza Runner
## 🛵 B.  Runner and Customer Experience

**1. How many runners signed up for each 1 week period? (i.e. week starts `2020-01-01`)**

```sql 
SELECT
  date_part('week', registration_date) AS week,
  count(*) AS runners_signed_up
FROM
  runners
GROUP BY
  week
ORDER BY
  week;
```

| week | runners_signed_up |
|------|-------------------|
| 1    | 2                 |
| 2    | 1                 |
| 3    | 1                 |


**2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?**

```sql
WITH avg_time_per_runner AS (
  SELECT
    runner_id,
    order_id,
    order_time,
    pickup_time,
    avg(pickup_time - order_time) AS avg_arrival
  FROM
    customer_orders_clean
    LEFT JOIN runner_orders_clean USING (order_id)
  WHERE
    pickup_time IS NOT NULL
  GROUP BY
    runner_id,
    order_id,
    order_time,
    pickup_time
)
SELECT
  runner_id,
  concat_ws(
    ' ',
    date_part('minutes', avg(avg_arrival)),
    'minutes and',
    round(
      date_part('seconds', avg(avg_arrival)) :: numeric,
      0
    ),
    'seconds'
  ) AS average_pickup_time
FROM
  avg_time_per_runner
GROUP BY
  runner_id
ORDER BY
  runner_id;
```
| runner_id | average_pickup_time       |
|-----------|---------------------------|
| 1         | 14 minutes and 20 seconds |
| 2         | 20 minutes and 1 seconds  |
| 3         | 10 minutes and 28 seconds |


**3. Is there any relationship between the number of pizzas and how long the order takes to prepare?**

```sql
WITH preparation_time AS (
  SELECT
    count(*) AS pizzas_single_order,
    avg(pickup_time - order_time) AS avg_prep_time
  FROM
    customer_orders_clean c
    LEFT JOIN runner_orders_clean r USING (order_id)
  WHERE
    cancellation IS NULL
  GROUP BY
    order_id
)
SELECT
  pizzas_single_order,
  date_part('minutes', avg(avg_prep_time)) AS preparation_time
FROM
  preparation_time
GROUP BY
  pizzas_single_order;
```

| pizzas_single_order | preparation_time |
|---------------------|------------------|
| 1                   | 12               |
| 2                   | 18               |
| 3                   | 29               |

**4. What was the average distance travelled for each customer?**

```sql
SELECT
  customer_id,
  round(avg(distance :: numeric), 1) AS avg_distance_km
FROM
  customer_orders_clean c
  LEFT JOIN runner_orders_clean r USING (order_id)
WHERE
  cancellation IS NULL
GROUP BY
  customer_id
ORDER BY
  customer_id;
```

| customer_id | avg_distance_km |
|-------------|-----------------|
| 101         | 20.0            |
| 102         | 16.7            |
| 103         | 23.4            |
| 104         | 10.0            |
| 105         | 25.0            |

**5. What was the difference between the longest and shortest delivery times for all orders?**

```sql
SELECT
  max(duration) - min(duration) AS delivery_diff
FROM
  runner_orders_clean;
```

| delivery_diff |
|---------------|
| 30            |

**6. What was the average speed for each runner for each delivery and do you notice any trend for these values?**

```sql
SELECT
  runner_id,
  order_id,
  round(distance :: numeric /(duration :: numeric / 60.0), 1) AS speed
FROM
  runner_orders_clean
WHERE
  cancellation IS NULL
ORDER BY
  runner_id,
  order_id;
```

| runner_id | order_id | speed |
|-----------|----------|-------|
| 1         | 1        | 37.5  |
| 1         | 2        | 44.4  |
| 1         | 3        | 40.2  |
| 1         | 10       | 60.0  |
| 2         | 4        | 35.1  |
| 2         | 7        | 60.0  |
| 2         | 8        | 93.6  |
| 3         | 5        | 40.0  |

**7. What is the successful delivery percentage for each runner?**

```sql
WITH deliveries AS (
  SELECT
    runner_id,
    count(order_id) AS total_orders,
    sum(
      CASE
        WHEN cancellation IS NULL THEN 1
        ELSE 0
      END
    ) AS delivered_orders
  FROM
    runner_orders_clean
  GROUP BY
    runner_id
)
SELECT
  runner_id,
  round(100 * delivered_orders :: numeric / total_orders, 0) AS successful_deliveries_pct
FROM
  deliveries
ORDER BY
  runner_id;
```
