import gradio as gr
import torch
import torch.nn as nn
import torch.nn.functional as F
import librosa
import numpy as np
import math
import os
from transformers import Wav2Vec2Model, Wav2Vec2Config, Wav2Vec2FeatureExtractor
from huggingface_hub import hf_hub_download

# ==========================================
# 1. මොඩලයේ නිවැරදි ව්‍යුහය (Architecture)
# ==========================================
class SelfAttentionPooling(nn.Module):
    def __init__(self, input_dim):
        super(SelfAttentionPooling, self).__init__()
        self.W = nn.Linear(input_dim, 128)
        self.V = nn.Linear(128, 1)

    def forward(self, x, attention_mask=None):
        scores = self.V(torch.tanh(self.W(x)))
        if attention_mask is not None:
            indices = torch.linspace(0, attention_mask.size(1) - 1, steps=x.size(1)).long().to(x.device)
            mask = torch.index_select(attention_mask, 1, indices).unsqueeze(-1)
            scores = scores.masked_fill(mask == 0, -1e4)
        attn_weights = F.softmax(scores, dim=1)
        return torch.sum(x * attn_weights, dim=1), attn_weights

class SinhalaPhonoNet(nn.Module):
    def __init__(self, base_model="facebook/wav2vec2-xls-r-300m", embedding_dim=256, num_classes=19):
        super(SinhalaPhonoNet, self).__init__()
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
        return F.normalize(embeddings, p=2, dim=1)

# ==========================================
# 2. මොඩලය පූරණය කිරීම
# ==========================================
DEVICE = torch.device("cpu")
PROCESSOR = Wav2Vec2FeatureExtractor.from_pretrained("facebook/wav2vec2-xls-r-300m")

# 🔴 ඔබේ Repo ID එක මෙහි නිවැරදිව ලබා දෙන්න
REPO_ID = "TD-jayadeera/SinhalaPhonoNet_TEC_v1_pp" 
MODEL_FILENAME= "SinhalaPhonoNet_TEC_v1_pp.pth"

try:
    model_path = hf_hub_download(repo_id=REPO_ID, filename=MODEL_FILENAME)
    model = SinhalaPhonoNet(num_classes=19).to(DEVICE)
    model.load_state_dict(torch.load(model_path, map_location=DEVICE))
    model.eval()
except Exception as e:
    print(f"Error: {e}")

# ==========================================
# 3. ප්‍රධාන Analysis Logic
# ==========================================
def analyze_pronunciation(teacher_audio, student_audio):
    if teacher_audio is None or student_audio is None:
        return "කරුණාකර ශබ්ද ගොනු දෙකම ලබා දෙන්න.", {}, ""

    try:
        def get_emb(path):
            speech, _ = librosa.load(path, sr=16000)
            speech, _ = librosa.effects.trim(speech, top_db=25)
            inputs = PROCESSOR(speech, sampling_rate=16000, return_tensors="pt", padding=True)
            with torch.no_grad():
                emb = model(inputs.input_values, inputs.attention_mask)
            return emb.cpu().numpy()

        emb_t = get_emb(teacher_audio)
        emb_s = get_emb(student_audio)
        raw_dist = float(np.linalg.norm(emb_t - emb_s))

        # Calibration (Distance to Accuracy mapping)
        center_point, steepness = 0.75, 12
        accuracy = (1 / (1 + math.exp(steepness * (raw_dist - center_point)))) * 100

        # Verdict තීරණය කිරීම
        if accuracy >= 85:
            verdict = "EXCELLENT"
            color = "green"
            msg = "ඉතාම නිවැරදියි! 🏆"
        elif accuracy >= 65:
            verdict = "GOOD"
            color = "orange"
            msg = "හොඳයි, තව උත්සාහ කරන්න! ⭐"
        else:
            verdict = "INCORRECT"
            color = "red"
            msg = "නැවත උත්සාහ කරන්න. ❌"

        results_labels = {
            "Excellent (ඉතා විශිෂ්ටයි)": 1.0 if verdict == "EXCELLENT" else 0.0,
            "Good (හොඳයි)": 1.0 if verdict == "GOOD" else 0.0,
            "Needs Work (නැවත උත්සාහ කරන්න)": 1.0 if verdict == "INCORRECT" else 0.0
        }

        info_html = f"""
        <div style='text-align: center; padding: 20px; border-radius: 10px; background-color: #f0f2f6;'>
            <h2 style='color: {color};'>{verdict}</h2>
            <h3 style='color: #333;'>{msg}</h3>
            <p style='font-size: 1.2em;'>නිරවද්‍යතාවය: <b>{accuracy:.2f}%</b></p>
            <p style='font-size: 0.9em; color: #666;'>Raw Distance: {raw_dist:.4f}</p>
        </div>
        """
        return info_html, results_labels

    except Exception as e:
        return f"<p style='color:red;'>Error: {str(e)}</p>", {}, ""

# ==========================================
# 4. නවීන Gradio UI (Blocks)
# ==========================================
with gr.Blocks(theme='shivi/calm_sea_ocean') as demo:
    gr.Markdown("# 🎙️ සිංහල මිතුරු (Sinhala Mithuru) - Pronunciation Lab")
    gr.Markdown("පහත ඕඩියෝ ගොනු දෙක ලබා දී ඔබේ උච්චාරණයේ නිරවද්‍යතාවය පරීක්ෂා කරගන්න.")
    
    with gr.Row():
        with gr.Column():
            t_input = gr.Audio(type="filepath", label="ගුරුවරයාගේ ශබ්දය (Teacher)")
            s_input = gr.Audio(type="filepath", label="ඔබේ ශබ්දය (Student)")
            btn = gr.Button("පරීක්ෂා කරන්න (Analyze)", variant="primary")
            
        with gr.Column():
            result_html = gr.HTML(label="Result Status")
            label_output = gr.Label(num_top_classes=1, label="Verdict Visualization")

    btn.click(fn=analyze_pronunciation, inputs=[t_input, s_input], outputs=[result_html, label_output])

    gr.Examples(
        examples=[], # ඔබට උදාහරණ ගොනු ඇත්නම් මෙහි එක් කරන්න
        inputs=[t_input, s_input]
    )

demo.launch()