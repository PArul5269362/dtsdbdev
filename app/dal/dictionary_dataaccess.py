
# In-memory data storage for vehicles
# Used for Testing and Development
# You should use a database in production

class DictionaryDataAccess:

    in_memory_database = {
        "vehicles": {
            1: {'id': 1, 'type_id':1, 'type': 'Car', 'category_id': 1, 'category': 'Economy', 'manufacturer_id':6, 'manufacturer': 'Toyota', 'model': 'Yaris Hatchback', 'location': 'City Centre', 'status': 'Rented Out'},
            2: {'id': 2, 'type_id':2,'type': 'Bike', 'category_id': 2, 'category': 'Comfort', 'manufacturer_id':8,'manufacturer': 'Honda', 'model': 'Gold Wing Tour', 'location': 'Airport', 'status': 'Being Serviced'},
            3: {'id': 3, 'type_id':3, 'type': 'Scooter', 'category_id': 3, 'category': 'Premium', 'manufacturer_id':9,'manufacturer': 'Vespa', 'model': 'SXL 150', 'location': 'City Centre', 'status': 'Not Available'}
        },
        "car_types": {1: "Car", 2: "Bike", 3: "Scooter"},
        "car_categories": {1: "Economy", 2: "Mid Size", 3: "Premium"},
        "manufacturers": {
            1: "Tesla", 2: "Ford", 3: "Mini", 4: "BMW", 5: "Mercedes", 6: "Toyota", 7: "Porsche", 8: "Honda", 9: "Vespa"
        },
        "locations": {1: "City Centre", 2: "Airport", 3: "Train Station"}
    }
    
