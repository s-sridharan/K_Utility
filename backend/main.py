import os
from flask_cors import CORS
from flask import Flask, request, jsonify, send_from_directory
from textblob import TextBlob
import matplotlib
matplotlib.use('Agg')
import requests
from bs4 import BeautifulSoup
import matplotlib.pyplot as plt
import io
import base64
import threading
import webbrowser

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

@app.route('/')
def hello():
    return "Hello, World!"

@app.route('/analyze', methods=['POST'])
def analyze():
    data = request.json
    url = data['url']
    response = requests.get(url)
    soup = BeautifulSoup(response.content, 'html.parser')
    text = soup.get_text()

    blob = TextBlob(text)
    sentiment = blob.sentiment

    plt.figure(figsize=(6, 4))
    plt.bar(['Polarity', 'Subjectivity'], [sentiment.polarity, sentiment.subjectivity])
    plt.title('Sentiment Analysis')

    img = io.BytesIO()
    plt.savefig(img, format='png')
    img.seek(0)
    img_base64 = base64.b64encode(img.getvalue()).decode('utf-8')
    plt.close()

    result = {
        'polarity': blob.sentiment.polarity,
        'subjectivity': blob.sentiment.subjectivity,
        'imageUrl': f'data:image/png;base64,{img_base64}'
    }
    print(jsonify(result))
    return jsonify(result)

@app.route('/', defaults={'path': ''})
@app.route('/<path:path>')
def serve(path):
    if path != "" and os.path.exists(os.path.join(app.static_folder, path)):
        return send_from_directory(app.static_folder, path)
    else:
        return send_from_directory(app.static_folder, 'index.html')

def open_browser():
    webbrowser.open_new('http://127.0.0.1:5000/')

if __name__ == '__main__':
    threading.Timer(1.25, open_browser).start()
    app.run(port=5000, debug=False)
