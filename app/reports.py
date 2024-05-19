"""
Contains the Reports dictionary
"""
reports_list = [
    {
        "concise_name": "available_vehicles",
        "full_name": "List Available Vehicles by Category and Location",
        "description": "Retrieve a list of available vehicles, sorted by category (Economy, Mid-Size, Premium) and location. This query helps customers or staff quickly find available vehicles in their desired category and location.",
        "details": "Include VehicleID, Manufacturer, Model, Location (Address, City), and Category Name in the results"
    },
    {
        "concise_name": "rental_summary",
        "full_name": "Daily Rental Summary Report",
        "description": "Generate a daily summary report that shows the number of vehicles rented today, categorized by vehicle category. This report aids in understanding the daily rental volume and category preferences.",
        "details": "Include the date, Category Name, and Count of Rentals."
    },
    {
        "concise_name": "utilisation_rate",
        "full_name": "Vehicle Utilisation Rate",
        "description": "Calculate the utilisation rate of vehicles over a period of your choice. The utilisation rate is defined as the number of days a vehicle is rented divided by the total number of days in the period.",
        "details": "Include VehicleID, Manufacturer, Model, UtilizationRate. Order the results by UtilizationRate descending."
    },
    {
        "concise_name": "loyalty_report",
        "full_name": "Customer Loyalty Report",
        "description": "Identify returning customers who have rented vehicles more than once within the last year. This report is useful for marketing purposes, such as targeting loyal customers with special offers.",
        "details": "Include CustomerID, FirstName, LastName, Email, and Total Rentals. Order by Total Rentals descending."
    },
    {
        "concise_name": "rental_loc_performance",
        "full_name": "Performance Analysis of Rental Locations",
        "description": "Analyze the performance of rental locations based on the total revenue generated and the average rental duration. This analysis helps in identifying high-performing locations and those that may require marketing boosts or operational adjustments.",
        "details": "For each location, include LocationID, Address, City, Total Revenue Generated, Average Rental Duration (in days), and the Count of Rentals. Sort the results by Total Revenue Generated descending."
    }
]
