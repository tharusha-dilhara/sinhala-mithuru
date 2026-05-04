import modal

# ==========================================
# 1. CONFIGURATION
# ==========================================
APP_NAME = "sinhala-story-export" 
VOL_NAME = "sinhala-model-storage"
REMOTE_OUTPUT_DIR = "/data/sinhala-story-model-v2" 

# ==========================================
# 2. ENVIRONMENT SETUP
# ==========================================
image = (
    modal.Image.debian_slim(python_version="3.11")
    .apt_install("curl", "cmake", "git", "libcurl4-openssl-dev", "build-essential")
    .pip_install(
        "unsloth", 
        "torch", 
        "transformers", 
        "accelerate",
        "gguf",             # 🟢 Pre-installing
        "protobuf",         # 🟢 Pre-installing
        "sentencepiece",    # 🟢 Pre-installing
        "mistral_common"    # 🟢 Pre-installing
    )
    # 🟢 THE FIX: Force 'uv' to install directly to the cloud system
    .env({"UV_SYSTEM_PYTHON": "1"}) 
)

app = modal.App(APP_NAME)
volume = modal.Volume.from_name(VOL_NAME, create_if_missing=True)

# ==========================================
# 3. EXPORT FUNCTION
# ==========================================
@app.function(
    image=image,
    gpu="A10G",           
    timeout=86400,        
    volumes={"/data": volume}
)
def export_model():
    from unsloth import FastLanguageModel
    
    print(f"📥 Loading your successfully trained model from {REMOTE_OUTPUT_DIR}...")
    
    model, tokenizer = FastLanguageModel.from_pretrained(
        model_name = REMOTE_OUTPUT_DIR, 
        max_seq_length = 2048,
        dtype = None,
        load_in_4bit = True,
    )
    
    print("📦 Merging and Exporting 8-bit GGUF...")
    model.save_pretrained_gguf(f"{REMOTE_OUTPUT_DIR}_GGUF_8bit", tokenizer, quantization_method="q8_0")

    print("📦 Merging and Exporting 4-bit GGUF...")
    model.save_pretrained_gguf(f"{REMOTE_OUTPUT_DIR}_GGUF_4bit", tokenizer, quantization_method="q4_k_m")
    
    volume.commit()
    print("✅ Exporting Finished Successfully!")

# ==========================================
# 4. EXECUTION
# ==========================================
@app.local_entrypoint()
def main():
    export_model.remote()