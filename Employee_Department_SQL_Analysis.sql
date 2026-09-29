/*
===========================================================
PROJECT: Employee & Department Salary Analysis
DATABASE: MySQL
FILE: Employee_Department_SQL_Analysis.sql
===========================================================

PROJECT OVERVIEW
----------------
This project analyzes employee and department data using MySQL.
The analysis focuses on employee count, department-wise salary
statistics, salary expenses, employee rankings, and comparison
of individual salaries with department averages.

KEY SQL CONCEPTS USED
---------------------
- SELECT
- COUNT()
- AVG()
- SUM()
- MIN()
- MAX()
- ROUND()
- JOIN
- LEFT JOIN
- GROUP BY
- HAVING
- ORDER BY
- LIMIT
- Subqueries
- CTE (Common Table Expression)
- Window Functions
- DENSE_RANK()
- AVG() OVER(PARTITION BY)

BUSINESS AREAS ANALYZED
-----------------------
1. Employee headcount
2. Department-wise employee count
3. Department-wise average salary
4. Highest and lowest salary by department
5. Department salary expense
6. Salary expense and average salary comparison
7. Departments above overall average salary
8. Highest-paid employees
9. Top employees within each department
10. Employee salary vs department average
11. Employees earning above their department average
12. Highest-average-salary department
13. Highest-total-salary-expense department

===========================================================
SQL ANALYSIS
===========================================================
*/


-- =========================================================
-- Q1. Total number of employees
-- =========================================================
SELECT COUNT(*) AS total_employees
FROM employees;


-- =========================================================
-- Q2. Number of employees in each department
-- =========================================================
SELECT
    DEPT.department_name AS department,
    COUNT(EMP.employee_id) AS employee_count
FROM employees AS EMP
JOIN departments AS DEPT
    ON EMP.department_id = DEPT.department_id
GROUP BY DEPT.department_name;


-- =========================================================
-- Q3. Average salary in each department
-- =========================================================
SELECT
    DEPT.department_name AS department,
    ROUND(AVG(EMP.salary), 0) AS average_salary
FROM employees AS EMP
JOIN departments AS DEPT
    ON EMP.department_id = DEPT.department_id
GROUP BY DEPT.department_name;


-- =========================================================
-- Q4. Highest salary in each department
-- =========================================================
SELECT
    DEPT.department_name AS department,
    MAX(EMP.salary) AS highest_salary
FROM employees AS EMP
LEFT JOIN departments AS DEPT
    ON EMP.department_id = DEPT.department_id
GROUP BY DEPT.department_name;


-- =========================================================
-- Q5. Lowest salary in each department
-- =========================================================
SELECT
    DEPT.department_name AS department,
    MIN(EMP.salary) AS lowest_salary
FROM employees AS EMP
LEFT JOIN departments AS DEPT
    ON EMP.department_id = DEPT.department_id
GROUP BY DEPT.department_name;


-- =========================================================
-- Q6. Total salary expense for each department
-- =========================================================
SELECT
    DEPT.department_name AS department,
    SUM(EMP.salary) AS total_salary
FROM employees AS EMP
LEFT JOIN departments AS DEPT
    ON EMP.department_id = DEPT.department_id
GROUP BY DEPT.department_name;


-- =========================================================
-- Q7. Each department's total salary expense and average salary
-- =========================================================
SELECT
    DEPT.department_name AS department,
    SUM(EMP.salary) AS total_salary_expense,
    ROUND(AVG(EMP.salary), 2) AS average_salary
FROM employees AS EMP
LEFT JOIN departments AS DEPT
    ON EMP.department_id = DEPT.department_id
GROUP BY DEPT.department_name;


-- =========================================================
-- Q8. Departments where average salary is greater than
--     the overall average salary
-- =========================================================
SELECT
    DEPT.department_name AS department,
    ROUND(AVG(EMP.salary), 2) AS average_salary
FROM employees AS EMP
LEFT JOIN departments AS DEPT
    ON EMP.department_id = DEPT.department_id
GROUP BY DEPT.department_name
HAVING AVG(EMP.salary) > (
    SELECT AVG(salary)
    FROM employees
);


-- =========================================================
-- Q9. Top 3 highest-paid employees in the company
-- =========================================================
SELECT
    EMP.first_name AS emp_name,
    DEPT.department_name AS department,
    EMP.salary
FROM employees AS EMP
LEFT JOIN departments AS DEPT
    ON EMP.department_id = DEPT.department_id
ORDER BY EMP.salary DESC
LIMIT 3;


-- =========================================================
-- Q10. Top 3 employees in EACH department
-- =========================================================
SELECT
    ranked.emp_name,
    DEPT.department_name AS department,
    ranked.salary,
    ranked.salary_rank
FROM (
    SELECT
        EMP.first_name AS emp_name,
        EMP.department_id,
        EMP.salary,
        DENSE_RANK() OVER (
            PARTITION BY EMP.department_id
            ORDER BY EMP.salary DESC
        ) AS salary_rank
    FROM employees AS EMP
) AS ranked
JOIN departments AS DEPT
    ON ranked.department_id = DEPT.department_id
WHERE ranked.salary_rank <= 3
ORDER BY DEPT.department_name, ranked.salary DESC;


-- =========================================================
-- Q11. Employee salary, department average salary, and
--      difference from department average
-- =========================================================
SELECT
    first_name,
    department_id,
    salary,
    ROUND(
        AVG(salary) OVER (PARTITION BY department_id), 2
    ) AS department_avg_salary,
    ROUND(
        salary - AVG(salary) OVER (PARTITION BY department_id), 2
    ) AS salary_difference
FROM employees;


-- =========================================================
-- Q12. Employees whose salary is higher than their
--      own department's average salary
-- =========================================================
SELECT
    first_name,
    department_id,
    salary
FROM employees e
WHERE salary > (
    SELECT AVG(salary)
    FROM employees e2
    WHERE e2.department_id = e.department_id
)
ORDER BY department_id, salary DESC;


-- =========================================================
-- Q13. Department with the highest average employee salary
-- =========================================================
SELECT
    DEPT.department_name AS department,
    ROUND(AVG(EMP.salary), 2) AS average_salary
FROM employees AS EMP
JOIN departments AS DEPT
    ON EMP.department_id = DEPT.department_id
GROUP BY DEPT.department_name
ORDER BY average_salary DESC
LIMIT 1;


-- =========================================================
-- Q14. Department with the highest total salary expense
-- =========================================================
SELECT
    DEPT.department_name AS department,
    SUM(EMP.salary) AS total_salary_expense
FROM employees AS EMP
JOIN departments AS DEPT
    ON EMP.department_id = DEPT.department_id
GROUP BY DEPT.department_name
ORDER BY total_salary_expense DESC
LIMIT 1;


-- =========================================================
-- Q15. Top 5 employees whose salary is higher than their
--      department's average salary — CTE approach
-- =========================================================
WITH salary_with_avg AS (
    SELECT
        e.first_name AS employee_name,
        d.department_name,
        e.salary,
        AVG(e.salary) OVER (
            PARTITION BY e.department_id
        ) AS dept_avg_salary
    FROM employees e
    JOIN departments d
        ON e.department_id = d.department_id
)
SELECT
    employee_name,
    department_name,
    salary,
    dept_avg_salary,
    salary - dept_avg_salary AS salary_difference
FROM salary_with_avg
WHERE salary > dept_avg_salary
ORDER BY salary DESC
LIMIT 5;


-- =========================================================
-- Q15 (Alternative). Same analysis using a correlated subquery
-- =========================================================
SELECT
    e.first_name AS employee_name,
    d.department_name,
    e.salary,
    (
        SELECT AVG(e2.salary)
        FROM employees e2
        WHERE e2.department_id = e.department_id
    ) AS dept_avg_salary,
    e.salary - (
        SELECT AVG(e2.salary)
        FROM employees e2
        WHERE e2.department_id = e.department_id
    ) AS salary_difference
FROM employees e
JOIN departments d
    ON e.department_id = d.department_id
WHERE e.salary > (
    SELECT AVG(e2.salary)
    FROM employees e2
    WHERE e2.department_id = e.department_id
)
ORDER BY e.salary DESC
LIMIT 5;


/*
===========================================================
PROJECT SUMMARY
===========================================================

WHAT WAS ANALYZED
-----------------
- Total employee headcount
- Department-wise employee count
- Department-wise average salary
- Highest and lowest salary by department
- Department salary expense
- Salary expense and average salary
- Departments above overall average salary
- Top 3 highest-paid employees
- Top 3 employees within each department
- Employee salary compared with department average
- Employees earning above department average
- Department with highest average salary
- Department with highest total salary expense
- Top 5 employees above department average

BUSINESS PURPOSE
----------------
The analysis helps HR and management understand workforce size,
salary distribution, departmental salary costs, high-paid employees,
and employee salary positioning relative to department averages.

===========================================================
END OF ANALYSIS
===========================================================
