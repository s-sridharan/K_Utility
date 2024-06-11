import sys
import os
import matplotlib

matplotlib.use('Agg')
from flask import Flask, request, jsonify, send_from_directory, Blueprint
from flask_cors import CORS
import threading
import webbrowser
from sentiment_analyzers import analyze_google_reviews, analyze_apple_reviews, analyze_twitter_hashtag

def resource_path(relative_path):
    """ Get the absolute path to the resource, works for dev and for PyInstaller """
    try:
        # PyInstaller creates a temp folder and stores path in _MEIPASS
        base_path = sys._MEIPASS
    except Exception:
        base_path = os.path.abspath(".")

    return os.path.join(base_path, relative_path)

web_build_folder = resource_path('web_build')
web_build_bp = Blueprint('web_build', __name__, static_folder=web_build_folder)

app = Flask(__name__, static_folder=web_build_folder)
CORS(app)  # Enable CORS for all routes

@app.route('/')
def index():
    print(f"Serving from: {app.static_folder}")
    return send_from_directory(app.static_folder, 'index.html')

@app.route('/<path:path>')
def static_proxy(path):
    print(f"Serving static file: {path}")
    return send_from_directory(app.static_folder, path)

@app.route('/sentimentAnalysis', methods=['GET', 'POST'])
def sentiment_analysis():
    if request.method == 'GET':
        # Return a list of available analyses
        return jsonify({
            "available_analyses": ["google", "apple", "twitter"]
        })

    elif request.method == 'POST':
        data = request.get_json()
        text = data.get('text', '')
        analysis_type = data.get('type', '')

        print(f'Received request for {analysis_type} with text: {text}')

        if analysis_type == 'google':
            return analyze_google_reviews.get_counts()
        elif analysis_type == 'apple':
            return analyze_apple_reviews.get_counts()
        elif analysis_type == 'twitter':
            return analyze_twitter_hashtag.get_counts()
        else:
            return jsonify({"error": "Invalid analysis type"}), 400

def open_browser():
    webbrowser.open_new('http://127.0.0.1:5000/')

@app.route('/shutdown', methods=['POST'])
def shutdown():
    shutdown_server = request.environ.get('werkzeug.server.shutdown')
    if shutdown_server:
        shutdown_server()
    return 'Server shutting down...'

if __name__ == '__main__':
    app.register_blueprint(web_build_bp, url_prefix='/')
    # Open the browser after a slight delay to ensure the server is running
    threading.Timer(1, open_browser).start()
    app.run(port=5000, debug=True)
