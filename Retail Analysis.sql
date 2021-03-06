CREATE DATABASE RETAIL_ANALYSIS

-------------DATA PREPERATION AND UNDERSTANDING-----------


USE RETAIL_ANALYSIS


--Q1. TOTAL NUMBER OF ROWS

SELECT 'CUSTOMER' as TBL_NAME, COUNT (*) AS NO_OF_RECORDS FROM DBO.Customer
UNION ALL
SELECT 'PRODUCT_CATEGORY', COUNT(*) FROM DBO.prod_cat_info
UNION ALL
SELECT 'TRANSACTION', COUNT (*) FROM DBO.Transactions

--Q2. NUMBER OF RETURN TRANSACTIONS

SELECT COUNT (*) FROM Transactions WHERE Qty<0

-- Q3. Changed date format

--Q4. What is the time range of the transaction data available for analysis? Show the output in number of days, months and years simlumtaneously in different columns


SELECT 
MIN(tran_date) AS First_Date, MAX(tran_date) AS Last_Date,
DATEDIFF(DAY, MIN(tran_date), MAX(tran_date)) AS NO_OF_DAYS,
DATEDIFF(MONTH, MIN(tran_date), MAX(tran_date))  AS NO_OF_MONTHS,
DATEDIFF(YEAR, MIN(tran_date), MAX(tran_date)) AS NO_OF_YEARS

FROM Transactions

--Q5. Which product category does the sub-category DIY belong to

SELECT  prod_cat FROM prod_cat_info
WHERE prod_subcat = 'DIY'

-------------DATA ANALYSIS-----------------

--Q1. Which channel is frequently used for transactions?

SELECT top 1 Store_type, COUNT(Store_type) AS Frequency FROM Transactions 
GROUP BY Store_type
ORDER BY COUNT(Store_type) DESC

--Q2. Count of Male and Female customers in database

Select Gender, COUNT(Gender) AS Count_of_Customer from Customer
Group By Gender

--Q3. City name and count of maximum number of customers

SELECT top 1 city_code, COUNT(city_code) AS Frequency FROM Customer
GROUP BY city_code
ORDER BY COUNT(city_code) DESC

-- Q4. How many sub- categories are there under books category

SELECT count(prod_subcat) AS CATEGORY_CODE FROM prod_cat_info
WHERE prod_cat LIKE 'Books'

--Q5. Maximum quantity of products ever ordered

SELECT Max(Qty) FROM Transactions

--Q6. What is the net total revenue generated in categories Electronics and Books

SELECT Sum(Total_amt) AS Total_revenue , prod_cat FROM Transactions INNER JOIN prod_cat_info ON Transactions.prod_cat_code = prod_cat_info.prod_cat_code
Where prod_cat in ( 'Books' ,'Electronics')
Group by prod_cat

--Q7. How many customers have >10 transactions excluding returns?

SELECT cust_id, COUNT(cust_id) AS Count_of_Transactions FROM Transactions
WHERE Qty >= 0
GROUP BY cust_id
HAVING COUNT(cust_id) > 10

--Q8. What is the combined revenue earned from the Electronics and Clothing categories , from flagship stores?

SELECT SUM(total_amt) AS CR_Electronics_Clothing_Flagship FROM transactions INNER JOIN prod_cat_info ON Transactions.prod_cat_code = prod_cat_info.prod_cat_code
WHERE prod_cat IN ('Electronics', 'Clothing') AND Store_type IN('Flagship store')

--Q9. What is the total "revenue" generated from "Male" customers in "Electronics category"? Output should display total revenue by prod sub-cat.

SELECT SUM(total_amt) AS Total_Revenue, prod_subcat AS Product_Subcategory FROM 
Customer
JOIN Transactions
ON Transactions.cust_id= Customer.customer_Id
JOIN prod_cat_info
On Transactions.prod_cat_code = prod_cat_info.prod_cat_code

WHERE prod_cat IN ('Electronics') AND Gender IN ('M')
GROUP BY prod_subcat

--Q10. What is percentage of sales and returns by product sub-category? Display only top 5 categories in terms of sales.

Select  TOP 5 P.prod_subcat [Subcategory] ,

	Round(SUM(case when T.Qty > 0 then T.Qty else 0 end),2) [Sales]  , 
    Round(SUM(case when T.Qty < 0 then T.Qty   else 0 end),2) [Returns] ,

    Round(SUM(case when T.Qty > 0 then T.Qty else 0 end),2) 
				- Round(SUM(case when T.Qty < 0 then T.Qty   else 0 end),2)  [total_qty],
    
	((Round(SUM(case when T.Qty < 0 then T.Qty  else 0 end),2)) /
                  (Round(SUM(case when T.Qty > 0 then T.Qty else 0 end),2)
                 - Round(SUM(case when T.Qty < 0 then T.Qty   else 0 end),2)))*100  [Returs_Percentage],

    ((Round(SUM(case when T.Qty > 0 then T.Qty  else 0 end),2))/
                  (Round(SUM(case when T.Qty > 0 then T.Qty else 0 end),2)
                 - Round(SUM(case when T.Qty < 0 then T.Qty   else 0 end),2)))*100  [Sales_Percentage]

from Transactions AS T INNER JOIN prod_cat_info AS P ON T.prod_subcat_code = P.prod_sub_cat_code
    
	group by P.prod_subcat
    order by [sales_Percentage] DESC



--- Q11. For all customers aged between 25-30 find what is the net total revenue generated by these consumers in last 30 days of transactions from max transaction date available in the data

SELECT SUM(total_amt) as Net_Total_Revenue
	FROM (SELECT *,MAX(Transactions.tran_date) OVER () as max_tran_date From Transactions) 
		transactions JOIN Customer
		ON transactions.cust_id = Customer.customer_Id
			WHERE Transactions.tran_date >= DATEADD(day, -30, Transactions.max_tran_date) 
			AND 
			Transactions.tran_date >= DATEADD(YEAR, 25, Customer.DOB) 
			AND 
			Transactions.tran_date < DATEADD(YEAR, 31, Customer.DOB);

---Q12. Which product category has seen the max value of returns in the last 3 months of transactions?


Select Top 1 prod_cat, Qty, tran_date
from Transactions join prod_cat_info on Transactions.prod_cat_code = prod_cat_info.prod_cat_code
WHERE tran_date >= DATEADD(month, -3, 28-02-2014)
Group BY prod_cat, Qty, tran_date
Order by Count(Case when Qty > 0 then 1 
		else 0 
		end) ;


-- Q.13: Which store type sells the maximum products, by value of sales amount and by quantity sold

select Top 1 Store_type, COUNT(Qty) AS Quantity_Sold, Max(total_amt) AS Value_Of_Sales from Transactions
Group by Store_type
Order by Store_type ASC;

---Q.14. What are the categories for which average revenue is above the overall average

SELECT prod_cat_info.prod_cat AS Product_Category, AVG(Transactions.total_amt) AS Average 
FROM (SELECT Transactions.*, AVG(Transactions.total_amt) OVER () as overall_average
      FROM Transactions Transactions) Transactions JOIN
     prod_cat_info 
     ON Transactions.prod_cat_code = prod_cat_info.prod_cat_code
GROUP BY prod_cat_info.prod_cat, overall_average
HAVING AVG(Transactions.total_amt) > overall_average;


---Q15. Find the average and total revenue by each subcategory for the categories which are among top 5 categories in terms of quantity sold.

SELECT P.prod_cat as Sub_Category, 
	Round(AVG(total_amt),2) as Avg_Revenue,
	SUM(total_amt) as Total_Revenue
from Transactions as T INNER JOIN prod_Cat_info as P
				ON T.prod_cat_code = P.prod_cat_code AND T.prod_subcat_code = P.prod_sub_cat_code
	
	WHERE P.prod_cat_code 
				
				IN (
						select top 5 P.prod_cat_code
						from prod_cat_info as P inner join Transactions as T
							ON P.prod_cat_code = T.prod_cat_code AND P.prod_sub_cat_code = T.prod_subcat_code
						group by P.prod_cat_code
						order by sum(Qty) desc
					)
group by P.prod_cat