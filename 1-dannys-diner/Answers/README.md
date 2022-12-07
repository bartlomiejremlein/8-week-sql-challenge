**1. What is the total amount each customer spent at the restaurant?**

```sql
SELECT
  customer_id,
  sum(price) AS total_spent
FROM
  sales
  LEFT JOIN menu ON sales.product_id = menu.product_id
GROUP BY
  customer_id
ORDER BY
  customer_id;
```

Output:
| customer_id | total_spent |
|-------------|-------------|
| A           | 76          |
| B           | 74          |
| C           | 36          |



**2. How many days has each customer visited the restaurant?**

```sql
SELECT
  customer_id,
  count(DISTINCT order_date) AS visits
FROM
  sales
GROUP BY
  customer_id
ORDER BY
  customer_id;
```

| customer_id | visits |
|-------------|--------|
| A           | 4      |
| B           | 6      |
| C           | 2      |



**3. What was the first item from the menu purchased by each customer?**

```sql
WITH orders_by_customers_ranked AS (
  SELECT
    customer_id,
    order_date,
    product_name,
    row_number() over(PARTITION by customer_id) AS order_no
  FROM
    sales s
    LEFT JOIN menu m ON s.product_id = m.product_id
)
SELECT
  customer_id,
  product_name,
  order_date
FROM
  orders_by_customers_ranked
WHERE
  order_no = 1;

```

| customer_id | product_name | order_date |
|-------------|--------------|------------|
| A           | curry        | 2021-01-07 |
| B           | sushi        | 2021-01-04 |
| C           | ramen        | 2021-01-01 |


**4. What is the most purchased item on the menu and how many times was it purchased by all customers?**

```sql
SELECT
  menu.product_name,
  count(product_name) AS total_purchases
FROM
  sales
  LEFT JOIN menu ON sales.product_id = menu.product_id
GROUP BY
  product_name
ORDER BY
  total_purchases DESC
LIMIT
  1;
```

| product_name | total_purchases |
|--------------|-----------------|
| ramen        | 8               |




**5. Which item was the most popular for each customer?**

```sql
WITH total_orders_per_product_per_customer AS (
  SELECT
    customer_id,
    menu.product_name,
    count(menu.product_name) AS total_count
  FROM
    sales
    LEFT JOIN menu ON sales.product_id = menu.product_id
  GROUP BY
    customer_id,
    menu.product_name
),
ranked_orders AS (
  SELECT
    customer_id,
    product_name,
    total_count,
    row_number() over(
      PARTITION by customer_id
      ORDER BY
        total_count DESC
    ) AS ranked
  FROM
    total_orders_per_product_per_customer
)
SELECT
  customer_id,
  product_name,
  total_count
FROM
  ranked_orders
WHERE
  ranked = 1;
```

| customer_id | product_name | total_count |
|-------------|--------------|-------------|
| A           | ramen        | 3           |
| B           | sushi        | 2           |
| C           | ramen        | 3           |




**6. Which item was purchased first by the customer after they became a member?**

```sql
WITH ranked_orders_after_joining AS (
  SELECT
    s.customer_id,
    order_date,
    product_id,
    join_date,
    row_number() over(PARTITION by s.customer_id) AS ranking
  FROM
    sales s
    RIGHT JOIN members m ON s.customer_id = m.customer_id
  WHERE
    order_date >= join_date
)
SELECT
  customer_id,
  product_name
FROM
  ranked_orders_after_joining
  LEFT JOIN menu USING(product_id)
WHERE
  ranking = 1
ORDER BY
 customer_id;
```

| customer_id | product_name |
|-------------|--------------|
| A           | curry        |
| B           | sushi        |




**7. Which item was purchased just before the customer became a member?**

```sql
WITH ranked_orders_before_joining AS (
  SELECT
    sales.customer_id,
    order_date,
    product_id,
    join_date,
    row_number() over(
      PARTITION by customer_id
      ORDER BY
        order_date DESC
    ) AS ranking
  FROM
    sales
    RIGHT JOIN members ON sales.customer_id = members.customer_id
  WHERE
    order_date < join_date
)
SELECT
  *
FROM
  ranked_orders_before_joining
WHERE
  ranking = 1;
```

| customer_id | product_name |
|-------------|--------------|
| A           | sushi        |
| B           | sushi        |




**8. What is the total items and amount spent for each member before they became a member?**

```sql
SELECT
  s.customer_id,
  count(s.product_id) AS total_items,
  sum(price) AS total
FROM
  sales s
  RIGHT JOIN members ON s.customer_id = members.customer_id
  LEFT JOIN menu m ON s.product_id = m.product_id
WHERE
  order_date < join_date
GROUP BY
  s.customer_id;
```

| customer_id | total_items | total |
|-------------|-------------|-------|
| A           | 2           | 25    |
| B           | 3           | 40    |




**9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?**

```sql
WITH customer_points AS (
  SELECT
    customer_id,
    product_name,
    price,
    CASE
      WHEN s.customer_id IN (
        SELECT
          customer_id
        FROM
          members
      )
      AND product_name = 'sushi' THEN price * 20
      WHEN s.customer_id IN (
        SELECT
          customer_id
        FROM
          members
      )
      AND product_name != 'sushi' THEN price * 10
      ELSE 0
    END AS points
  FROM
    sales s
    LEFT JOIN menu m ON s.product_id = m.product_id
)
SELECT
  customer_id,
  sum(points) total_points
FROM
  customer_points
GROUP BY
  customer_id
ORDER BY
  customer_id;
```

| customer_id | total_points |
|-------------|--------------|
| A           | 760          |
| B           | 740          |
| C           | 360          |



**10.  In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?**

```sql
WITH orders_with_points AS (
  SELECT
    s.customer_id,
    join_date,
    order_date,
    product_name,
    price,
    CASE
      WHEN product_name = 'sushi'
      OR (
        order_date >= join_date
        AND order_date < join_date + INTERVAL '7 DAY'
      ) THEN price * 10 * 2
      ELSE price * 10
    END AS points
  FROM
    sales s
    RIGHT JOIN members ON s.customer_id = members.customer_id
    LEFT JOIN menu m ON s.product_id = m.product_id
  WHERE
    order_date < '2021-02-01'
)
SELECT
  customer_id,
  sum(points) AS total_points
FROM
  orders_with_points
GROUP BY
  customer_id;
```

| customer_id | total_points |
|-------------|--------------|
| A           | 1370         |
| B           | 820          |



**Bonus 1.**

```sql
SELECT
  customer_id,
  order_date,
  product_name,
  price,
  CASE
    WHEN order_date >= join_date THEN 'Y'
    ELSE 'N'
  END AS member
FROM
  sales
  LEFT JOIN menu USING(product_id)
  LEFT JOIN members USING(customer_id)
ORDER BY
  customer_id,
  order_date;
```
   
| customer_id | order_date | product_name | price | member |
|-------------|------------|--------------|-------|--------|
| A           | 2021-01-01 | curry        | 15    | N      |
| A           | 2021-01-01 | sushi        | 10    | N      |
| A           | 2021-01-07 | curry        | 15    | Y      |
| A           | 2021-01-10 | ramen        | 12    | Y      |
| A           | 2021-01-11 | ramen        | 12    | Y      |
| A           | 2021-01-11 | ramen        | 12    | Y      |
| B           | 2021-01-01 | curry        | 15    | N      |
| B           | 2021-01-02 | curry        | 15    | N      |
| B           | 2021-01-04 | sushi        | 10    | N      |
| B           | 2021-01-11 | sushi        | 10    | Y      |
| B           | 2021-01-16 | ramen        | 12    | Y      |
| B           | 2021-02-01 | ramen        | 12    | Y      |
| C           | 2021-01-01 | ramen        | 12    | N      |
| C           | 2021-01-01 | ramen        | 12    | N      |
| C           | 2021-01-07 | ramen        | 12    | N      |




**Bonus 2.**

```sql
WITH loyalty_program AS (
  SELECT
    customer_id,
    order_date,
    product_name,
    price,
    CASE
      WHEN order_date >= join_date THEN 'Y'
      ELSE 'N'
    END AS member
  FROM
    sales
    LEFT JOIN menu USING(product_id)
    LEFT JOIN members USING(customer_id)
)
SELECT
  *,
  CASE
    WHEN member = 'Y' THEN dense_rank() over(
      PARTITION by customer_id,
      member
      ORDER BY
        order_date
    )
    ELSE NULL
  END AS ranking
FROM
  loyalty_program
```

| customer_id | order_date | product_name | price | member | ranking |
|-------------|------------|--------------|-------|--------|---------|
| A           | 2021-01-01 | curry        | 15    | N      | null    |
| A           | 2021-01-01 | sushi        | 10    | N      | null    |
| A           | 2021-01-07 | curry        | 15    | Y      | 1       |
| A           | 2021-01-10 | ramen        | 12    | Y      | 2       |
| A           | 2021-01-11 | ramen        | 12    | Y      | 3       |
| A           | 2021-01-11 | ramen        | 12    | Y      | 3       |
| B           | 2021-01-01 | curry        | 15    | N      | null    |
| B           | 2021-01-02 | curry        | 15    | N      | null    |
| B           | 2021-01-04 | sushi        | 10    | N      | null    |
| B           | 2021-01-11 | sushi        | 10    | Y      | 1       |
| B           | 2021-01-16 | ramen        | 12    | Y      | 2       |
| B           | 2021-02-01 | ramen        | 12    | Y      | 3       |
| C           | 2021-01-01 | ramen        | 12    | N      | null    |
| C           | 2021-01-01 | ramen        | 12    | N      | null    |
| C           | 2021-01-07 | ramen        | 12    | N      | null    |
