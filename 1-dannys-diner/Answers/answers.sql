-- Question 1. What is the total amount each customer spent at the restaurant?
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

-- Question 2. How many days has each customer visited the restaurant?
SELECT
  customer_id,
  count(DISTINCT order_date) AS visits
FROM
  sales
GROUP BY
  customer_id
ORDER BY
  customer_id;

-- Question 3. What was the first item from the menu purchased by each customer?
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

-- Question 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
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

-- Question 5. Which item was the most popular for each customer?
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

-- Question 6. Which item was purchased first by the customer after they became a member?
WITH ranked_orders_after_joining AS (
  SELECT
    s.customer_id,
    order_date,
    product_id,
    join_date,
    row_number() over(PARTITION by s.customer_id) AS ranking
  FROM
    sales s
    LEFT JOIN members m ON s.customer_id = m.customer_id
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

-- Question 7. Which item was purchased just before the customer became a member?
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
    LEFT JOIN members ON sales.customer_id = members.customer_id
  WHERE
    order_date < join_date
)
SELECT
  *
FROM
  ranked_orders_before_joining
WHERE
  ranking = 1;

-- Question 8. What is the total items and amount spent for each member before they became a member?
SELECT
  s.customer_id,
  count(s.product_id) AS total_items,
  sum(price) AS total
FROM
  sales s
  LEFT JOIN members ON s.customer_id = members.customer_id
  LEFT JOIN menu m ON s.product_id = m.product_id
WHERE
  order_date < join_date
GROUP BY
  s.customer_id;

-- Question 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
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

-- Question 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
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
    LEFT JOIN members ON s.customer_id = members.customer_id
    LEFT JOIN menu m ON s.product_id = m.product_id
  WHERE
    order_date < '2021-02-01'
    AND s.customer_id IN (
      SELECT
        customer_id
      FROM
        members
    )
)
SELECT
  customer_id,
  sum(points) AS total_points
FROM
  orders_with_points
GROUP BY
  customer_id;

-- Bonus Question 1. 
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

-- Bonus Question 2. 
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
    sales s
    LEFT JOIN menu m USING(product_id)
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