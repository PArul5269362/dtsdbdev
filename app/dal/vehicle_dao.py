

class VehicleDAO:
    """
    Data Access Object for vehicles. This class is responsible for all CRUD operations on vehicles.
    The Data Source is Injected into the class in the __init__ method (when a VehiceDAO object is created)
    You should inject a Data Source that can perform database read/write operations.
    Next, modify the methods below to perform the required CRUD operations using the data source. There is no requirement for it to be backwards compatible with the Dictionary in memory database.
    You can use this model to implement as much of the functionality as you choose or use your own solution.
    """
    def __init__(self, data_source) -> None:
        self.data_source = data_source

    # Retrieve all vehicles
    def get_all_vehicles(self):
        return list(self.data_source["vehicles"].values())

    # Retrieve a single vehicle
    def get(self, vehicle_id):
        return self.data_source["vehicles"].get(vehicle_id, None)

    # Add a new vehicle
    def add_vehicle(self, type, category, manufacturer):
        new_vehicle = {
            'id': max(self.data_source["vehicles"].keys())+1 if len(self.data_source["vehicles"].keys())>0 else 1,
            'type': self.data_source["car_types"][int(type)],
            'category': self.data_source["car_categories"][int(category)],
            'manufacturer': self.data_source["manufacturers"][int(manufacturer)],
            'type_id': type,
            'category_id': category,
            'manufacturer_id': manufacturer
        }
        
        self.data_source["vehicles"][new_vehicle["id"]]= new_vehicle
        return 1
        
    # Update a vehicle
    def update_vehicle(self, vehicle_id, vehicle_data):
        vehicle_to_update = self.get(vehicle_id)
        if vehicle_to_update:
            vehicle_to_update['type'] = vehicle_data['type']
            vehicle_to_update['category'] = vehicle_data['category']
            vehicle_to_update['manufacturer'] = vehicle_data['manufacturer']
            vehicle_to_update['model'] = vehicle_data['model']
            vehicle_to_update['location'] = vehicle_data['location']
            vehicle_to_update['status'] = vehicle_data['status']

    # Delete a vehicle
    def delete_vehicle(self, vehicle_id):
        self.data_source["vehicles"].pop(int(vehicle_id), None)
