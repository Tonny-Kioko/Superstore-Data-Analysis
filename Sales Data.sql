--Data Inspection
SELECT * FROM Sales_data

--Checking Unique Values in the table
SELECT DISTINCT STATUS FROM Sales_data;
SELECT DISTINCT YEAR_ID FROM Sales_data;
SELECT DISTINCT PRODUCTLINE FROM Sales_data;
SELECT DISTINCT COUNTRY FROM Sales_data;
SELECT DISTINCT DEALSIZE FROM Sales_data;
SELECT DISTINCT TERRITORY FROM Sales_data;


                       --DATA ANALYSIS
--Grouping the sales made with the product line
SELECT productline, SUM (sales) Revenue
FROM Sales_data
GROUP BY PRODUCTLINE
ORDER BY 2 DESC

--Year with the highest sales
SELECT YEAR_ID, SUM (sales) Revenue
FROM Sales_data
GROUP BY YEAR_ID
ORDER BY 2 DESC
--YEAR_ID	Revenue
2004	4724162.6
2003	3516979.54
2005	1791486.71

--Why did 2005 have the least sales? How many months did they operate?

SELECT DISTINCT MONTH_ID FROM Sales_data
WHERE YEAR_ID = 2005;
--Operated for five months only. 

--Deals with the highest revenue 
SELECT DEALSIZE, SUM (sales) Revenue
FROM Sales_data
GROUP BY DEALSIZE
ORDER BY 2 DESC

--Best month for sales in a particular year
SELECT month_id, SUM (sales) Revenue, COUNT (Ordernumber) Frequency
FROM Sales_data 
WHERE YEAR_ID = 2003 --Change for specific year
GROUP BY MONTH_ID
ORDER BY 2 DESC

--Most sales happen in November. What is the best selling product?
SELECT month_id, SUM (sales) Revenue, COUNT (Ordernumber) Frequency, PRODUCTLINE
FROM Sales_data 
WHERE YEAR_ID = 2003 
AND MONTH_ID = 11
GROUP BY MONTH_ID, PRODUCTLINE
ORDER BY 2 DESC

--Who is the best customer to the company? RFM Analysis
SELECT customername,
       SUM (sales) MonetaryValue, 
	   AVG (sales) AvgMonetaryValue, 
	   COUNT (ordernumber) Frequency, 
	   MAX (orderdate) LastOrderDate, 
	   (SELECT MAX (orderdate) FROM Sales_data) AS Max_order_date,
	   DATEDIFF (DD, MAX (orderdate), (SELECT MAX (orderdate) FROM Sales_data)) Recency
FROM Sales_data
GROUP BY CUSTOMERNAME
--ORDER BY 2

DROP TABLE IF EXISTS #RFM
WITH rfm AS 
(
SELECT customername,
       SUM (sales) MonetaryValue, 
	   AVG (sales) AvgMonetaryValue, 
	   COUNT (ordernumber) Frequency, 
	   MAX (orderdate) LastOrderDate, 
	   (SELECT MAX (orderdate) FROM Sales_data) AS Max_order_date,
	   DATEDIFF (DD, MAX (orderdate), (SELECT MAX (orderdate) FROM Sales_data)) Recency
FROM Sales_data
GROUP BY CUSTOMERNAME
--ORDER BY 2
),
rfm_calc AS (
SELECT *, 
	  NTILE (4) OVER (ORDER BY Recency) rfm_recency, 
	  NTILE (4) OVER (ORDER BY Frequency) rfm_frequency, 
	  NTILE (4) OVER (ORDER BY MonetaryValue) rfm_monetary
FROM rfm 
--ORDER BY 4 DESC
)
SELECT  *, rfm_recency + rfm_frequency + rfm_monetary AS rfm_cell, 
 CAST (rfm_recency AS VARCHAR) + CAST (rfm_frequency AS VARCHAR) + CAST (rfm_monetary AS VARCHAR)
 RFM_Cell_s
 INTO #RFM
FROM rfm_calc

--Temporary table #RFM has been created 
SELECT * FROM #RFM

SELECT Customername, rfm_recency, rfm_frequency,  rfm_monetary,
CASE
		WHEN rfm_cell_s IN (111, 112, 121, 122, 123, 132, 211, 212, 114, 141) THEN 'Lost_Customers'
		WHEN rfm_cell_s IN (133, 134, 143, 244, 334, 343, 344) THEN 'Slipping Away, Valuable Customer'
		WHEN rfm_cell_s IN (311, 411, 331) THEN 'New_Customer'
		WHEN rfm_cell_s IN (222, 223, 233, 322) THEN 'Potential_Churners'
		WHEN rfm_cell_s IN (323, 333, 321, 422, 332, 432) THEN 'Active'
		WHEN rfm_cell_s IN (433, 434, 443, 444) THEN 'Loyal'
		END rfm_segment
FROM #RFM


--Which products are often sold together?
 SELECT ',' + PRODUCTCODE Product_codes, ORDERNUMBER
 FROM Sales_data
 WHERE ORDERNUMBER IN (
	 SELECT ordernumber 
	 FROM (
		 SELECT Ordernumber, COUNT (*) rn
		 FROM Sales_data
		 WHERE STATUS = 'Shipped'
		 GROUP BY ORDERNUMBER
	) m
	WHERE rn =2
	)