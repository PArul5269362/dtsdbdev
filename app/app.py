"""
This is the main module for the WheelEase application. 
It contains the Flask app and the routes for the application.
"""
from config import Config
from flask import Flask, render_template, request, redirect, url_for, jsonify
from reports import reports_list as reports
import pymysql
import json
import dataclasses


app = Flask(__name__)
app.secret_key = Config.SECRET_KEY


connection = pymysql.connect(
    host=Config.DB_HOST,
    user=Config.DB_USER,
    password=Config.DB_PASSWORD,
    database=Config.DB_NAME
)

@dataclasses.dataclass
class Customer:
    customer_id: int
    first_name: str
    last_name: str
    address_line_1: str
    address_line_2: str
    city: str
    postcode: str
    phone_number: str
    email: str
    license_number: str 
    date_of_birth: str
    date_of_registration: str

    def __post_init__(self):
        if self.address_line_2 is None:
            self.address_line_2 = ""
        if self.license_number is None:
            self.license_number = ""



@dataclasses.dataclass
class VehicleDetailed:
    vehicle_category: str
    registration: str
    manufacturer: str
    model: str
    mileage: int
    availability: str
    branch: str
    daily_rate_category: float
    daily_rate_price: bool


@dataclasses.dataclass
class VehicleRaw:
    registration: str
    model_id: int
    mileage: int
    availability: str
    branch_id: int
    daily_rate_id: int


@app.context_processor
def inject_dict():
    """
    Injects a dictionary into all templates
    """
    return {'reports': reports}  # This makes 'my_dictionary' available in all templates


@app.route('/')
def home():
    """
    Home page route
    """
    return render_template('home.html')


@app.route('/vehicles')
def vehicles():
    """
    Display All Vehicles page route
    """
     # Get filter criteria from the search endpoint
    category = request.args.get('category')
    manufacturer = request.args.get('manufacturer')
    model = request.args.get('model')

    # build filter query    
    query = "SELECT * FROM vehicle_details_VIEW WHERE 1=1"
    params = []

    if category:
        query += " AND category=%s"
        params.append(category)
    if manufacturer:
        query += " AND manufacturer=%s"
        params.append(manufacturer)
    if model:
        query += " AND model=%s"
        params.append(model)
    
    # pagination
    
    page = request.args.get('page', 1, type=int)
    per_page = 10  
    offset = (page - 1) * per_page
    
    query = "SELECT * FROM vehicle_details_VIEW WHERE 1=1"
    params = []
    
    query += " LIMIT %s OFFSET %s"
    params.extend([per_page, offset])
    
    cursor = connection.cursor()
    cursor.execute(query, params)
    vehicles = []
    for vehicle_data in cursor.fetchall():
        vehicle = VehicleDetailed(
            vehicle_category=vehicle_data[0],
            registration=vehicle_data[1],
            manufacturer=vehicle_data[2],
            model=vehicle_data[3],
            mileage=vehicle_data[4],
            availability=vehicle_data[5],
            branch=vehicle_data[6],
            daily_rate_category=vehicle_data[7],
            daily_rate_price=vehicle_data[8]
        )
        vehicles.append(vehicle)
    
    count_query = "SELECT COUNT(*) FROM vehicle WHERE 1=1"
    
    cursor.execute(count_query)
    
    total_rows = cursor.fetchone()[0]
    total_pages = (total_rows + per_page - 1) // per_page
    cursor.close()
    
    return render_template('vehicle/list_vehicles.html', vehicles=vehicles, total_pages=total_pages, page=page)


@app.route('/vehicles/search', methods=['GET', 'POST'])
def search():
    """
    Search page route, allows users to enter parameters in a form to search for vehicles
    """
    if request.method == 'POST':
        # Retrieve form data
        category = request.form['category']
        manufacturer = request.form['manufacturer']
        model = request.form['model']
    
        # send the query to the vehicles page to display the results
        return redirect(url_for('vehicles', category=category, manufacturer=manufacturer, model=model))
    else:
        # Get all categories, manufacturers and models
        with connection.cursor() as cursor:
            cursor.execute("SELECT name FROM vehicle_category")
            categories = cursor.fetchall()
            cursor.execute("SELECT DISTINCT manufacturer FROM model")
            manufacturers = cursor.fetchall()
            cursor.execute("SELECT model FROM model")
            models = cursor.fetchall()
        
        return render_template('vehicle/search_vehicles.html', categories=categories, manufacturers=manufacturers, models=models)


@app.route('/vehicle/add', methods=['GET', 'POST'])
def add_vehicle():
    """
    Add Vehicle page route
    """
    if request.method == 'POST':
        # Retrieve form data
        registration = request.form['registration']
        model_id = request.form['model_id']
        mileage = request.form['mileage']
        branch_id = request.form['branch_id']
        daily_rate_id = request.form['daily_rate_id']
        
        # Insert the new vehicle into the database
        query = "INSERT INTO vehicle (registration, model_id, mileage, branch_id, daily_rate_id) VALUES (%s, %s, %s, %s, %s)"
        values = (registration, model_id, mileage, branch_id, daily_rate_id)
        
        try:
            cursor = connection.cursor()
            cursor.execute(query, values)
            connection.commit()
            cursor.close()
            return redirect(url_for('vehicles'))
        except Exception as err:
            # Handle any errors that occur during the database operation
            error_message = f"An error occurred: {err}"
            return render_template('error.html', error_message=error_message)
    else:
        return render_template('vehicle/add_vehicle.html')


@app.route('/vehicle/edit/<string:vehicle_id>', methods=['GET', 'POST'])
def edit_vehicle(vehicle_id):
    """
    Edit Vehicle page route
    """
    if request.method == 'POST':
        # Retrieve form data
        branch_id = request.form['branch_id']
        daily_rate_id = request.form['daily_rate_id']
        registration = vehicle_id
        
        # Update the vehicle in the database
        query = "UPDATE vehicle SET branch_id=%s, daily_rate_id=%s WHERE registration=%s"
        values = (branch_id, daily_rate_id, registration)
        try:
            cursor = connection.cursor()
            cursor.execute(query, values)
            connection.commit()
            cursor.close()
            return redirect(url_for('vehicles'))
        except Exception as err:
            # Handle any errors that occur during the database operation
            error_message = f"An error occurred: {err}"
            return render_template('errors/error.html', error_message=error_message)
    else:
        # Get the vehicle details from the database
        query = "SELECT * FROM vehicle WHERE registration=%s"
        values = (vehicle_id,)
        cursor = connection.cursor()
        cursor.execute(query, values)
        vehicle = cursor.fetchone()
        vehicle = VehicleRaw(
            registration=vehicle[0],
            model_id=vehicle[1],
            mileage=vehicle[2],
            availability=vehicle[3],
            branch_id=vehicle[4],
            daily_rate_id=vehicle[5]
        )
        cursor.close()
        return render_template('vehicle/edit_vehicle.html', vehicle=vehicle)

@app.route('/vehicle/delete/<string:vehicle_id>', methods=['POST'])
def delete_vehicle(vehicle_id):
    """
    Delete Vehicle page route
    """
    if request.method != 'POST':
        return redirect(url_for('vehicles'))
    else:
        query = "DELETE FROM vehicle WHERE registration=%s"
        values = (vehicle_id,)
        cursor = connection.cursor()
        cursor.execute(query, values)
        connection.commit()
        cursor.close()

    return redirect(url_for('vehicles'))


@app.route('/vehicle/<string:vehicle_id>')
def view_vehicle(vehicle_id):
    """
    View Vehicle page route
    """
    # Get the vehicle details from the database
    query = "SELECT * FROM vehicle_details_VIEW WHERE registration=%s"
    values = (vehicle_id)
    vehicle = None
    
    cursor = connection.cursor()
    cursor.execute(query, values)
    vehicle = cursor.fetchone()

    vehicle = VehicleDetailed(
            vehicle_category=vehicle[0],
            registration=vehicle[1],
            manufacturer=vehicle[2],
            model=vehicle[3],
            mileage=vehicle[4],
            availability=vehicle[5],
            branch=vehicle[6],
            daily_rate_category=vehicle[7],
            daily_rate_price=vehicle[8]
        )
    cursor.close()
    
    return render_template('vehicle/list_vehicle.html', vehicle=vehicle)


@app.route('/rentals')
def rentals():
    """
    Display All Rentals page route
    """
    with connection.cursor() as cursor:
        cursor.execute("SELECT * FROM rental")
        rentals = cursor.fetchall()

    return render_template('rental/list_rentals.html', rentals=rentals)

@app.route('/rentals/<string:customer_id>')
def list_customer_rentals(customer_id):
    """
    List Customer Rentals page route
    """
    query = "SELECT vehicle_id, rental_startdate, rental_enddate, insurance_id FROM rental WHERE customer_id=%s"
    values = (customer_id,)
    with connection.cursor() as cursor:
        cursor.execute(query, values)
        rentals = cursor.fetchall()

    return render_template('rental/list_customer_rentals.html', rentals=rentals)

@app.route('/rental/new', methods=['GET', 'POST'])
def rent_vehicle():
    """
    Rent Vehicle page route
    """
  
    if request.method == 'POST':
        # Retrieve form data
        registration = request.form['registration']
        customer_id = request.form['customer_id']
        start_date = request.form['start_date']
        end_date = request.form['end_date']
        insurance_id = request.form['insurance_id']
        driver_id = request.form['driver_id']

        # Insert the new rental into the database
        query = 'CALL create_rental_record_SP(%s, %s, %s, %s, %s, %s)'
        values = (registration, customer_id, start_date, end_date, insurance_id, driver_id)

        try:
            cursor = connection.cursor()
            cursor.execute(query, values)
            connection.commit()
            cursor.close()
            return redirect(url_for('rentals'))
        except Exception as err:
            # Handle any errors that occur during the database operation
            error_message = f"An error occurred: {err}"
            return render_template('errors/error.html', error_message=error_message)
    else:
        return render_template('rental/rent_vehicle.html')



# Customer
@app.route('/customers')
def customers():
    """
    Display All Customers page route
    """
    # pagination
    
    page = request.args.get('page', 1, type=int)
    per_page = 10  
    offset = (page - 1) * per_page
    
    query = "SELECT * FROM customer WHERE 1=1"
    params = []
    
    query += " LIMIT %s OFFSET %s"
    params.extend([per_page, offset])
    
    cursor = connection.cursor()
    cursor.execute(query, params)
    customers = []
    for customer_data in cursor.fetchall():
        customer = Customer(
            customer_id=customer_data[0],
            first_name=customer_data[1],
            last_name=customer_data[2],
            address_line_1=customer_data[3],
            address_line_2=customer_data[4],
            city=customer_data[5],
            postcode=customer_data[6],
            phone_number=customer_data[7],
            email=customer_data[8],
            license_number=customer_data[9],
            date_of_birth=customer_data[10],
            date_of_registration=customer_data[11]
        )
        customers.append(customer)
    
    count_query = "SELECT COUNT(*) FROM customer WHERE 1=1"
    
    cursor.execute(count_query)
    
    total_rows = cursor.fetchone()[0]
    total_pages = (total_rows + per_page - 1) // per_page
    cursor.close()
    
    return render_template('customer/list_customers.html', customers=customers, total_pages=total_pages, page=page)

    # build filter query    
    query = "SELECT * FROM customer"
    
    # pagination
    
    page = request.args.get('page', 1, type=int)
    per_page = 10  
    offset = (page - 1) * per_page
    
    query = "SELECT * FROM customer WHERE 1=1"
    params = []
    
    query += " LIMIT %s OFFSET %s"
    params.extend([per_page, offset])
    with connection.cursor() as cursor:
        cursor.execute("SELECT * FROM customer")
        customers = []
        for customer in cursor.fetchall():
            customers.append(Customer(
                customer_id=customer[0],
                first_name=customer[1],
                last_name=customer[2],
                address_line_1=customer[3],
                address_line_2=customer[4],
                city=customer[5],
                postcode=customer[6],
                phone_number=customer[7],
                email=customer[8],
                license_number=customer[9],
                date_of_birth=customer[10],
                date_of_registration=customer[11]
            ))

    return render_template('customer/list_customers.html', customers=customers)


# @app.route('/customer/list_rentals')
# def list_customer_rentals():
#     return None


@app.route('/customer/<int:customer_id>')
def view_customer(customer_id):
    """
    View Customer page route
    """
    query = "SELECT * FROM customer WHERE customer_id=%s"
    values = (customer_id,)

    cursor = connection.cursor()
    cursor.execute(query, values)
    customer = cursor.fetchone()
    customer = Customer(
        customer_id=customer[0],
        first_name=customer[1],
        last_name=customer[2],
        address_line_1=customer[3],
        address_line_2=customer[4],
        city=customer[5],
        postcode=customer[6],
        phone_number=customer[7],
        email=customer[8],
        license_number=customer[9],
        date_of_birth=customer[10],
        date_of_registration=customer[11]
    )
    cursor.close()
    return render_template('customer/view_customer.html', customer=customer)

@app.route('/customer/add', methods=['GET', 'POST'])
def add_customer():
    """
    Add Customer page route
    """
    if request.method == 'POST':
        # Retrieve form data
        first_name = request.form['first_name']
        last_name = request.form['last_name']
        address_line_one = request.form['address_line_one']
        address_line_two = request.form['address_line_two']
        city = request.form['city']
        postcode = request.form['postcode']
        phone_number = request.form['phone_number']
        email = request.form['email']
        license_number = request.form['license_number']
        date_of_birth = request.form['date_of_birth']
        
        # Insert the new customer into the database
        query = "INSERT INTO customer (first_name, last_name, address_line_one, address_line_two, city, postcode, phone_number, email, license_number, date_of_birth) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)"
        values = (first_name, last_name, address_line_one, address_line_two, city, postcode, phone_number, email, license_number, date_of_birth)

        try:
            cursor = connection.cursor()
            cursor.execute(query, values)
            connection.commit()
            cursor.close()
            return redirect(url_for('customers'))
        except Exception as err:
            # Handle any errors that occur during the database operation
            error_message = f"An error occurred: {err}"
            return render_template('errors/error.html', error_message=error_message)
    else:
        return render_template('customer/add_customer.html')
        
      
@app.route('/reports')
def list_reports():
    """
    List Reports page route
    """
    return render_template('report/list_reports.html', reports=reports)


@app.route('/report/<string:concise_name>')
def report(concise_name):
    """
    Report page route
    """

    match concise_name:
        case "available_vehicles":
            query = "SELECT * FROM available_vehicles_VIEW"
        case "rental_summary":
            query = "SELECT * FROM rental_summary_VIEW"
        case "utilisation_rate":
            query = "SELECT * FROM utilisation_rate_VIEW"
        case "loyalty_report":
            query = "SELECT * FROM loyalty_report_VIEW"
        case "rental_loc_performance":
            query = "SELECT * FROM rental_loc_performance_VIEW"
        case _:
            return render_template('errors/error.html', message="Report not found"), 404

    with connection.cursor() as cursor:
        cursor.execute(query)
        data = cursor.fetchall()
        return render_template('report/report.html', data=data)
# Services
@app.route('/api/models')
def get_models():
    """
    Returns a JSON string containing all car models
    """
    with connection.cursor() as cursor:
        cursor.execute("SELECT model FROM model")
        types = cursor.fetchall() 

    return jsonify(types)


@app.route('/api/categories')
def get_categories():
    """
    Returns a JSON string containing all car categories
    """
    with connection.cursor() as cursor:
        cursor.execute("SELECT name FROM vehicle_category")
        categories = cursor.fetchall()

    return jsonify(categories)  

@app.route('/api/manufacturers')
def get_manufacturers():
    """
    Returns a JSON string containing all car manufacturers
    """
    with connection.cursor() as cursor:
        cursor.execute("SELECT DISTINCT manufacturer FROM model")
        manufacturers = cursor.fetchall()
    return jsonify(manufacturers)  

# Error handlers

@app.errorhandler(400)
def bad_request(e):
    """
    400 error handler
    """
    return render_template('errors/400.html'), 400

@app.errorhandler(404)
def page_not_found(e):
    """
    404 error handler
    """
    return render_template('errors/404.html'), 404

@app.errorhandler(500)
def internal_server_error(e):
    """
    500 error handler
    """
    return render_template('errors/500.html'), 500


if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5050)
