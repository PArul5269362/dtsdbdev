DROP DATABASE IF EXISTS wheelease;
CREATE DATABASE wheelease;

USE wheelease;

CREATE TABLE customer (
	customer_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(255) NOT NULL,
    last_name VARCHAR(255) NOT NULL,
    address_line_one VARCHAR(255) NOT NULL,
    address_line_two VARCHAR(255),
    city VARCHAR(255) NOT NULL,
    postcode VARCHAR(255) NOT NULL,
    phone_number VARCHAR(20) NOT NULL,
    email VARCHAR(255) NOT NULL,
    license_number VARCHAR(50),
    date_of_birth DATE NOT NULL,
    date_of_registration DATE DEFAULT (CURRENT_DATE)
);

CREATE TABLE insurance (
	insurance_id INT AUTO_INCREMENT PRIMARY KEY,
    insurance_type VARCHAR(255) NOT NULL,
    cost_multiplier DECIMAL(3,2) NOT NULL
);

CREATE TABLE vehicle_category (
    vehicle_category_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL
);

CREATE TABLE vehicle_type (
    vehicle_type_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL
);

CREATE TABLE daily_rate_category (
    daily_rate_id INT AUTO_INCREMENT PRIMARY KEY,
    category_class CHAR(1) NOT NULL,
    cost DECIMAL(10,2) NOT NULL
);

CREATE TABLE branch (
	branch_id INT AUTO_INCREMENT PRIMARY KEY,
    address_line_one VARCHAR(255) NOT NULL,
    address_line_two VARCHAR(255),
    city VARCHAR(255) NOT NULL,
    post_code VARCHAR(255) NOT NULL,
    phone_number VARCHAR(20) NOT NULL,
    email VARCHAR(255) NOT NULL
);

CREATE TABLE employee (
	employee_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    address_line_one VARCHAR(255) NOT NULL,
    address_line_two VARCHAR(255),
    city VARCHAR(255) NOT NULL,
    post_code VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    branch_id INT NOT NULL,
    FOREIGN KEY (branch_id) REFERENCES branch(branch_id)
);

CREATE TABLE model (
    model_id INT AUTO_INCREMENT PRIMARY KEY,
    manufacturer VARCHAR(255) NOT NULL,
    transmission VARCHAR(50) NOT NULL,
    model VARCHAR(255) NOT NULL,
    fuel_type VARCHAR(50) NOT NULL,
    engine_size DECIMAL(3,2) NOT NULL,
    vehicle_type_id INT NOT NULL,
    vehicle_category_id INT NOT NULL,
    FOREIGN KEY (vehicle_category_id) REFERENCES vehicle_category(vehicle_category_id),
    FOREIGN KEY (vehicle_type_id) REFERENCES vehicle_type(vehicle_type_id)
);

CREATE TABLE vehicle (
	registration VARCHAR(50) PRIMARY KEY,
    model_id INT NOT NULL,
    mileage INT NOT NULL,
    availability BOOLEAN NOT NULL DEFAULT 1,
    branch_id INT NOT NULL,
    daily_rate_id INT NOT NULL,
	FOREIGN KEY (model_id) REFERENCES model(model_id),
    FOREIGN KEY (daily_rate_id) REFERENCES daily_rate_category(daily_rate_id),
    FOREIGN KEY (branch_id) REFERENCES branch(branch_id)
);

CREATE TABLE rental (
    rental_id INT AUTO_INCREMENT PRIMARY KEY,
    rental_startdate DATE DEFAULT (CURRENT_DATE),
    rental_enddate DATE DEFAULT (CURRENT_DATE+1),
    start_mileage INT NOT NULL DEFAULT 0,
    end_mileage INT,
    vehicle_id VARCHAR(50) NOT NULL,
    insurance_id INT,
    customer_id INT NOT NULL,
    FOREIGN KEY (insurance_id) REFERENCES insurance(insurance_id),
    FOREIGN KEY (customer_id) REFERENCES customer(customer_id)
);

CREATE TABLE driver_rental (
	customer_id INT NOT NULL,
    rental_id INT NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customer(customer_id),
    FOREIGN KEY (rental_id) REFERENCES rental(rental_id)
);

-- intended to log when a vehicle is checked in, checked out etc
CREATE TABLE rental_log (
	rental_id INT NOT NULL,
    log_comment VARCHAR(255) NOT NULL,
    vehicle_mileage INT,
    log_time DATETIME NOT NULL,
    employee_id INT NOT NULL,
    FOREIGN KEY (employee_id) REFERENCES employee(employee_id)
);

CREATE TABLE payment (
	payment_id INT AUTO_INCREMENT PRIMARY KEY,
    rental_id INT NOT NULL,
    customer_id INT NOT NULL,
    cost DECIMAL(15,2) NOT NULL,
    transaction_time DATETIME NOT NULL,
    FOREIGN KEY (rental_id) REFERENCES rental(rental_id),
    FOREIGN KEY (customer_id) REFERENCES customer(customer_id)
);

-- stored procedures, functions and triggers

-- CREATE RENTAL RECORD
DELIMITER // 

CREATE PROCEDURE create_rental_record_SP(
	IN v_registration VARCHAR(50),
    IN c_customer_id INT,
    IN r_start_date DATE,
    IN r_end_date DATE,
    IN r_insurance_id INT,
    IN c_driver_id INT
)
BEGIN

	DECLARE initial_mileage INT;
    DECLARE new_rental_id INT;
    
	-- Check if any of the required fields are NULL
	IF v_registration IS NULL OR c_customer_id IS NULL OR r_end_date IS NULL OR r_insurance_id IS NULL OR c_driver_id IS NULL THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Not all required fields are provided';
	ELSE
		-- Proceed with the rest of the procedure logic
	IF r_start_date IS NULL THEN
		SET r_start_date = CURDATE();
	END IF;
		
        
    START TRANSACTION;
	
    SELECT 'v_registration:', v_registration;
	SELECT 'c_customer_id:', c_customer_id;
	SELECT 'r_start_date:', r_start_date;
	SELECT 'r_end_date:', r_end_date;
	SELECT 'r_insurance_id:', r_insurance_id;
	SELECT 'c_driver_id:', c_driver_id;
    
    SELECT mileage
    INTO initial_mileage
    FROM vehicle
    WHERE registration = v_registration;
    
    SELECT 'initial_mileage:', initial_mileage;
    
    INSERT INTO rental (
    rental_startdate,
    rental_enddate,
    start_mileage,
    vehicle_id,
    insurance_id,
    customer_id) VALUES (
    r_start_date,
    r_end_date,
    initial_mileage,
    v_registration,
    r_insurance_id,
    c_customer_id);
    
    SET new_rental_id = LAST_INSERT_ID();
    
    SELECT 'initial_mileage:', initial_mileage;
    
    UPDATE vehicle
    SET availability = 0
    WHERE registration = v_registration;
    
    SELECT 'initial_mileage:', initial_mileage;
    
    INSERT INTO driver_rental (
    customer_id,
    rental_id) VALUES (c_driver_id, new_rental_id);
    END IF;
    
END //

DELIMITER ;

-- CREATE PAYMENT PROCEDURE

DELIMITER //

CREATE PROCEDURE create_payment_log_SP(IN r_rental_id INT, IN c_customer_id INT)
BEGIN
	DECLARE daily_rate_total DECIMAL(15,2);
    DECLARE insurance_cost DECIMAL(15,2);
	DECLARE total_cost DECIMAL(15,2);
    
    -- Calculate the daily rate total for the rental
    SELECT DRC.cost INTO daily_rate_total
    FROM rental R
    JOIN vehicle V ON R.vehicle_id = V.registration
    JOIN daily_rate_category DRC ON V.daily_rate_id = DRC.daily_rate_id
    WHERE R.rental_id = r_rental_id;

    -- Calculate the insurance cost for the rental
    SELECT I.cost_multiplier * daily_rate_total INTO insurance_cost
    FROM rental R
    JOIN insurance I ON R.insurance_id = I.insurance_id
    WHERE R.rental_id = r_rental_id;

    -- Calculate the total cost
    SET total_cost = daily_rate_total + insurance_cost;

    -- Insert the payment record
    INSERT INTO payment (rental_id, customer_id, cost, transaction_time)
    VALUES (r_rental_id, c_customer_id, total_cost, NOW());

END //
DELIMITER ;

-- VIEWS

-- Vehicle Information View

CREATE VIEW vehicle_details_VIEW AS
SELECT
    vc.name AS Vehicle_Category,
    v.registration AS Registration,
	m.manufacturer AS Manufacturer,
    m.model AS Model,
    v.mileage AS Mileage,
    CASE
        WHEN v.availability = 1 THEN 'Available'
        ELSE 'Unavailable'
    END AS Availability,
    b.city AS Branch,
    drc.category_class AS Daily_Rate_Category,
    drc.cost AS Daily_Rate_Price
FROM
    vehicle v
    INNER JOIN model m ON v.model_id = m.model_id
    INNER JOIN vehicle_category vc ON m.vehicle_category_id = vc.vehicle_category_id
    INNER JOIN branch b ON v.branch_id = b.branch_id
    INNER JOIN daily_rate_category drc ON v.daily_rate_id = drc.daily_rate_id;

-- Reports View

-- Available Vehicles 

CREATE VIEW available_vehicles_VIEW AS
SELECT
    v.registration AS VehicleID,
    m.manufacturer AS Manufacturer,
    m.model AS Model,
    CONCAT(b.address_line_one, ', ', b.city) AS Location,
    vc.name AS Category
FROM
    vehicle v
    INNER JOIN model m ON v.model_id = m.model_id
    INNER JOIN branch b ON v.branch_id = b.branch_id
    INNER JOIN vehicle_category vc ON m.vehicle_category_id = vc.vehicle_category_id
WHERE
    v.availability = 1;

CREATE VIEW rental_summary_VIEW AS
SELECT
    CURRENT_DATE() AS Date,
    vc.name AS Category_Name,
    COUNT(r.rental_id) AS Rental_Count
FROM
    rental r
    INNER JOIN vehicle v ON r.vehicle_id = v.registration
    INNER JOIN model m ON v.model_id = m.model_id
    INNER JOIN vehicle_category vc ON m.vehicle_category_id = vc.vehicle_category_id
WHERE
    r.rental_startdate = CURRENT_DATE()
GROUP BY
    vc.name;

-- Utilisation Rate View
CREATE VIEW utilisation_rate_VIEW AS
SELECT
    v.registration AS VehicleID,
    m.manufacturer AS Manufacturer,
    m.model AS Model,
    SUM(DATEDIFF(r.rental_enddate, r.rental_startdate)) / DATEDIFF(MAX(r.rental_enddate), MIN(r.rental_startdate)) AS UtilizationRate
FROM
    vehicle v
    INNER JOIN rental r ON v.registration = r.vehicle_id
    INNER JOIN model m ON v.model_id = m.model_id
GROUP BY
    v.registration, m.manufacturer, m.model
ORDER BY
    UtilizationRate DESC;

-- Loyalty Report
CREATE VIEW loyalty_report_VIEW AS
SELECT
    c.customer_id AS CustomerID,
    c.first_name AS FirstName,
    c.last_name AS LastName,
    c.email AS Email,
    COUNT(r.rental_id) AS Total_Rentals
FROM
    customer c
    INNER JOIN rental r ON c.customer_id = r.customer_id
WHERE
    r.rental_startdate >= DATE_SUB(CURRENT_DATE(), INTERVAL 1 YEAR)
GROUP BY
    c.customer_id, c.first_name, c.last_name, c.email
HAVING
    COUNT(r.rental_id) > 1
ORDER BY
    Total_Rentals DESC;

-- Rental Location Performance
CREATE VIEW rental_loc_performance_VIEW AS
SELECT
    b.branch_id AS LocationID,
    CONCAT(b.address_line_one, ', ', b.city) AS Address,
    b.city AS City,
    SUM(p.cost) AS Total_Revenue_Generated,
    AVG(DATEDIFF(r.rental_enddate, r.rental_startdate)) AS Average_Rental_Duration,
    COUNT(r.rental_id) AS Rental_Count
FROM
    branch b
    INNER JOIN vehicle v ON b.branch_id = v.branch_id
    INNER JOIN rental r ON v.registration = r.vehicle_id
    INNER JOIN payment p ON r.rental_id = p.rental_id
GROUP BY
    b.branch_id, b.address_line_one, b.city
ORDER BY
    Total_Revenue_Generated DESC;


-- TEST DATA

USE wheelease;

-- INSERT TEST DATA

-- Inserting test data into the customer table
INSERT INTO customer (first_name, last_name, address_line_one, address_line_two, city, postcode, phone_number, email, license_number, date_of_birth, date_of_registration) 
VALUES 
('John', 'Doe', '123 High Street', NULL, 'London', 'W1A 1AA', '020 7946 0958', 'john.doe@example.com', 'ABC123', '1985-05-15', '2023-01-10'),
('Jane', 'Smith', '456 Elm Avenue', NULL, 'Manchester', 'M1 1AE', '0161 856 1234', 'jane.smith@example.com', 'XYZ789', '1990-11-20', '2022-12-05'),
('Alice', 'Johnson', '789 Oak Road', 'Apt 4', 'Birmingham', 'B2 4QA', '0121 789 0123', 'alice.johnson@example.com', 'LMN456', '1978-03-08', '2023-02-18'),
('Bob', 'Williams', '321 Pine Street', NULL, 'Liverpool', 'L1 8JQ', '0151 345 6789', 'bob.williams@example.com', 'PQR678', '1992-07-25', '2023-03-22'),
('Charlie', 'Brown', '654 Cedar Lane', 'Suite 5', 'Leeds', 'LS1 4DY', '0113 345 6789', 'charlie.brown@example.com', 'STU901', '1988-01-30', '2023-04-15'),
('Diana', 'Prince', '987 Maple Court', NULL, 'Glasgow', 'G1 2FF', '0141 567 8901', 'diana.prince@example.com', 'VWX234', '1982-12-14', '2023-05-03'),
('Ethan', 'Hunt', '147 Birch Close', 'Unit 2B', 'Bristol', 'BS1 3XX', '0117 345 6789', 'ethan.hunt@example.com', 'YZA567', '1975-09-10', '2023-05-10'),
('Fiona', 'Apple', '258 Spruce Way', NULL, 'Sheffield', 'S1 4EH', '0114 567 8901', 'fiona.apple@example.com', 'BCD890', '1989-06-17', '2023-06-01'),
('George', 'Washington', '369 Fir Grove', 'Penthouse', 'Edinburgh', 'EH1 3NG', '0131 345 6789', 'george.washington@example.com', 'EFG123', '1984-02-22', '2023-06-10'),
('Hannah', 'Montana', '741 Willow Crescent', NULL, 'Cardiff', 'CF10 1FL', '029 2044 1234', 'hannah.montana@example.com', 'HIJ456', '1995-08-12', '2023-07-01'),
('Ivy', 'Clark', '112 Ash Boulevard', 'Flat 7', 'Leicester', 'LE1 1AA', '0116 254 7890', 'ivy.clark@example.com', 'JKL123', '1987-04-25', '2023-01-15'),
('Jack', 'Davis', '369 Beech Terrace', NULL, 'Coventry', 'CV1 2GT', '024 7683 1234', 'jack.davis@example.com', 'MNO456', '1980-02-12', '2023-02-22'),
('Karen', 'Evans', '478 Palm Street', NULL, 'Hull', 'HU1 3XZ', '01482 123456', 'karen.evans@example.com', 'PQR789', '1994-09-07', '2023-03-18'),
('Liam', 'Morgan', '582 Poplar Lane', 'House 5', 'Newcastle', 'NE1 7XY', '0191 234 5678', 'liam.morgan@example.com', 'STU234', '1981-11-03', '2023-04-12'),
('Mia', 'Turner', '654 Willow Place', NULL, 'Southampton', 'SO14 0YN', '023 8058 1234', 'mia.turner@example.com', 'VWX567', '1993-05-28', '2023-05-15'),
('Noah', 'Green', '789 Cedar Drive', 'Flat 9', 'Nottingham', 'NG1 2DT', '0115 876 7890', 'noah.green@example.com', 'YZA890', '1979-08-18', '2023-06-02'),
('Olivia', 'Harris', '123 Oak Crescent', NULL, 'Brighton', 'BN1 1AA', '01273 123456', 'olivia.harris@example.com', 'BCD123', '1986-10-21', '2023-06-20'),
('Peter', 'Adams', '456 Pine Road', NULL, 'Derby', 'DE1 2HN', '01332 345678', 'peter.adams@example.com', 'EFG456', '1991-12-30', '2023-07-10'),
('Quinn', 'Parker', '321 Birch Avenue', 'Suite 6', 'Plymouth', 'PL1 3QT', '01752 345678', 'quinn.parker@example.com', 'HIJ789', '1984-07-09', '2023-07-25'),
('Rose', 'White', '741 Maple Street', NULL, 'Oxford', 'OX1 1AA', '01865 123456', 'rose.white@example.com', 'JKL234', '1982-03-19', '2023-08-01');


-- Insert vehicle categories
INSERT INTO vehicle_category (name) VALUES ('Economy'), ('Mid-Size'), ('Premium');

-- Inserting test data into the insurance table
INSERT INTO insurance (insurance_type, cost_multiplier) VALUES ('Self Insured', 0), ('Part (With Excess)',0.25), ('Full (No Excess)', 0.45);

-- Inserting test data into the vehicle_category table
INSERT INTO vehicle_type (name) VALUES ('Car'), ('Motorbike'), ('Scooter');

-- Inserting test data into the daily_rate_category table
INSERT INTO daily_rate_category (category_class, cost) VALUES ('C', 30.00), ('B', 50.00), ('A', 80.00);

-- Inserting test data into the branch table
INSERT INTO branch (address_line_one, city, post_code, phone_number, email) 
VALUES 
('789 Oak St', 'Somewhere', '13579', '555-456-7890', 'somewhere@example.com'),
('321 Pine St', 'Nowhere', '02468', '555-789-0123', 'nowhere@example.com');

-- Inserting test data into the employee table
INSERT INTO employee (first_name, last_name, address_line_one, city, post_code, email, branch_id) 
VALUES 
('Alice', 'Johnson', '789 Oak St', 'Somewhere', '13579', 'alice.johnson@example.com', 1),
('Bob', 'Williams', '321 Pine St', 'Nowhere', '02468', 'bob.williams@example.com', 2);

-- Inserting test data into the model table
INSERT INTO model (manufacturer, transmission, model, fuel_type, engine_size, vehicle_category_id, vehicle_type_id) 
VALUES 
('Toyota', 'Automatic', 'Corolla', 'Petrol', 1.8, 1, 1),
('Ford', 'Automatic', 'Escape', 'Petrol', 2.5, 1, 1),
('Harley-Davidson', 'Manual', 'Sportster', 'Petrol', 1.2, 3, 2),
('Honda', 'Automatic', 'PCX', 'Petrol', 0.15, 2, 3),
('Toyota', 'Manual', 'Yaris', 'Petrol', 1.2, 1, 1),
('Ford', 'Automatic', 'Focus', 'Petrol', 1.6, 1, 1),
('Volkswagen', 'Manual', 'Golf', 'Diesel', 2.0, 2, 1),
('BMW', 'Automatic', '3 Series', 'Petrol', 2.0, 2, 1),
('Audi', 'Automatic', 'A4', 'Petrol', 1.8, 3, 1),
('Kawasaki', 'Manual', 'Ninja', 'Petrol', 1.0, 1, 2),
('Yamaha', 'Manual', 'MT-07', 'Petrol', 0.7, 2, 2),
('Suzuki', 'Manual', 'GSX-R', 'Petrol', 1.0, 3, 2),
('Piaggio', 'Automatic', 'Vespa', 'Petrol', 0.15, 2, 3),
('Aprilia', 'Automatic', 'SR50', 'Petrol', 0.05, 1, 3);

-- Inserting test data into the vehicle table
INSERT INTO vehicle (registration, model_id, mileage, availability, branch_id, daily_rate_id) 
VALUES 
('ABC123', 1, 50000, 1, 1, 1),
('DEF456', 2, 60000, 1, 2, 2),
('GHI789', 3, 70000, 1, 1, 3),
('JKL012', 4, 40000, 1, 1, 1),
('MNO345', 5, 30000, 1, 2, 1),
('PQR678', 6, 40000, 1, 1, 2),
('STU901', 7, 35000, 1, 2, 1),
('VWX234', 8, 20000, 1, 1, 1),
('YZA567', 9, 45000, 1, 2, 3),
('BCD890', 1, 28000, 1, 1, 2),
('EFG123', 9, 32000, 1, 2, 1),
('HIJ456', 2, 37000, 1, 1, 1),
('KLM789', 3, 26000, 1, 2, 2),
('NOP012', 4, 42000, 1, 1, 1),
('QRS345', 1, 39000, 1, 2, 3),
('TUV678', 6, 18000, 1, 1, 2),
('VWX901', 4, 47000, 1, 2, 1),
('YZA234', 7, 33000, 1, 1, 1),
('BCD567', 9, 36000, 1, 2, 2),
('EFG890', 2, 24000, 1, 1, 1),
('HIJ123', 2, 41000, 1, 2, 3),
('KLM456', 8, 29000, 1, 1, 2),
('NOP789', 6, 34000, 1, 2, 1),
('QRS012', 5, 38000, 1, 1, 1);


-- Inserting test data into the rental_log table
INSERT INTO rental_log (rental_id, log_comment, vehicle_mileage, log_time, employee_id) 
VALUES 
(1, 'Checked out by customer', 50000, NOW(), 1),
(2, 'Checked out by customer', 60000, NOW(), 2),
(3, 'Checked out by customer', 70000, NOW(), 1);


-- Call the stored procedure to create rental records
CALL create_rental_record_SP('ABC123', 1, '2024-05-01', '2024-05-10', 1, 1);
CALL create_rental_record_SP('DEF456', 2, '2024-05-05', '2024-05-15', 2, 2);
CALL create_rental_record_SP('JKL012', 4, '2024-05-15', '2024-05-20', 3, 4);
CALL create_rental_record_SP('MNO345', 5, '2024-05-20', '2024-05-25', 1, 5);
CALL create_rental_record_SP('PQR678', 6, '2024-05-22', '2024-05-30', 2, 6);
CALL create_rental_record_SP('STU901', 7, '2024-05-25', '2024-06-01', 3, 7);
CALL create_rental_record_SP('VWX234', 8, '2024-05-28', '2024-06-03', 1, 8);
CALL create_rental_record_SP('YZA567', 9, '2024-06-01', '2024-06-08', 2, 9);
CALL create_rental_record_SP('BCD890', 10, '2024-06-05', '2024-06-12', 3, 10);
CALL create_rental_record_SP('EFG123', 11, '2024-06-10', '2024-06-17', 1, 11);
CALL create_rental_record_SP('HIJ456', 12, '2024-06-15', '2024-06-22', 2, 12);
CALL create_rental_record_SP('GHI789', 3, '2024-05-12', '2024-05-18', 2, 3);
CALL create_rental_record_SP('DEF456', 2, '2024-05-05', '2024-05-15', 2, 2);
CALL create_rental_record_SP('DEF456', 2, '2023-06-05', '2023-06-15', 2, 2);


SELECT * FROM rental;
SELECT * FROM driver_rental;

-- Call the create payment log procedure with sample values
CALL create_payment_log_SP(1, 1); -- Assuming rental_id and customer_id are 1 for the example

-- Sample query to retrieve the payment details for verification
SELECT * FROM payment WHERE rental_id = 1; -- Assuming the rental_id is 1 for the example


