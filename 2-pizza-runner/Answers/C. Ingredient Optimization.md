# Case Study #2 - Pizza Runner
## 🍴 C. Ingredient Optimization

```sql
DROP TABLE IF EXISTS pizza_recipes_unnested;

CREATE TEMP TABLE pizza_recipes_unnested AS WITH recipes_unnested AS (
  SELECT
    pizza_id,
    unnest(string_to_array(toppings, ', ')) :: int AS topping_id
  FROM
    pizza_recipes
)
SELECT
  pizza_id,
  topping_id,
  topping_name
FROM
  recipes_unnested
  LEFT JOIN pizza_toppings USING(topping_id)
ORDER BY
  pizza_id,
  topping_id;
```
```sql
CREATE TEMP TABLE exclusions AS
SELECT
  pizza_number,
  unnest(string_to_array(exclusions, ', ')) AS exclusion_id
FROM
  customer_orders_clean;
```
```sql
CREATE TEMP TABLE extras AS
SELECT
  pizza_number,
  unnest(string_to_array(extras, ', ')) AS extra_id
FROM
  customer_orders_clean;
```

**1. What are the standard ingredients for each pizza?**


```sql
SELECT
  pizza_name,
  string_agg(topping_name, ', ') AS toppings
FROM
  pizza_recipes_unnested
  LEFT JOIN pizza_names USING(pizza_id)
GROUP BY
  pizza_name;
```
| pizza_name | toppings                                                              |
|------------|-----------------------------------------------------------------------|
| Meatlovers | Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami |
| Vegetarian | Cheese, Mushrooms, Onions, Peppers, Tomatoes, Tomato Sauce            |


**2. What was the most commonly added extra?**

```sql
SELECT
  topping_name,
  count(*)
FROM
  extras e
  LEFT JOIN pizza_toppings pt ON e.extra_id = pt.topping_id
GROUP BY
  topping_name
ORDER BY
  count DESC;

```


| topping_name | count |
|--------------|-------|
| Bacon        | 4     |
| Chicken      | 1     |
| Cheese       | 1     |

**3. What was the most common exclusion?**

```sql
SELECT
  topping_name,
  count(*)
FROM
  exclusions e
  LEFT JOIN pizza_toppings pt ON e.exclusion_id = pt.topping_id
GROUP BY
  topping_name
ORDER BY
  count DESC;
```

| topping_name | count |
|--------------|-------|
| Cheese       | 4     |
| Mushrooms    | 1     |
| BBQ Sauce    | 1     |

**4. Generate an order item for each record in the customers_orders table in the format of one of the following:**
- `Meat Lovers`
- `Meat Lovers - Exclude Beef`
- `Meat Lovers - Extra Bacon`
- `Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers`

```sql 
WITH records AS (
  SELECT
    pizza_number,
    'Exclude ' || string_agg(topping_name, ', ') AS record
  FROM
    exclusions e
    LEFT JOIN pizza_toppings pt ON e.exclusion_id = pt.topping_id
  GROUP BY
    pizza_number
  UNION
  SELECT
    pizza_number,
    'Extra ' || string_agg(topping_name, ', ')
  FROM
    extras e
    LEFT JOIN pizza_toppings pt ON e.extra_id = pt.topping_id
  GROUP BY
    pizza_number
)
SELECT
  c.pizza_number,
  concat_ws(
    ' - ',
    pn.pizza_name,
    string_agg(r.record, ' - ')
  ) AS record
FROM
  customer_orders_clean c
  LEFT JOIN records r ON c.pizza_number = r.pizza_number
  LEFT JOIN pizza_names pn ON c.pizza_id = pn.pizza_id
GROUP BY
  c.pizza_number,
  pizza_name;
```

| pizza_number | record                                                          |
|--------------|-----------------------------------------------------------------|
| 1            | Meatlovers                                                      |
| 2            | Meatlovers                                                      |
| 3            | Meatlovers                                                      |
| 4            | Vegetarian                                                      |
| 5            | Meatlovers - Exclude Cheese                                     |
| 6            | Meatlovers - Exclude Cheese                                     |
| 7            | Vegetarian - Exclude Cheese                                     |
| 8            | Meatlovers - Extra Bacon                                        |
| 9            | Vegetarian                                                      |
| 10           | Vegetarian - Extra Bacon                                        |
| 11           | Meatlovers                                                      |
| 12           | Meatlovers - Extra Bacon, Chicken - Exclude Cheese              |
| 13           | Meatlovers                                                      |
| 14           | Meatlovers - Extra Bacon, Cheese - Exclude BBQ Sauce, Mushrooms |

**5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the `customer_orders` table and add a `2x` in front of any relevant ingredients**
- For example: `"Meat Lovers: 2xBacon, Beef, ... , Salami"`

```sql 
SELECT
  pizza_number,
  pizza_name || ': ' || string_agg(
    CASE
      WHEN topping_id IN (
        SELECT
          extra_id
        FROM
          extras e
        WHERE
          c.pizza_number = e.pizza_number
      ) THEN '2x' || topping_name
      ELSE topping_name
    END,
    ', '
    ORDER BY
      topping_name
  )
FROM
  customer_orders_clean c
  LEFT JOIN pizza_recipes_unnested p ON c.pizza_id = p.pizza_id
  LEFT JOIN pizza_names pn ON c.pizza_id = pn.pizza_id
WHERE
  p.topping_id NOT IN (
    SELECT
      exclusion_id
    FROM
      exclusions e
    WHERE
      c.pizza_number = e.pizza_number
  )
GROUP BY
  pizza_number,
  pizza_name;
```

| pizza_number | record                                                                              |
|--------------|-------------------------------------------------------------------------------------|
| 1            | Meatlovers: Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami   |
| 2            | Meatlovers: Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami   |
| 3            | Meatlovers: Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami   |
| 4            | Vegetarian: Cheese, Mushrooms, Onions, Peppers, Tomato Sauce, Tomatoes              |
| 5            | Meatlovers: Bacon, BBQ Sauce, Beef, Chicken, Mushrooms, Pepperoni, Salami           |
| 6            | Meatlovers: Bacon, BBQ Sauce, Beef, Chicken, Mushrooms, Pepperoni, Salami           |
| 7            | Vegetarian: Mushrooms, Onions, Peppers, Tomato Sauce, Tomatoes                      |
| 8            | Meatlovers: 2xBacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami |
| 9            | Vegetarian: Cheese, Mushrooms, Onions, Peppers, Tomato Sauce, Tomatoes              |
| 10           | Vegetarian: Cheese, Mushrooms, Onions, Peppers, Tomato Sauce, Tomatoes              |
| 11           | Meatlovers: Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami   |
| 12           | Meatlovers: 2xBacon, BBQ Sauce, Beef, 2xChicken, Mushrooms, Pepperoni, Salami       |
| 13           | Meatlovers: Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami   |
| 14           | Meatlovers: 2xBacon, Beef, 2xCheese, Chicken, Pepperoni, Salami                     |


**6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?**

```sql
WITH ingredients AS (
  SELECT
    c.pizza_number,
    p.topping_name,
    CASE
      WHEN topping_id IN (
        SELECT
          extra_id
        FROM
          extras e
        WHERE
          c.pizza_number = e.pizza_number
      ) THEN 2
      WHEN topping_id IN (
        SELECT
          exclusion_id
        FROM
          exclusions e
        WHERE
          c.pizza_number = e.pizza_number
      ) THEN 0
      ELSE 1
    END AS times_used
  FROM
    customer_orders_clean c
    LEFT JOIN pizza_recipes_unnested p ON c.pizza_id = p.pizza_id
  WHERE
    c.order_id IN (
      SELECT
        order_id
      FROM
        runner_orders_clean
      WHERE
        cancellation IS NULL
    )
)
SELECT
  topping_name,
  sum(times_used) AS times_used
FROM
  ingredients
GROUP BY
  topping_name
ORDER BY
  times_used DESC;
```

| topping_name | times_used |
|--------------|------------|
| Bacon        | 11         |
| Mushrooms    | 11         |
| Cheese       | 10         |
| Pepperoni    | 9          |
| Salami       | 9          |
| Chicken      | 9          |
| Beef         | 9          |
| BBQ Sauce    | 8          |
| Tomatoes     | 3          |
| Onions       | 3          |
| Peppers      | 3          |
| Tomato Sauce | 3          |
