from flask import Flask, jsonify

app = Flask(__name__)

# Health check endpoint
@app.route('/api/health', methods=['GET'])
def health_check():
    return jsonify(status="UP", message="Service is healthy"), 200

# Sample application endpoint
@app.route('/', methods=['GET'])
def home():
    return "Hello from the Python PROD app v1!"

if __name__ == '__main__':
    import os
    port = int(os.getenv("PORT", 8080))
    app.run(host='0.0.0.0', port=port)

