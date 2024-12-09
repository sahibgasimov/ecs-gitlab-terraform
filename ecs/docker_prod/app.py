from flask import Flask, request, send_file, jsonify
from PIL import Image
import os

app = Flask(__name__)
UPLOAD_FOLDER = 'uploads'
OUTPUT_FOLDER = 'output'
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
os.makedirs(OUTPUT_FOLDER, exist_ok=True)

@app.route('/')
def home():
    return '''
    <!doctype html>
    <title>Image to PDF Converter</title>
    <h1>Upload an image to convert to PDF</h1>
    <form method="post" action="/convert" enctype="multipart/form-data">
        <input type="file" name="image" accept="image/*">
        <button type="submit">Convert to PDF</button>
    </form>
    '''

@app.route('/convert', methods=['POST'])
def convert_to_pdf():
    if 'image' not in request.files:
        return "No file uploaded", 400
    
    file = request.files['image']
    if file.filename == '':
        return "No selected file", 400

    try:
        # Save the uploaded file
        image_path = os.path.join(UPLOAD_FOLDER, file.filename)
        file.save(image_path)

        # Convert to PDF
        image = Image.open(image_path)
        if image.mode != 'RGB':
            image = image.convert('RGB')
        pdf_path = os.path.join(OUTPUT_FOLDER, f"{os.path.splitext(file.filename)[0]}.pdf")
        image.save(pdf_path, "PDF")

        # Send the PDF file as a response
        return send_file(pdf_path, as_attachment=True)
    except Exception as e:
        return f"An error occurred: {e}", 500

# Health check endpoint for ALB
@app.route('/api/health', methods=['GET'])
def health_check():
    return jsonify({"status": "healthy"}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080, debug=True)
