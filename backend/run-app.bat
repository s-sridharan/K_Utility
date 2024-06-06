@echo off
echo Setting up the virtual environment...
python -m venv venv
call venv\Scripts\activate

echo Installing required packages...
pip install -r requirements.txt

echo Starting the Flask app...
python main.py

pause
