"""
Config.py contains configuration classes 
for different environments (development, testing, production).
"""
import os
from dotenv import load_dotenv

load_dotenv() # take environment variables from .env file 

class ConfigBase:
    """
    Base configuration class. Contains configuration options that are common to all environments
    """
    SECRET_KEY = os.getenv('SECRET_KEY', os.urandom(16))
    DEBUG = False
    TESTING = False
    DB_HOST = os.getenv('DB_HOST')
    DB_USER = os.getenv('DB_USER')
    DB_PASSWORD = os.getenv('DB_PASSWORD')
    DB_NAME = os.getenv('DB_NAME')

    # Add more configuration options here like database connection strings etc.
    # Ideally, you would store these in environment variables and load them here
    # For example, to load a database connection string from an environment variable:
    # DATABASE_URI = os.getenv('DATABASE_URI')
    # We are using dotenv to load environment variables from a .env file
    # The .env file wont be deployed to github or production, it's only for local development
    # If you use environment variables to load configuration, you can avoid storing sensitive information in your codebase

class ConfigTest(ConfigBase):
    """
    Configuration class for testing environment
    """
    TESTING = True

class ConfigDev(ConfigBase):
    """
    Configuration class for development environment
    """
    DEBUG  = True

class ConfigProd(ConfigBase):
    """
    Configuration class for production environment
    """
    pass

# This dictionary maps the FLASK_ENV environment variable to the correct configuration class
config = {
    'test': ConfigTest,
    'development': ConfigDev,
    'production': ConfigProd
}

Config = config[os.getenv('FLASK_ENV', 'dev')]
