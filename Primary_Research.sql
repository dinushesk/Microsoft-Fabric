/*View the data sets*/

SELECT * FROM EV_Sales_by_Makers;
SELECT * FROM EV_sales_by_state;

/*List the top 3 and bottom 3 makers for the fiscal years 2023 and 2024 in 
terms of the number of 2-wheelers sold.*/

/*Listing down the TOP 3 makers*/

SELECT 
    TOP 3 maker, 
    SUM(electric_vehicles_sold) AS Total
FROM 
    EV_Sales_by_Makers
JOIN 
    Dim_Date dd
ON 
    dd.date = EV_Sales_by_Makers.date
WHERE 
    dd.fiscal_year in (2023,2024)
    AND EV_Sales_by_Makers.vehicle_category = '2-Wheelers' 
GROUP BY 
    maker
ORDER BY 
    Total DESC;

/*Listing down BOTTOM 3 makers*/

SELECT 
    TOP 3 maker, 
    SUM(electric_vehicles_sold) AS Total
FROM 
    EV_Sales_by_Makers
JOIN 
    Dim_Date dd
ON 
    dd.date = EV_Sales_by_Makers.date
WHERE 
    dd.fiscal_year in (2023,2024)
    AND EV_Sales_by_Makers.vehicle_category = '2-Wheelers' 
GROUP BY 
    maker
ORDER BY 
    Total ASC;


/*Identify the top 5 states with the highest penetration rate in 2-wheeler 
and 4-wheeler EV sales in FY 2024.*/

SELECT
     TOP 5 state, 
     round(sum(electric_vehicles_sold)*100.0/sum(total_vehicles_sold),2)AS penetration_rate
FROM EV_sales_by_state esbs
JOIN Dim_Date dd
ON
    dd.date= esbs.date
WHERE dd.fiscal_year in (2024) AND
vehicle_category = '4-Wheelers'
GROUP BY state
ORDER BY penetration_rate DESC;

/*List the states with negative penetration (decline) in EV sales from 2022 
to 2024? */

SELECT 
    state,
    PR_2022,
    PR_2024
FROM
    (
        SELECT 
            state,
            SUM(CASE WHEN dd.fiscal_year = 2022 THEN electric_vehicles_sold ELSE 0 END)*100 /
            NULLIF(SUM(CASE WHEN dd.fiscal_year = 2022 THEN total_vehicles_sold ELSE 0 END), 0) AS PR_2022,
            
            SUM(CASE WHEN dd.fiscal_year = 2024 THEN electric_vehicles_sold ELSE 0 END)*100 /
            NULLIF(SUM(CASE WHEN dd.fiscal_year = 2024 THEN total_vehicles_sold ELSE 0 END), 0) AS PR_2024
        FROM 
            EV_sales_by_state esbs
        JOIN 
            Dim_Date dd ON dd.date = esbs.date
        GROUP BY 
            state
    ) AS RATE
WHERE 
    PR_2024 < PR_2022;

/*What are the quarterly trends based on sales volume for the top 5 EV 
makers (4-wheelers) from 2022 to 2024*/

WITH top5
     AS (SELECT TOP 5 maker,
                      Sum(electric_vehicles_sold) AS total
         FROM   ev_sales_by_makers esbm
                JOIN dim_date dd
                  ON dd.date = esbm.date
         WHERE  dd.fiscal_year BETWEEN 2022 AND 2024
                AND vehicle_category = '4-Wheelers'
         GROUP  BY maker
         ORDER  BY total DESC)

SELECT dd.fiscal_year,
       dd.quarter,
       t5.maker
FROM   top5 AS t5
       JOIN ev_sales_by_makers esbm
         ON esbm.maker = t5.maker
       JOIN dim_date dd
         ON dd.date = esbm.date
WHERE  dd.fiscal_year BETWEEN 2022 AND 2024
ORDER  BY dd.fiscal_year,
          dd.quarter; 

/*How do the EV sales and penetration rates in Delhi compare to 
Karnataka for 2024?*/

    SELECT
        state,
        SUM(electric_vehicles_sold) AS EV_sales,
        SUM(electric_vehicles_sold)*100.0/SUM(total_vehicles_sold) AS Penetration_rate
    FROM
        EV_sales_by_state AS esbs
    JOIN Dim_Date dd ON 
        dd.date = esbs.date
    WHERE
        state IN ('Delhi', 'Karnataka')
    AND 
        fiscal_year = 2024
    GROUP BY
        state

/*What are the peak and low season months for EV sales based on the 
data from 2022 to 2024?*/

SELECT
    FORMAT(dd.date, 'MMMM yyyy') AS month_year,
    SUM(electric_vehicles_sold) AS sales
FROM EV_sales_by_state esbm
JOIN Dim_Date dd 
    ON dd.date = esbm.date
WHERE dd.fiscal_year BETWEEN 2022 AND 2024
GROUP BY FORMAT(dd.date, 'MMMM yyyy'), YEAR(dd.date), MONTH(dd.date)
ORDER BY YEAR(dd.date), MONTH(dd.date);

/*List down the compounded annual growth rate (CAGR) in 4-wheeler 
units for the top 5 makers from 2022 to 2024.*/

WITH cte AS (
    SELECT
        TOP 5 maker,
        SUM(electric_vehicles_sold) AS Sales
    FROM
        EV_Sales_by_Makers esbm
    JOIN Dim_Date dd ON
        dd.date = esbm.date
    WHERE
        dd.fiscal_year BETWEEN 2022 AND 2024
        AND esbm.vehicle_category = '4-Wheelers'
    GROUP BY
        maker
    ORDER BY
        Sales DESC
)

SELECT
    cte.maker,
    SUM(CASE WHEN dd.fiscal_year = 2022 THEN electric_vehicles_sold ELSE 0 END) AS EV_2022,
    SUM(CASE WHEN dd.fiscal_year = 2024 THEN electric_vehicles_sold ELSE 0 END) AS EV_2024,
    ROUND(
        (POWER(
            NULLIF(SUM(CASE WHEN dd.fiscal_year = 2024 THEN electric_vehicles_sold ELSE 0 END), 0) * 1.0 /
            NULLIF(SUM(CASE WHEN dd.fiscal_year = 2022 THEN electric_vehicles_sold ELSE 0 END), 0),
            1 / 2.0
        ) - 1) * 100, 2
    ) AS CAGR
FROM
    cte
JOIN EV_Sales_by_Makers esbm ON
    esbm.maker = cte.maker
JOIN Dim_Date dd ON
    dd.date = esbm.date
GROUP BY
    cte.maker
ORDER BY CAGR DESC;

/*List down the top 10 states that had the highest compounded annual 
growth rate (CAGR) from 2022 to 2024 in total vehicles sold.*/

WITH cte AS (
    SELECT 
        state, 
        SUM(CASE WHEN dd.fiscal_year = 2022 THEN total_vehicles_sold ELSE 0 END) AS Total_2022,
        SUM(CASE WHEN dd.fiscal_year = 2024 THEN total_vehicles_sold ELSE 0 END) AS Total_2024,
        ((POWER(
            SUM(CASE WHEN dd.fiscal_year = 2024 THEN total_vehicles_sold ELSE 0 END) * 1.0 /
            NULLIF(SUM(CASE WHEN dd.fiscal_year = 2022 THEN total_vehicles_sold ELSE 0 END), 0),
            1 / 2.0) - 1) * 100) AS CAGR
    FROM
        EV_sales_by_state esbs
    JOIN Dim_Date dd ON
        dd.date = esbs.date
    WHERE
        dd.fiscal_year BETWEEN 2022 AND 2024
    GROUP BY 
        state
)
SELECT TOP 10
    cte.state,
    cte.CAGR
FROM
    cte
ORDER BY
    cte.CAGR DESC;

/*What is the projected number of EV sales (including 2-wheelers and 4-
wheelers) for the top 10 states by penetration rate in 2030, based on the 
compounded annual growth rate (CAGR) from previous years?*/

/*Top 10 States by Penetration Rate in 2024*/

WITH top10 AS (
    SELECT TOP 10
        state,
        SUM(electric_vehicles_sold) * 100.0 / SUM(total_vehicles_sold) AS Penetration_Rate_2024,
        SUM(electric_vehicles_sold) AS EV_Sales_2024,
        SUM(total_vehicles_sold) AS Total_Sales_2024
    FROM 
        EV_sales_by_state esbs
    JOIN 
        Dim_Date dd ON dd.date = esbs.date
    WHERE 
        dd.fiscal_year = 2024
    GROUP BY 
        state
    ORDER BY 
        Penetration_Rate_2024 DESC
),

CAGR AS (
    SELECT 
        state,
        SUM(CASE WHEN dd.fiscal_year = 2022 THEN electric_vehicles_sold ELSE 0 END) AS EV_Sales_2022,
        SUM(CASE WHEN dd.fiscal_year = 2024 THEN electric_vehicles_sold ELSE 0 END) AS EV_Sales_2024,
        (POWER(
            NULLIF(SUM(CASE WHEN dd.fiscal_year = 2024 THEN electric_vehicles_sold ELSE 0 END), 0) * 1.0 /
            NULLIF(SUM(CASE WHEN dd.fiscal_year = 2022 THEN electric_vehicles_sold ELSE 0 END), 0),
            1.0 / 2.0
        ) - 1) * 100 AS CAGR
    FROM 
        EV_sales_by_state esbs
    JOIN 
        Dim_Date dd ON dd.date = esbs.date
    WHERE 
        dd.fiscal_year BETWEEN 2022 AND 2024
    GROUP BY 
        state
)
/*Project sales in 2030*/
SELECT 
    top10.state,
    top10.EV_Sales_2024,
    CAGR.CAGR,
    ROUND(top10.EV_Sales_2024 * POWER(1 + CAGR.CAGR / 100, 2030 - 2024), 0) AS Projected_EV_Sales_2030
FROM 
    top10
JOIN 
    CAGR ON top10.state = CAGR.state
ORDER BY 
    Projected_EV_Sales_2030 DESC;

/*Estimate the revenue growth rate of 4-wheeler and 2-wheelers 
EVs in India for 2022 vs 2024 and 2023 vs 2024, assuming an average 
unit price

2-Wheelers    INR 85,000
4-Wheelers    INR 1500000 */

/* First calculating the total 4-Wheelers and 2-Wheelers sales for each year */

WITH sales_summary AS (
    SELECT 
        dd.fiscal_year,
        esbm.vehicle_category,
        SUM(electric_vehicles_sold) AS total_units_sold
    FROM 
        EV_Sales_by_Makers esbm
    JOIN 
        Dim_Date dd ON dd.date = esbm.date
    WHERE 
        dd.fiscal_year BETWEEN 2022 AND 2024
        AND esbm.vehicle_category IN ('2-Wheelers', '4-Wheelers')
    GROUP BY 
        dd.fiscal_year, esbm.vehicle_category
),

/* Revenue Calculation Based on Average Unit Price */
revenue_summary AS (
    SELECT 
        fiscal_year,
        vehicle_category,
        CASE 
            WHEN vehicle_category = '2-Wheelers' THEN total_units_sold * 85000
            WHEN vehicle_category = '4-Wheelers' THEN total_units_sold * 1500000
        END AS revenue
    FROM 
        sales_summary
),

/* Calculating Revenue Growth Rates */
growth_rate AS (
    SELECT 
        a.vehicle_category,
        a.revenue AS revenue_2022,
        b.revenue AS revenue_2023,
        c.revenue AS revenue_2024,
        ROUND((NULLIF(c.revenue, 0) - NULLIF(a.revenue, 0)) / NULLIF(a.revenue, 0) * 100, 2) AS growth_2022_2024,
        ROUND((NULLIF(c.revenue, 0) - NULLIF(b.revenue, 0)) / NULLIF(b.revenue, 0) * 100, 2) AS growth_2023_2024
    FROM 
        revenue_summary a
    JOIN 
        revenue_summary b ON a.vehicle_category = b.vehicle_category AND b.fiscal_year = 2023
    JOIN 
        revenue_summary c ON a.vehicle_category = c.vehicle_category AND c.fiscal_year = 2024
    WHERE 
        a.fiscal_year = 2022
)

SELECT 
    vehicle_category,
    revenue_2022,
    revenue_2023,
    revenue_2024,
    growth_2022_2024 AS "Growth Rate 2022 vs 2024 (%)",
    growth_2023_2024 AS "Growth Rate 2023 vs 2024 (%)"
FROM 
    growth_rate;
