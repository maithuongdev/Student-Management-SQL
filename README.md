# Student Management System (with RSA Encryption)

A GUI-based application for managing employees, classes, and students. This project emphasizes data security by utilizing asymmetric RSA encryption for sensitive data (e.g., salaries, exam scores) and SHA-1 hashing for login passwords.

## Key Features
* **Secure Initialization:** Automatically generates RSA key pairs (Public/Private Keys) for each employee during data initialization.
* **GUI Management:** Provides a graphical interface for instructors/employees to log in, add, edit, and delete class and student information.
* **Score & Salary Protection:** Sensitive data is stored in the SQL Server database as encrypted strings. Only valid sessions (authenticated with the correct password and holding the Private Key) can decrypt and view the actual scores or salaries.

## Prerequisites
1. Python 3.8 or higher.
2. [ODBC Driver 17 for SQL Server](https://learn.microsoft.com/en-us/sql/connect/odbc/download-odbc-driver-for-sql-server) installed.
3. SQL Server (Local or Remote) with the database initialized from the provided SQL scripts.

## Installation Guide
**Step 1:** Install the required Python dependencies:
\`\`\`bash
pip install -r requirements.txt
\`\`\`

**Step 2:** Database Setup
* Open SQL Server Management Studio (SSMS).
* Execute the SQL scripts located in the `database/` folder in order to create the tables and Stored Procedures.
* Open the Python files (e.g., `src/UI.py`) and update the `SERVER=...` connection string in the `connect_db()` function to match your local or remote SQL Server instance name.

## Usage
1. Run the initialization script (e.g., `src/InitEmployee.py` or `src/AddNV.py`) to insert the first employee into the database and generate the `*.pem` key files.
2. Launch the main application:
\`\`\`bash
python src/UI.py
\`\`\`
3. Log in using the credentials you just created and start managing your classes and students.

## ⚠️ Security Note
**Never** commit your key files (`private.pem`, `public.pem`, or `rsa_keys.json`) to public version control repositories like GitHub. Your system's entire security layer will be compromised if the Private Key is exposed. Ensure these files are added to your `.gitignore`.