"""
Example of how to generate a secret key and save it to a file.
"""
import os
from cryptography.fernet import Fernet
# Generate a new key
key = Fernet.generate_key()

# Save the key to a file
with open('key.txt', 'wb') as key_file:
    key_file.write(key)

# Load the key from the file
with open('key.txt', 'rb') as key_file:
    loaded_key = key_file.read()

# Print the loaded key
print(loaded_key.hex())
