import os
import math
import tempfile
import numpy as np
import torch
import torch.nn as nn
import torch.nn.functional as F
import librosa
from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from fastapi.responses import JSONResponse
from contextlib import asynccontextmanager
from transformers import Wav2Vec2Model, Wav2Vec2Config, Wav2Vec2FeatureExtractor
from huggingface_hub import hf_hub_download

# ==========================================
# 1. Global Configurations
# ==========================================
DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")

MODEL_REPO_ID = "TD-jayadeera/model_255" 
MODEL_FILENAME = "SinhalaPhonoNet_Final_Checkpoint_v4.pth"

# 🌟 ගුරුවරයාගේ ශබ්ද ගොනු ඇති Local ෆෝල්ඩරයේ නම (HF Space එකට මෙය Upload කළ යුතුයි)
REFERENCE_AUDIO_DIR = "reference_audios"

# ==========================================
# 2. Model Architecture (255-Class)
# ==========================================
class SelfAttentionPooling(nn.Module):
    def __init__(self, input_dim):
        super().__init__()
        self.W = nn.Linear(input_dim, 128)
        self.V = nn.Linear(128, 1)

    def forward(self, x, attention_mask=None):
        scores = self.V(torch.tanh(self.W(x)))
        if attention_mask is not None:
            indices = torch.linspace(0, attention_mask.size(1)-1, steps=x.size(1)).long().to(x.device)
            mask = torch.index_select(attention_mask, 1, indices).unsqueeze(-1)
            scores = scores.masked_fill(mask == 0, -1e4)
        attn_weights = F.softmax(scores, dim=1)
        return torch.sum(x * attn_weights, dim=1), attn_weights

class SinhalaPhonoNet(nn.Module):
    def __init__(self, base_model="facebook/wav2vec2-xls-r-300m", embedding_dim=256, num_classes=255):
        super().__init__()
        self.config = Wav2Vec2Config.from_pretrained(base_model, output_hidden_states=True)
        self.backbone = Wav2Vec2Model.from_pretrained(base_model, config=self.config)
        self.layer_weights = nn.Parameter(torch.ones(self.config.num_hidden_layers + 1))
        self.attention = SelfAttentionPooling(self.config.hidden_size)
        self.fc = nn.Sequential(
            nn.Linear(self.config.hidden_size, 512),
            nn.BatchNorm1d(512),
            nn.ReLU(),
            nn.Dropout(0.3),
            nn.Linear(512, embedding_dim),
            nn.BatchNorm1d(embedding_dim)
        )
        self.classifier = nn.Linear(embedding_dim, num_classes)

    def forward(self, input_values, attention_mask=None):
        outputs = self.backbone(input_values=input_values, attention_mask=attention_mask)
        stacked_hidden_states = torch.stack(outputs.hidden_states, dim=0)
        weights = F.softmax(self.layer_weights, dim=0).view(-1, 1, 1, 1)
        weighted_hidden_state = torch.sum(stacked_hidden_states * weights, dim=0)
        pooled, _ = self.attention(weighted_hidden_state, attention_mask)
        embeddings = self.fc(pooled)
        norm_embeddings = F.normalize(embeddings, p=2, dim=1)
        logits = self.classifier(norm_embeddings)
        return embeddings, norm_embeddings, logits

# Global variables
model = None
processor = None

# ==========================================
# 3. Startup Event
# ==========================================
@asynccontextmanager
async def lifespan(app: FastAPI):
    global model, processor
    print("⏳ Loading processor...")

    hf_token = os.getenv("HF_TOKEN")
    
    processor = Wav2Vec2FeatureExtractor.from_pretrained("facebook/wav2vec2-xls-r-300m",token=hf_token,resume_download=True)
    
    print(f"⏳ Downloading & Loading custom model from HF ({MODEL_REPO_ID})...")
    model_path = hf_hub_download(repo_id=MODEL_REPO_ID, filename=MODEL_FILENAME)
    
    model = SinhalaPhonoNet(num_classes=255).to(DEVICE)
    checkpoint = torch.load(model_path, map_location=DEVICE, weights_only=False)
    model.load_state_dict(checkpoint['model_state_dict'])
    model.eval()
    print(f"✅ SinhalaPhonoNet API Ready! (Accuracy: {checkpoint.get('best_val_acc', 0)*100:.2f}%)")
    yield
    print("🛑 Shutting down API...")

app = FastAPI(lifespan=lifespan, title="Sinhala Mithuru HF Space API")

# ==========================================
# 4. Core Logic Functions
# ==========================================
def get_embedding(audio_path):
    speech, _ = librosa.load(audio_path, sr=16000)
    speech, _ = librosa.effects.trim(speech, top_db=25)
    inputs = processor(speech, sampling_rate=16000, return_tensors="pt", padding=True)
    with torch.no_grad():
        _, norm_emb, _ = model(inputs.input_values.to(DEVICE), inputs.attention_mask.to(DEVICE))
    return norm_emb.cpu().numpy()

# ==========================================
# 5. API Endpoints
# ==========================================
@app.get("/")
def read_root():
    return {"status": "Online", "message": "SinhalaPhonoNet HF Space API is Running 🚀"}

@app.post("/analyze")
async def analyze_pronunciation(
    target_audio_name: str = Form(...), 
    student_audio: UploadFile = File(...)
):
    student_temp_path = None
    try:
        with tempfile.NamedTemporaryFile(delete=False, suffix=".wav") as temp_student:
            student_content = await student_audio.read()
            temp_student.write(student_content)
            student_temp_path = temp_student.name

        teacher_audio_path = os.path.join(REFERENCE_AUDIO_DIR, target_audio_name)
        
        if not os.path.exists(teacher_audio_path):
            raise HTTPException(
                status_code=404, 
                detail=f"Target audio '{target_audio_name}' not found in '{REFERENCE_AUDIO_DIR}' folder."
            )

        emb_teacher = get_embedding(teacher_audio_path)
        emb_student = get_embedding(student_temp_path)
        raw_dist = float(np.linalg.norm(emb_teacher - emb_student))

        center_point = 0.31
        steepness = 40
        accuracy = (1 / (1 + math.exp(steepness * (raw_dist - center_point)))) * 100

        if accuracy >= 85:
            verdict = "EXCELLENT"
        elif accuracy >= 65:
            verdict = "GOOD"
        else:
            verdict = "INCORRECT"

        return JSONResponse(content={
            "target_word": target_audio_name,
            "accuracy": round(accuracy, 2),
            "raw_distance": round(raw_dist, 4),
            "verdict": verdict
        })

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    
    finally:
        if student_temp_path and os.path.exists(student_temp_path):
            os.remove(student_temp_path)

# ==========================================
# 🌟 6. Hugging Face Space Uvicorn Runner
# ==========================================
if __name__ == "__main__":
    import uvicorn
    # Hugging Face Spaces require mapping to port 7860
    uvicorn.run(app, host="0.0.0.0", port=7860)