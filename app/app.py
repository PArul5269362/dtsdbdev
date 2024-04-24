"""
This is the main module for the WheelEase application. 
It contains the Flask app and the routes for the application.
"""
from config import Config
from flask import Flask, render_template, request, redirect, url_for, jsonify
from reports import reports_list as reports
from dal.report_dao import ReportDAO
from dal.vehicle_dao import VehicleDAO
from dal.dictionary_dataaccess import DictionaryDataAccess

app = Flask(__name__)
app.secret_key = Config.SECRET_KEY

dao = VehicleDAO(DictionaryDataAccess.in_memory_database)

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
    return render_template('vehicles.html', vehicles=dao.get_all_vehicles())

@app.route('/add_vehicle', methods=['GET', 'POST'])
def add_vehicle():
    """
    Add Vehicle page route
    """
    if request.method == 'POST':
        dao.add_vehicle(**request.form)
        return redirect(url_for('vehicles'))
    return render_template('add_vehicle.html')

@app.route('/rent_vehicle', methods=['GET', 'POST'])
def rent_vehicle():
    """
    Rent Vehicle page route
    """
    if request.method == 'POST':

        return redirect(url_for('home'))

    return render_template('rent_vehicle.html')

@app.route('/delete_vehicle/<int:vehicle_id>', methods=['POST'])
def delete_vehicle(vehicle_id):
    """
    Delete Vehicle page route
    """
    dao.delete_vehicle(vehicle_id)
    return redirect(url_for('vehicles'))

@app.route('/report/<int:report_id>')
def report(report_id):
    """
    Report page route
    """
    title = reports[report_id]['full_name']
    description = reports[report_id]['description']
    details = reports[report_id]['details']
    column_titles, data_rows = ReportDAO().run_report(report_id)
    return render_template('report.html', 
                           title=title, 
                           description=description, 
                           details = details,
                           columns=column_titles, 
                           data=data_rows)

# Services
@app.route('/api/types')
def get_types():
    """
    Returns a JSON string containing all car types
    """
    types = DictionaryDataAccess.in_memory_database["car_types"]
    return jsonify(types)


@app.route('/api/categories')
def get_categories():
    """
    Returns a JSON string containing all car categories
    """
    categories = DictionaryDataAccess.in_memory_database["car_categories"]
    return jsonify(categories)  # Use jsonify to convert the dictionary to JSON format

@app.route('/api/manufacturers')
def get_manufacturers():
    """
    Returns a JSON string containing all car manufacturers
    """
    manufacturers = DictionaryDataAccess.in_memory_database["manufacturers"]
    return jsonify(manufacturers)  # Use jsonify to convert the dictionary to JSON format


if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5050)
