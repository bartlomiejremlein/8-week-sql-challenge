
**1. How many customers has Foodie-Fi ever had?**

```sql
SELECT
  count(DISTINCT customer_id)
FROM
  subscriptions;
```
| count |
|-------|
| 1000  |


**2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value**

```sql
SELECT
  date_part('month', start_date) AS MONTH,
  count(*)
FROM
  subscriptions
  LEFT JOIN plans USING (plan_id)
WHERE
  plan_name = 'trial'
GROUP BY
  MONTH
ORDER BY
  MONTH;
```

| month | count |
|-------|-------|
| 1     | 88    |
| 2     | 68    |
| 3     | 94    |
| 4     | 81    |
| 5     | 88    |
| 6     | 79    |
| 7     | 89    |
| 8     | 88    |
| 9     | 87    |
| 10    | 79    |
| 11    | 75    |
| 12    | 84    |

**3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name**

```sql
SELECT
  plan_name,
  count(*)
FROM
  subscriptions
  LEFT JOIN plans USING (plan_id)
WHERE
  date_part('year', start_date) > 2020
GROUP BY
  plan_name;
```

| plan_name     | count |
|---------------|-------|
| pro annual    | 63    |
| churn         | 71    |
| pro monthly   | 60    |
| basic monthly | 8     |

**4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?**

```sql
SELECT
  count(*),
  round(
    count(DISTINCT customer_id) :: numeric /(
      SELECT
        count(DISTINCT customer_id)
      FROM
        subscriptions
    ) :: numeric * 100,
    1
  ) as pct
FROM
  subscriptions
  LEFT JOIN plans USING (plan_id)
WHERE
  plan_name = 'churn';
```

| count | pct  |
|-------|------|
| 307   | 30.7 |


**5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?**
```sql
WITH next_plans AS (
  SELECT
    customer_id,
    plan_name,
    lead(plan_name) over(
      PARTITION by customer_id
      ORDER BY
        start_date
    ) AS next_plan
  FROM
    subscriptions
    LEFT JOIN plans USING (plan_id)
)
SELECT
  count(*),
  100 * count(*) /(
    SELECT
      count(DISTINCT customer_id)
    FROM
      subscriptions
  ) AS pct
FROM
  next_plans
WHERE
  plan_name = 'trial'
  AND next_plan = 'churn';
```

| count | pct |
|-------|-----|
| 92    | 9   |

**6. What is the number and percentage of customer plans after their initial free trial?**
```sql
WITH next_plans AS (
  SELECT
    customer_id,
    plan_name,
    lead(plan_name) over(
      PARTITION by customer_id
      ORDER BY
        start_date
    ) AS next_plan
  FROM
    subscriptions
    LEFT JOIN plans USING (plan_id)
)
SELECT
  next_plan,
  count(customer_id),
  round(
    100 * count(customer_id) /(
      SELECT
        count(DISTINCT customer_id)
      FROM
        subscriptions
    ) :: numeric,
    1
  ) AS pct
FROM
  next_plans
WHERE
  plan_name = 'trial'
  AND next_plan IS NOT NULL
GROUP BY
  next_plan;
```
| next_plan     | count | pct  |
|---------------|-------|------|
| basic monthly | 546   | 54.6 |
| churn         | 92    | 9.2  |
| pro annual    | 37    | 3.7  |
| pro monthly   | 325   | 32.5 |


**7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?**

```sql
WITH plan_date AS (
  SELECT
    customer_id,
    plan_name,
    start_date,
    lead(start_date) over(
      PARTITION by customer_id
      ORDER BY
        start_date
    ) AS end_date
  FROM
    subscriptions
    LEFT JOIN plans USING(plan_id)
)
SELECT
  plan_name,
  count(*),
  round(
    100 * count(*) :: numeric /(
      SELECT
        count(DISTINCT customer_id)
      FROM
        subscriptions
    ),
    1
  ) AS pct
FROM
  plan_date
WHERE
  (
    (
      start_date < '2020-12-31'
      AND end_date > '2020-12-31'
    )
    AND end_date IS NOT NULL
  )
  OR (
    start_date < '2020-12-31'
    AND end_date IS NULL
  )
GROUP BY
  plan_name;
```

| plan_name     | count | pct  |
|---------------|-------|------|
| pro annual    | 195   | 19.5 |
| trial         | 19    | 1.9  |
| churn         | 235   | 23.5 |
| pro monthly   | 326   | 32.6 |
| basic monthly | 224   | 22.4 |

**8. How many customers have upgraded to an annual plan in 2020?**

```sql
SELECT
  count(DISTINCT customer_id)
FROM
  subscriptions
  LEFT JOIN plans USING(plan_id)
WHERE
  plan_name = 'pro annual'
  AND date_part('year', start_date) = 2020;
```

| sum |
|-----|
| 195 |

**9.  How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?**
```sql
WITH trial_customers AS (
  SELECT
    *
  FROM
    subscriptions
    LEFT JOIN plans USING(plan_id)
  WHERE
    plan_name = 'trial'
),
pro_annual_customers AS (
  SELECT
    s.customer_id,
    t.start_date AS start_date,
    s.start_date AS annual_plan_date
  FROM
    subscriptions s
    LEFT JOIN plans p ON s.plan_id = p.plan_id
    LEFT JOIN trial_customers t ON s.customer_id = t.customer_id
  WHERE
    p.plan_name = 'pro annual'
)
SELECT
  round(avg(annual_plan_date - start_date), 0)
FROM
  pro_annual_customers;

```
| round |
|-------|
| 105   |

**10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)**

```sql
WITH RECURSIVE bins AS (
  SELECT
    0 AS start_period,
    30 AS end_period
  UNION
  ALL
  SELECT
    end_period + 1 AS start_period,
    end_period + 30 AS end_period
  FROM
    bins
  WHERE
    end_period < 360
),
trial_customers AS (
  SELECT
    *
  FROM
    subscriptions
    LEFT JOIN plans USING(plan_id)
  WHERE
    plan_name = 'trial'
),
pro_annual_customers AS (
  SELECT
    s.customer_id,
    s.start_date - t.start_date AS date_diff
  FROM
    subscriptions s
    LEFT JOIN plans p ON s.plan_id = p.plan_id
    LEFT JOIN trial_customers t ON s.customer_id = t.customer_id
  WHERE
    p.plan_name = 'pro annual'
)
SELECT
  start_period,
  end_period,
  count(*)
FROM
  bins
  LEFT JOIN pro_annual_customers ON date_diff >= start_period
  AND date_diff <= end_period
GROUP BY
  start_period,
  end_period;
```
| start_period | end_period | count |
|--------------|------------|-------|
| 0            | 30         | 49    |
| 31           | 60         | 24    |
| 61           | 90         | 34    |
| 91           | 120        | 35    |
| 121          | 150        | 42    |
| 151          | 180        | 36    |
| 181          | 210        | 26    |
| 211          | 240        | 4     |
| 241          | 270        | 5     |
| 271          | 300        | 1     |
| 301          | 330        | 1     |
| 331          | 360        | 1     |

**11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?**
```sql
WITH next_plans AS (
  SELECT
    customer_id,
    start_date,
    plan_name,
    lead(start_date) over(
      PARTITION by customer_id
      ORDER BY
        start_date
    ) AS next_plan_start_date,
    lead(plan_name) over(
      PARTITION by customer_id
      ORDER BY
        start_date
    ) AS next_plan
  FROM
    subscriptions
    LEFT JOIN plans USING (plan_id)
)
SELECT
  COUNT(DISTINCT customer_id)
FROM
  next_plans
WHERE
  plan_name = 'pro monthly'
  AND next_plan = 'basic monthly'
  AND date_part('year', next_plan_start_date) = 2020;
```
| count |
|-------|
| 0     |