# Case Study #2 - Pizza Runner
## 💵 D. Pricing and Ratings
**1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?**

```sql
SELECT
  sum(
    CASE
      WHEN pizza_name = 'Meatlovers' THEN 12
      ELSE 10
    END
  ) AS total
FROM
  customer_orders_clean
  LEFT JOIN runner_orders_clean USING (order_id)
  LEFT JOIN pizza_names USING(pizza_id)
WHERE
  cancellation IS NULL
```

| total |
|-------|
| 138   |

2. What if there was an additional $1 charge for any pizza extras?
- Add cheese is $1 extra

**3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.**

```sql
CREATE TABLE ratings (order_id int, rating int);

INSERT INTO
  ratings (order_id, rating)
VALUES
  (1, 4),
  (2, 5),
  (3, 2),
  (4, 5),
  (5, 5),
  (7, 3),
  (8, 4),
  (10, 1);

SELECT
  *
FROM
  ratings;
```


**4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?**
- `customer_id`
- `order_id`
- `runner_id`
- `rating`
- `order_time`
- `pickup_time`
- Time between order and pickup
- Delivery duration
- Average speed
- Total number of pizzas

```sql 
SELECT
  customer_id,
  order_id,
  runner_id,
  rating,
  order_time,
  pickup_time,
  date_part('minutes', pickup_time - order_time) AS time_between_order_and_pickup,
  duration,
  round(distance :: numeric /(duration :: numeric / 60.0), 1) AS speed,
  count(order_id) AS pizza_count
FROM
  customer_orders_clean
  LEFT JOIN runner_orders_clean USING(order_id)
  LEFT JOIN ratings USING(order_id)
WHERE
  cancellation IS NULL
GROUP BY
  customer_id,
  order_id,
  runner_id,
  rating,
  order_time,
  pickup_time,
  time_between_order_and_pickup,
  duration,
  speed
ORDER BY
  customer_id;
```

| customer_id | order_id | runner_id | rating | order_time          | pickup_time         | time_between_order_and_pickup | duration | speed | pizza_count |
|-------------|----------|-----------|--------|---------------------|---------------------|-------------------------------|----------|-------|-------------|
| 101         | 1        | 1         | 4      | 2020-01-01 18:05:02 | 2020-01-01 18:15:34 | 10                            | 32       | 37.5  | 1           |
| 101         | 2        | 1         | 5      | 2020-01-01 19:00:52 | 2020-01-01 19:10:54 | 10                            | 27       | 44.4  | 1           |
| 102         | 3        | 1         | 2      | 2020-01-02 23:51:23 | 2020-01-03 00:12:37 | 21                            | 20       | 40.2  | 2           |
| 102         | 8        | 2         | 4      | 2020-01-09 23:54:33 | 2020-01-10 00:15:02 | 20                            | 15       | 93.6  | 1           |
| 103         | 4        | 2         | 5      | 2020-01-04 13:23:46 | 2020-01-04 13:53:03 | 29                            | 40       | 35.1  | 3           |
| 104         | 5        | 3         | 5      | 2020-01-08 21:00:29 | 2020-01-08 21:10:57 | 10                            | 15       | 40.0  | 1           |
| 104         | 10       | 1         | 1      | 2020-01-11 18:34:49 | 2020-01-11 18:50:20 | 15                            | 10       | 60.0  | 2           |
| 105         | 7        | 2         | 3      | 2020-01-08 21:20:29 | 2020-01-08 21:30:45 | 10                            | 25       | 60.0  | 1           |

**5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?**

```sql
SELECT
  138 - sum(runner_paid) AS money_left
FROM
  (
    SELECT
      order_id,
      round(avg(distance), 1) AS distance,
      sum(distance) * 0.3 AS runner_paid
    FROM
      runner_orders_clean
    WHERE
      cancellation IS NULL
    GROUP BY
      order_id
  ) a;
```

| money_left |
|------------|
| 94.44      |
