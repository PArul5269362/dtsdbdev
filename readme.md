## Queries Required

1. **List Available Vehicles by Category and Location**
   - **Requirement:** Retrieve a list of available vehicles, sorted by category (Economy, Mid-Size, Premium) and location. This query helps customers or staff quickly find available vehicles in their desired category and location.
   - **Details:** Include VehicleID, Manufacturer, Model, Location (Address, City), and Category Name in the results.

2. **Daily Rental Summary Report**
   - **Requirement:** Generate a daily summary report that shows the number of vehicles rented today, categorized by vehicle category. This report aids in understanding the daily rental volume and category preferences.
   - **Details:** Include the date, Category Name, and Count of Rentals.

3. **Vehicle Utilization Rate**
   - **Requirement:** Calculate the utilization rate of vehicles over a period of your choice. The utilization rate is defined as the number of days a vehicle is rented divided by the total number of days in the period.
   - **Details:** Include VehicleID, Manufacturer, Model, UtilizationRate. Order the results by UtilizationRate descending.

4. **Customer Loyalty Report**
   - **Requirement:** Identify returning customers who have rented vehicles more than a certain number of times (of your choosing) within the last year. This report is useful for marketing purposes, such as targeting loyal customers with special offers.
   - **Details:** Include CustomerID, FirstName, LastName, Email, and Total Rentals. Order by Total Rentals descending.


5. **Performance Analysis of Rental Locations**
   - **Requirement:** Analyze the performance of rental locations based on the total revenue generated and the average rental duration. This analysis helps in identifying high-performing locations and those that may require marketing boosts or operational adjustments.
   - **Details:** For each location, include LocationID, Address, City, Total Revenue Generated, Average Rental Duration (in days), and the Count of Rentals. Sort the results by Total Revenue Generated descending.

Implementing these queries would involve complex SQL features like `JOIN` operations across multiple tables, aggregate functions (`COUNT`, `SUM`, `AVG`), and `GROUP BY` clauses, reflecting a range of difficulties from medium to advanced. These queries not only serve immediate operational needs but also provide strategic insights for business development and customer relationship management.