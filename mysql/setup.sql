DROP DATABASE IF EXISTS wheelease;
CREATE DATABASE wheelease;

USE wheelease;
-- Create tables
CREATE TABLE Driver (
    driver_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    address VARCHAR(255) NOT NULL,
    phone_number VARCHAR(20) NOT NULL,
    email VARCHAR(255) NOT NULL,
    license_number VARCHAR(50) NOT NULL
);

CREATE TABLE Insurance (
	insurance_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL
);


CREATE TABLE Rental (
    rental_id INT AUTO_INCREMENT PRIMARY KEY,
    rental_startdate DATETIME NOT NULL,
    rental_enddate DATETIME NOT NULL,
    start_mileage INT NOT NULL,
    end_mileage INT,
    vehicle_id VARCHAR(50) NOT NULL,
    insurance_id INT,
    FOREIGN KEY (insurance_id) REFERENCES Insurance(insurance_id)
);

CREATE TABLE DriverRental (
    driver_id INT,
    rental_id INT,
    FOREIGN KEY (driver_id) REFERENCES Driver(driver_id),
    FOREIGN KEY (rental_id) REFERENCES Rental(rental_id),
    PRIMARY KEY (driver_id, rental_id)
);

CREATE TABLE Customer (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(255) NOT NULL,
    last_name VARCHAR(255) NOT NULL,
    address VARCHAR(255) NOT NULL,
    phone_number VARCHAR(20) NOT NULL,
    email VARCHAR(255) NOT NULL
);

CREATE TABLE Branch (
    branch_id INT AUTO_INCREMENT PRIMARY KEY,
    address VARCHAR(255) NOT NULL,
    phone_number VARCHAR(20) NOT NULL,
    email VARCHAR(255) NOT NULL
);

CREATE TABLE Employee (
    employee_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    address VARCHAR(255) NOT NULL,
    branch INT NOT NULL,
    phone_number VARCHAR(20) NOT NULL,
    email VARCHAR(255) NOT NULL,
    FOREIGN KEY (branch) REFERENCES Branch(branch_id)
);


CREATE TABLE Category (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL
);

CREATE TABLE DailyRate (
    dailyrate_id INT AUTO_INCREMENT PRIMARY KEY,
    cost DECIMAL(10,2) NOT NULL
);

CREATE TABLE CustomerRental (
    customer_id INT,
    rental_id INT,
    FOREIGN KEY (customer_id) REFERENCES Customer(customer_id),
    FOREIGN KEY (rental_id) REFERENCES Rental(rental_id),
    PRIMARY KEY (customer_id, rental_id)
);

CREATE TABLE Model (
    model_id INT AUTO_INCREMENT PRIMARY KEY,
    manufacturer VARCHAR(255) NOT NULL,
    transmission VARCHAR(50) NOT NULL,
    model VARCHAR(255) NOT NULL,
    fuel_type VARCHAR(50) NOT NULL,
    engine_size DECIMAL(3,2) NOT NULL,
    category_id INT NOT NULL,
    FOREIGN KEY (category_id) REFERENCES Category(category_id)
);


CREATE TABLE Vehicle (
    registration VARCHAR(50) PRIMARY KEY,
    model_id INT NOT NULL,
    mileage DECIMAL(10,2) NOT NULL,
    dailyrate_id INT NOT NULL,
    availability BOOLEAN NOT NULL,
    branch INT NOT NULL,
    FOREIGN KEY (model_id) REFERENCES Model(model_id),
    FOREIGN KEY (dailyrate_id) REFERENCES DailyRate(dailyrate_id),
    FOREIGN KEY (branch) REFERENCES Branch(branch_id)
);

-- Create Procedures, indexes and whatnot 

DELIMITER //

CREATE PROCEDURE CreateRentalTransaction(
    IN p_customer_id INT,
    IN p_driver_id INT,
    IN p_vehicle_registration VARCHAR(50),
    IN p_rental_startdate DATETIME,
    IN p_rental_enddate DATETIME
)
BEGIN
    DECLARE v_start_mileage DECIMAL(10,2);
    
    -- Retrieve current mileage of the vehicle
    SELECT mileage INTO v_start_mileage
    FROM Vehicle
    WHERE registration = p_vehicle_registration;
    
    -- Create rental transaction with start mileage
    INSERT INTO Rental (rental_startdate, rental_enddate, vehicle_id, start_mileage)
    VALUES (p_rental_startdate, p_rental_enddate, p_vehicle_registration, v_start_mileage);
    
    -- Retrieve the rental_id of the newly created rental transaction
    SELECT LAST_INSERT_ID() AS rental_id;
    
    -- Update vehicle availability to unavailable
    UPDATE Vehicle
    SET availability = 0
    WHERE registration = p_vehicle_registration;
    
END //

DELIMITER ;


-- Test data for Driver table
INSERT INTO Driver (name, address, phone_number, email, license_number) VALUES 
('John Doe', '123 Main St', '555-1234', 'john@example.com', 'ABC123'),
('Jane Smith', '456 Elm St', '555-5678', 'jane@example.com', 'XYZ789');

-- Test data for Insurance table
INSERT INTO Insurance(name) VALUES
('Comprehensive'),
('Third-Party and Theft');


-- Example rental transactions

-- Rental transaction for Customer ID 1, Driver ID 1, renting vehicle with registration 'ABC123'
CALL CreateRentalTransaction(1, 1, 'ABC123', '2024-05-12 08:00:00', '2024-05-15 17:00:00');

-- Rental transaction for Customer ID 2, Driver ID 2, renting vehicle with registration 'XYZ789'
CALL CreateRentalTransaction(2, 2, 'XYZ789', '2024-05-14 10:00:00', '2024-05-18 15:00:00');

-- Rental transaction for Customer ID 3, Driver ID 2, renting vehicle with registration 'RJ69 XYZ'
CALL CreateRentalTransaction(3, 2, 'RJ69 XYZ', '2024-05-14 10:00:00', '2024-05-18 15:00:00');


-- Test data for daily_rate table
INSERT INTO DailyRate (cost) VALUES 
(50.00),
(60.00);

-- Test data for Customer table
INSERT INTO Customer (first_name, last_name, address, phone_number, email) VALUES 
('Alice', 'Johnson', '789 Oak St', '555-2468', 'alice@example.com'),
('Bob', 'Williams', '101 Pine St', '555-1357', 'bob@example.com'),
('Akshaiya','Arul','420 Loserville', '666-777', 'poopyfart@fartnugget.com');

-- Test data for Category table
INSERT INTO Category (name) VALUES 
('Car'),
('Scooter'),
('Bike');

-- Test data for Model table
INSERT INTO Model (manufacturer, transmission, model, fuel_type, engine_size, category_id) VALUES 
('Toyota', 'Manual', 'Corolla', 'Petrol', 1.4, 1),
('Honda', 'Automatic', 'Civic', 'Electricity', 1.6, 1),
('Vespa', 'Automatic', 'Primavera', 'Petrol', 0.8, 2);


-- Test data for Branch table
INSERT INTO Branch (address, phone_number, email) VALUES 
('123 Branch St', '555-1111', 'branch1@example.com'),
('456 Branch Ave', '555-2222', 'branch2@example.com');

-- Test data for Vehicle table
INSERT INTO Vehicle (registration, model_id, mileage, dailyrate_id, availability, branch) VALUES 
('ABC123', 1, 50000, 1, 1, 1),
('XYZ789', 2, 75000, 2, 1, 2),
('RJ60 XYZ', 3, 4567, 1, 1, 1);

-- Test data for Employee table
INSERT INTO Employee (name, address, branch, phone_number, email) VALUES 
('Jim Brown', '789 Elm St', 1, '555-3333', 'jim@example.com'),
('Sara Lee', '321 Maple St', 2, '555-4444', 'sara@example.com');



