import os
import json
import numpy as np
import tensorflow as tf
import keras
import joblib
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from .utils import preprocess_data #

app = FastAPI(title="Sinhala Mithuru AI Engine")

# =============================================================================
# 🟢 SECTION 1: SYSTEM PATHS & ASSET LOADING
# =============================================================================

BASE_PATH = "/app"
CHAR_MODEL_PATH = os.path.join(BASE_PATH, "models/sinhala_mithuru_char_recognizer_v1.keras")
QUAL_MODEL_PATH = os.path.join(BASE_PATH, "models/quality_model_v1.keras")
CHAR_SCALER_PATH = os.path.join(BASE_PATH, "models/char_scaler_v1.pkl")
QUAL_SCALER_PATH = os.path.join(BASE_PATH, "models/scaler_v1.pkl")
CONFIG_PATH = os.path.join(BASE_PATH, "app/config.json")

# මොඩලය පුහුණු කළ අවස්ථාවේ තිබූ නිවැරදි අනුපිළිවෙල
DYNAMIC_CLASSES = [
    'A', 'AEe', 'Aa', 'Ae', 'E', 'Ee', 'G', 'Gi', 'Gii', 'Gu', 'Guu', 
    'H', 'I', 'Ii', 'K', 'Ka', 'Ke', 'Kee', 'Ki', 'Kii', 'Kii ', 'Ku', 
    'N', 'O', 'Oo', 'Ou', 'P', 'Pu', 'Puu', 'R', 'S', 'T', 'Th', 'U', 
    'Uu', 'Y', 'g', 'k'
]

# Assets පූරණය කිරීම
try:
    CHAR_MODEL = keras.models.load_model(CHAR_MODEL_PATH)
    QUAL_MODEL = keras.models.load_model(QUAL_MODEL_PATH)
    CHAR_SCALER = joblib.load(CHAR_SCALER_PATH)
    QUAL_SCALER = joblib.load(QUAL_SCALER_PATH)
    
    with open(CONFIG_PATH, 'r', encoding='utf-8') as f:
        CHAR_CONFIG = json.load(f)
    print("✅ All Research Assets Loaded Successfully with Keras 3!")
except Exception as e:
    print(f"❌ Critical Error Loading Assets: {e}")

# =============================================================================
# 🟢 SECTION 2: API ENDPOINTS
# =============================================================================

class LevelSubmission(BaseModel):
    expected_char: str
    strokes: list

@app.post("/evaluate")
async def evaluate_handwriting(submission: LevelSubmission):
    """
    පර්යේෂණාත්මක ඇගයීම් Endpoint එක: අකුර සහ ගුණාත්මකභාවය පිරික්සයි.
    """
    # 🧪 1. Preprocessing (Resampling to 150 points)
    processed, raw_strokes = preprocess_data(submission.strokes)
    
    if processed is None:
        raise HTTPException(status_code=400, detail="Invalid stroke data.")

    # 🧪 2. Character Recognition (Model A)
    # Z-score Scaling & Inference
    char_input = CHAR_SCALER.transform(processed.reshape(-1, 5)).reshape(1, 150, 5)
    char_pred = CHAR_MODEL.predict(char_input, verbose=0)
    
    # හඳුනාගත් අකුර (Predicted Class) ලබා ගැනීම
    char_idx = np.argmax(char_pred)
    predicted_label = DYNAMIC_CLASSES[char_idx]
    
    # හඳුනාගත් අකුරේ සිංහල සංකේතය Config එකෙන් ලබා ගැනීම
    identified_meta = CHAR_CONFIG.get(predicted_label, {"symbol": predicted_label})
    identified_symbol = identified_meta['symbol']

    # 🧪 3. Quality Assessment (Model B)
    qual_input = QUAL_SCALER.transform(processed.reshape(-1, 5)).reshape(1, 150, 5)
    qual_score = float(QUAL_MODEL.predict(qual_input, verbose=0)[0][0])
    
    # 🧪 4. Validation & Logic
    config_data = CHAR_CONFIG.get(submission.expected_char, {"symbol": "", "strokes": 1})
    actual_strokes = len(raw_strokes)

    # අකුරේ නිරවද්‍යතාවය පිරික්සීම
    is_correct_char = (predicted_label == submission.expected_char)
    is_quality_pass = (qual_score >= 0.5)

    return {
        "status": "success",
        "analysis": {
            "is_correct_letter": bool(is_correct_char),
            "identified_letter_label": predicted_label,    # හඳුනාගත් ලේබලය (උදා: 'Aa')
            "identified_letter_symbol": identified_symbol, # හඳුනාගත් සිංහල අකුර (උදා: 'ආ')
            "quality_percentage": round(qual_score * 100, 2),
            "is_quality_pass": bool(is_quality_pass),
            "strokes_actual": actual_strokes,
            "strokes_expected": config_data['strokes']
        }
    }