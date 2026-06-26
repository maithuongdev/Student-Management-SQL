import pyodbc
import hashlib
import base64
import json
import os
from Crypto.PublicKey import RSA
from Crypto.Cipher import PKCS1_OAEP
import sys

sys.stdout.reconfigure(encoding="utf-8")

# SQL Server connection
conn = pyodbc.connect(
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=Thuong\\MSSQLSERVER3;"
    "DATABASE=QLSVNhom;"
    "Trusted_Connection=yes;"
)
cursor = conn.cursor()

# User login credentials
username = "CCC"
password = "asd"

# JSON file for storing multiple RSA key pairs
KEYS_FILE = "rsa_keys.json"
KEY_CACHE = {}


def load_keys():
    """Load all RSA key pairs from the JSON file into memory."""
    if os.path.exists(KEYS_FILE):
        try:
            with open(KEYS_FILE, "r") as f:
                KEY_CACHE.update(json.load(f))
        except json.JSONDecodeError:
            print("Error: The key file is corrupted. Resetting...")
            with open(KEYS_FILE, "w") as f:
                json.dump({}, f)  # Reset the key file


def load_private_key(username: str):
    """Load the private RSA key for the specified user."""
    load_keys()

    if username in KEY_CACHE:
        return base64.b64decode(KEY_CACHE[username]["private_key"])

    print("Private key not found for the specified user.")
    return None


def decrypt_salary(encrypted_salary: bytes, private_key_pem: bytes, password: str):
    """Decrypt the employee salary using the RSA private key."""
    try:
        private_key = RSA.import_key(private_key_pem, passphrase=password)
        cipher = PKCS1_OAEP.new(private_key)
        decrypted_salary = cipher.decrypt(encrypted_salary).decode()
        return decrypted_salary

    except ValueError:
        return "Decryption failed: Incorrect password or invalid private key."

    except Exception as e:
        return f"Unexpected error: {e}"


# Hash the password using SHA-1
hashed_password = hashlib.sha1(password.encode()).digest()

# Execute the stored procedure to retrieve employee information
try:
    cursor.execute(
        "EXEC SP_SEL_PUBLIC_ENCRYPT_NHANVIEN ?, ?",
        (username, hashed_password)
    )
    rows = cursor.fetchall()

except Exception as e:
    print(f"Database query failed: {e}")
    conn.close()
    exit()

# Validate the query result
if not rows or rows[0][0] == -1:
    print("Invalid username or password.")
    conn.close()
    exit()

# Load the user's private RSA key
private_key_pem = load_private_key(username)

if not private_key_pem:
    conn.close()
    exit()

# Process employee information
for row in rows:
    manv, hoten, email, encrypted_salary = row

    # Convert memoryview to bytes if necessary
    if isinstance(encrypted_salary, memoryview):
        encrypted_salary = encrypted_salary.tobytes()

    # Decrypt the salary
    decrypted_salary = decrypt_salary(
        encrypted_salary,
        private_key_pem,
        password
    )

    print(
        f"Employee ID: {manv}, "
        f"Full Name: {hoten}, "
        f"Email: {email}, "
        f"Salary: {decrypted_salary}"
    )

# Close the database connection
conn.close()