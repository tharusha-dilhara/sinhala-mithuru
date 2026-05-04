import modal
import os
import glob

# ==========================================
# 1. CONFIGURATION
# ==========================================
APP_NAME = "sinhala-gguf-tester" 
VOL_NAME = "sinhala-model-storage"

# 🟢 CHANGE THIS LINE to test different versions:
# Use "/data/sinhala-story-model-v2_GGUF_8bit" for the 8-bit version
# Use "/data/sinhala-story-model-v2_GGUF_4bit" for the 4-bit version
GGUF_DIR = "/data/sinhala-story-model-v2_GGUF_4bit" 

# ==========================================
# 2. ENVIRONMENT SETUP
# ==========================================
image = (
    modal.Image.debian_slim(python_version="3.11")
    .pip_install("llama-cpp-python") # The industry standard for GGUF
)

app = modal.App(APP_NAME)
volume = modal.Volume.from_name(VOL_NAME)

# ==========================================
# 3. INFERENCE FUNCTION
# ==========================================
@app.function(
    image=image,
    timeout=600,        
    volumes={"/data": volume}
)
def test_gguf(level: str, theme: str, context: str):
    from llama_cpp import Llama
    
    print("🔍 Scanning the entire cloud volume for 4-bit GGUF files...")
    
    # 🟢 THE FIX: Recursively search ALL folders for the Q4_K_M file
    gguf_files = glob.glob("/data/**/*Q4_K_M*.gguf", recursive=True) + glob.glob("/data/**/*q4_k_m*.gguf", recursive=True)
    
    if not gguf_files:
        print("❌ Error: Still could not find the 4-bit .gguf file anywhere on the drive.")
        print("Run this in your terminal to see what is inside: modal volume ls sinhala-model-storage")
        return
        
    model_path = gguf_files[0]
    print(f"✅ Found it! 🚀 Loading {os.path.basename(model_path)} into CPU memory...")
    
    # 1. Load the model using CPU
    llm = Llama(
        model_path=model_path,
        n_ctx=2048,
        chat_format="llama-3", 
        verbose=False 
    )

    # 2. Apply our bulletproof English logic
    system_prompt = "You are a primary school teacher in Sri Lanka. Follow the instructions strictly. Output Sinhala text only."
    
    if level == "උසස්":
        task_instruction = "Write a meaningful Sinhala story for Grade 3, 4, and 5 children to read, using simple words and formal written Sinhala grammar. Do not include any dialogues, direct speech, or sound effects. The story must consist of exactly 7 or 8 sentences."
    else:
        task_instruction = "Write a highly entertaining and simple Sinhala story for Grade 1 and 2 children to listen to, using spoken Sinhala grammar. You may include simple dialogues and sound effects. The story must consist of exactly 5 or 6 sentences."

    user_content = f"{task_instruction}\n\nමට්ටම: {level} | තේමාව: {theme} | සන්දර්භය: {context}"

    messages = [
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": user_content}
    ]

    print(f"✍️ Generating a '{level}' story about '{context}'...")
    print("⏳ Running on CPU. It will take a few seconds to process...")

    # 3. Generate the text
    response = llm.create_chat_completion(
        messages=messages,
        max_tokens=512,
        temperature=0.7,
        stop=["<|eot_id|>"] 
    )
    
    generated_text = response["choices"][0]["message"]["content"].strip()
    
    print("\n" + "="*50)
    print(f"🎓 SINHALA MITHURU - 4-BIT GGUF STORY ({level})")
    print("="*50)
    print(generated_text)
    print("="*50 + "\n")
    
# ==========================================
# 4. EXECUTION
# ==========================================
@app.local_entrypoint()
def main():
    test_gguf.remote(
        level="උසස්", 
        theme="වීර ක්‍රියා", 
        context="ගංවතුරෙන් බල්ලෙකු බේරා ගැනීම"
    )