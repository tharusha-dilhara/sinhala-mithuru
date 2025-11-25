import os
import sys
import json
import base64
import time
import cv2
import numpy as np
import subprocess # Folder open කිරීමට
import platform   # OS එක හඳුනා ගැනීමට
from flask import Flask, render_template, request, jsonify, send_from_directory
from flask_cors import CORS

def get_base_path():
    if getattr(sys, 'frozen', False):
        return os.path.dirname(sys.executable)
    return os.path.dirname(os.path.abspath(__file__))

if getattr(sys, 'frozen', False):
    template_dir = os.path.join(sys._MEIPASS, 'templates')
else:
    template_dir = 'templates'

app = Flask(__name__, template_folder=template_dir)
CORS(app)

BASE_DIR = get_base_path()
DATA_DIR = os.path.join(BASE_DIR, "dataset")
IMAGES_DIR = os.path.join(DATA_DIR, "images")
JSON_DIR = os.path.join(DATA_DIR, "json")
CNN_DIR = os.path.join(DATA_DIR, "cnn_64")
LOG_FILE = os.path.join(DATA_DIR, "debug_log.txt") 

for folder in [IMAGES_DIR, JSON_DIR, CNN_DIR]:
    if not os.path.exists(folder):
        os.makedirs(folder)

def log_error(message):
    try:
        with open(LOG_FILE, "a", encoding="utf-8") as f:
            f.write(f"{time.ctime()}: {message}\n")
    except: pass

# --- Helper Functions (cv2_imread, cv2_imwrite, process_image_for_cnn) ---
# (මේවා කලින් කේතයේ තිබූ පරිදිම තබන්න, නැතහොත් සම්පූර්ණ කේතයම පහතින් ගන්න)
def cv2_imread(file_path, flags=cv2.IMREAD_GRAYSCALE):
    try:
        with open(file_path, "rb") as f:
            bytes_data = bytearray(f.read())
            numpy_array = np.asarray(bytes_data, dtype=np.uint8)
            return cv2.imdecode(numpy_array, flags)
    except Exception as e:
        log_error(f"Read Error: {e}")
        return None

def cv2_imwrite(file_path, img):
    try:
        is_success, im_buf_arr = cv2.imencode(".png", img)
        if is_success:
            with open(file_path, "wb") as f:
                im_buf_arr.tofile(f)
            return True
        return False
    except Exception as e:
        log_error(f"Write Error: {e}")
        return False

def process_image_for_cnn(image_path, output_path, target_size=64):
    try:
        img = cv2_imread(image_path)
        if img is None: return False
        _, img = cv2.threshold(img, 128, 255, cv2.THRESH_BINARY)
        coords = cv2.findNonZero(img)
        if coords is None: return False
        x, y, w, h = cv2.boundingRect(coords)
        crop = img[y:y+h, x:x+w]
        max_dim = max(w, h)
        pad_size = int(max_dim * 0.2)
        new_size = max_dim + (pad_size * 2)
        square_img = np.zeros((new_size, new_size), dtype=np.uint8)
        start_x = (new_size - w) // 2
        start_y = (new_size - h) // 2
        square_img[start_y:start_y+h, start_x:start_x+w] = crop
        final_img = cv2.resize(square_img, (target_size, target_size), interpolation=cv2.INTER_AREA)
        return cv2_imwrite(output_path, final_img)
    except Exception as e:
        log_error(f"Processing Exception: {e}")
        return False

# --- Routes ---

@app.route('/')
def home():
    return render_template('index.html')

@app.route('/dashboard')
def dashboard():
    return render_template('dashboard.html')

@app.route('/images/<filename>')
def serve_image(filename):
    return send_from_directory(IMAGES_DIR, filename)

@app.route('/cnn_images/<filename>')
def serve_cnn_image(filename):
    return send_from_directory(CNN_DIR, filename)

@app.route('/api/get_count')
def get_count():
    try:
        if not os.path.exists(JSON_DIR): return jsonify({"count": 0})
        file_count = len([name for name in os.listdir(JSON_DIR) if name.endswith('.json')])
        return jsonify({"count": file_count})
    except: return jsonify({"count": 0})

@app.route('/api/get_all_data')
def get_all_data():
    files = []
    try:
        if os.path.exists(JSON_DIR):
            json_files = sorted(os.listdir(JSON_DIR), reverse=True)
            for j_file in json_files:
                if j_file.endswith('.json'):
                    try:
                        with open(os.path.join(JSON_DIR, j_file), 'r', encoding='utf-8') as f:
                            content = json.load(f)
                        
                        is_processed = os.path.exists(os.path.join(CNN_DIR, content.get("filename")))
                        strokes = content.get("strokes", [])
                        stroke_count = content.get("stroke_count")
                        if stroke_count is None: stroke_count = len(strokes) if isinstance(strokes, list) else 0

                        files.append({
                            "filename": content.get("filename"),
                            "label": content.get("label"),
                            "stroke_count": stroke_count,
                            "full_json": content,
                            "cnn_ready": is_processed
                        })
                    except: pass
    except Exception as e:
        log_error(f"Data Load Error: {e}")
    return jsonify(files)

@app.route('/save_data', methods=['POST'])
def save_data():
    try:
        data = request.json
        label = data.get('label', 'unknown')
        image_data = data.get('image')
        strokes = data.get('strokes', [])
        
        if not image_data: return jsonify({"status": "error"}), 400

        timestamp = int(time.time() * 1000)
        filename_base = f"{label}_{timestamp}"
        
        encoded = image_data.split(",", 1)[1] if "," in image_data else image_data
        image_bytes = base64.b64decode(encoded)
        img_filename = f"{filename_base}.png"
        raw_img_path = os.path.join(IMAGES_DIR, img_filename)
        
        with open(raw_img_path, "wb") as f:
            f.write(image_bytes)

        cnn_path = os.path.join(CNN_DIR, img_filename)
        success = process_image_for_cnn(raw_img_path, cnn_path)
        
        json_content = {
            "filename": img_filename,
            "label": label,
            "processed": True if success else False,
            "stroke_count": len(strokes), 
            "strokes": strokes             
        }

        json_filename = f"{filename_base}.json"
        json_path = os.path.join(JSON_DIR, json_filename)
        
        with open(json_path, "w", encoding='utf-8') as f:
            json.dump(json_content, f, indent=4, ensure_ascii=False)

        return jsonify({"status": "success", "file": img_filename})
    except Exception as e:
        log_error(f"Save Route Error: {e}")
        return jsonify({"status": "error", "message": str(e)}), 500

# --- NEW: Delete Item Route ---
@app.route('/api/delete_item', methods=['POST'])
def delete_item():
    try:
        data = request.json
        filename = data.get('filename')
        
        if not filename: return jsonify({"status": "error"}), 400

        # Delete Raw Image
        raw_path = os.path.join(IMAGES_DIR, filename)
        if os.path.exists(raw_path): os.remove(raw_path)

        # Delete CNN Image
        cnn_path = os.path.join(CNN_DIR, filename)
        if os.path.exists(cnn_path): os.remove(cnn_path)

        # Delete JSON
        json_name = filename.replace('.png', '.json')
        json_path = os.path.join(JSON_DIR, json_name)
        if os.path.exists(json_path): os.remove(json_path)

        return jsonify({"status": "success"})
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

# --- NEW: Open Folder Route ---
@app.route('/api/open_folder')
def open_folder():
    try:
        path = DATA_DIR
        if platform.system() == "Windows":
            os.startfile(path)
        elif platform.system() == "Darwin":
            subprocess.Popen(["open", path])
        else:
            subprocess.Popen(["xdg-open", path])
        return jsonify({"status": "success"})
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)})

if __name__ == '__main__':
    app.run(port=5000)