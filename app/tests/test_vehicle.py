"""
Test module for the vehicle data access object
"""
import pytest

from dal.vehicle_dao import VehicleDAO

# Serves the database/data source to the test
@pytest.fixture()
def data_source():
    from dal.dictionary_dataaccess import DictionaryDataAccess
    yield DictionaryDataAccess.in_memory_database

# Given a known test data source with 3 vehicles, the test should return 3 vehicles
def test_get_all_vehicles(data_source):

    # ARRANGE
    

    dao = VehicleDAO(data_source)
    
    # ACT
    vehicles = dao.get_all_vehicles()
    
    # ASSERT
    assert vehicles and vehicles[0]["id"] and vehicles[0]["category_id"]  and vehicles[0]["type_id"]

def test_get_vehicle(data_source):

    # ARRANGE
    v_id = 1
    expected = 1

    # ACT
    dao = VehicleDAO(data_source)

    # ASSERT
    vehicle = VehicleDAO(data_source).get(v_id)

    assert vehicle["id"] == expected

def test_add_vehicle(data_source):

    # ARRANGE
    type_id = 3
    manuf_id = 3
    category_id = 3
    

    # ACT
    dao = VehicleDAO(data_source)
    expected = dao.get_all_vehicles()[-1]["id"] + 1

    dao.add_vehicle(category_id, manuf_id, type_id)
    vehicle = dao.get(expected)

    # ASSERT
    
    assert vehicle["id"] == expected and vehicle["type_id"] == type_id and vehicle["category_id"] == category_id and vehicle["manufacturer_id"] == manuf_id
