#ЗАДАНИЕ 1 
#1. Преобразуем дату в месяц
SELECT 
  ID_client,
  DATE_FORMAT(date_new, '%Y-%m') AS month
FROM Transactions
WHERE date_new BETWEEN '2015-06-01' AND '2016-05-31'
GROUP BY ID_client, month;

#2. Посчитаем количество уникальных месяцев на клиента
SELECT 
  ID_client,
  COUNT(DISTINCT DATE_FORMAT(date_new, '%Y-%m')) AS active_months
FROM Transactions
WHERE date_new BETWEEN '2015-06-01' AND '2016-05-31'
GROUP BY ID_client;

#3. Отфильтруем тех, у кого active_months = 12
SELECT ID_client
FROM (
  SELECT 
    ID_client,
    COUNT(DISTINCT DATE_FORMAT(date_new, '%Y-%m')) AS active_months
  FROM Transactions
  WHERE date_new BETWEEN '2015-06-01' AND '2016-05-31'
  GROUP BY ID_client
) AS monthly_check
WHERE active_months = 12;

#ЗАДАНИЕ 2
# a)Средняя сумма чека в месяц
SELECT 
  DATE_FORMAT(date_new, '%Y-%m') AS month,
  AVG(Sum_payment) AS avg_check
FROM Transactions
WHERE date_new BETWEEN '2015-06-01' AND '2016-05-31'
GROUP BY month
ORDER BY month;

#b) Среднее количество операций в месяц
SELECT 
  DATE_FORMAT(date_new, '%Y-%m') AS month,
  COUNT(*) AS total_operations
FROM Transactions
WHERE date_new BETWEEN '2015-06-01' AND '2016-05-31'
GROUP BY month
ORDER BY month;

#c) Среднее количество клиентов, совершивших операции
SELECT 
  DATE_FORMAT(date_new, '%Y-%m') AS month,
  COUNT(DISTINCT ID_client) AS active_clients
FROM Transactions
WHERE date_new BETWEEN '2015-06-01' AND '2016-05-31'
GROUP BY month
ORDER BY month;

#d) Доля операций и суммы от годового объема
SELECT 
  DATE_FORMAT(date_new, '%Y-%m') AS month,
  COUNT(*) AS operations_in_month,
  SUM(Sum_payment) AS amount_in_month,
  COUNT(*) / (SELECT COUNT(*) FROM Transactions WHERE date_new BETWEEN '2015-06-01' AND '2016-05-31') AS share_of_year_operations,
  SUM(Sum_payment) / (SELECT SUM(Sum_payment) FROM Transactions WHERE date_new BETWEEN '2015-06-01' AND '2016-05-31') AS share_of_year_amount
FROM Transactions
WHERE date_new BETWEEN '2015-06-01' AND '2016-05-31'
GROUP BY month
ORDER BY month;

#e) Гендерное распределение и доля затрат
SELECT 
  DATE_FORMAT(t.date_new, '%Y-%m') AS month,
  c.gender,
  COUNT(DISTINCT t.ID_client) AS num_clients,
  ROUND(COUNT(DISTINCT t.ID_client) / SUM(COUNT(DISTINCT t.ID_client)) OVER (PARTITION BY DATE_FORMAT(t.date_new, '%Y-%m')) * 100, 2) AS gender_pct_clients,
  SUM(t.Sum_payment) AS total_spent,
  ROUND(SUM(t.Sum_payment) / SUM(SUM(t.Sum_payment)) OVER (PARTITION BY DATE_FORMAT(t.date_new, '%Y-%m')) * 100, 2) AS gender_pct_spending
FROM Transactions t
JOIN Customers c ON t.ID_client = c.ID_client
WHERE t.date_new BETWEEN '2015-06-01' AND '2016-06-01'
GROUP BY DATE_FORMAT(t.date_new, '%Y-%m'), c.gender
ORDER BY month, c.gender;

# ЗАДАНИЕ 3
#a) Общая статистика по возрастным группам (шаг 10 лет + NA)
SELECT 
  CASE 
    WHEN c.age IS NULL THEN 'NA'
    WHEN c.age BETWEEN 10 AND 19 THEN '10–19'
    WHEN c.age BETWEEN 20 AND 29 THEN '20–29'
    WHEN c.age BETWEEN 30 AND 39 THEN '30–39'
    WHEN c.age BETWEEN 40 AND 49 THEN '40–49'
    WHEN c.age BETWEEN 50 AND 59 THEN '50–59'
    WHEN c.age BETWEEN 60 AND 69 THEN '60–69'
    WHEN c.age >= 70 THEN '70+'
  END AS age_group,
  COUNT(*) AS num_transactions,
  SUM(t.Sum_payment) AS total_spent
FROM Transactions t
LEFT JOIN Customers c ON t.ID_client = c.ID_client
WHERE t.date_new BETWEEN '2015-06-01' AND '2016-06-01'
GROUP BY age_group
ORDER BY age_group;

#b)Поквартальная статистика: средняя сумма и доля каждой группы
WITH QuarterTotals AS (
  SELECT 
    QUARTER(date_new) AS qtr,
    YEAR(date_new) AS yr,
    SUM(Sum_payment) AS total_quarter_payment
  FROM Transactions
  WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'
  GROUP BY YEAR(date_new), QUARTER(date_new)
)

SELECT 
  CONCAT('Q', QUARTER(t.date_new), '-', YEAR(t.date_new)) AS quarter,
  CASE 
    WHEN c.age IS NULL THEN 'NA'
    WHEN c.age BETWEEN 10 AND 19 THEN '10–19'
    WHEN c.age BETWEEN 20 AND 29 THEN '20–29'
    WHEN c.age BETWEEN 30 AND 39 THEN '30–39'
    WHEN c.age BETWEEN 40 AND 49 THEN '40–49'
    WHEN c.age BETWEEN 50 AND 59 THEN '50–59'
    WHEN c.age BETWEEN 60 AND 69 THEN '60–69'
    WHEN c.age >= 70 THEN '70+'
  END AS age_group,
  ROUND(AVG(t.Sum_payment), 2) AS avg_payment,
  ROUND(SUM(t.Sum_payment) * 100 / qt.total_quarter_payment, 2) AS pct_of_quarter_spending
FROM Transactions t
LEFT JOIN Customers c ON t.ID_client = c.ID_client
JOIN QuarterTotals qt 
  ON QUARTER(t.date_new) = qt.qtr AND YEAR(t.date_new) = qt.yr
WHERE t.date_new BETWEEN '2015-06-01' AND '2016-06-01'
GROUP BY quarter, age_group, qt.total_quarter_payment
ORDER BY quarter, age_group, qt.total_quarter_payment;


