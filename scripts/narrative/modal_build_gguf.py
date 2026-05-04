import modal
import os

# ==========================================
# CONFIGURATION
# ==========================================
APP_NAME = "sinhala-gguf-converter"
VOL_NAME = "sinhala-model-storage"
ADAPTER_DIR = "/data/sinhala-multitask-model-v1" 
BASE_MODEL = "ihalage/llama3-sinhala"

# We will save the converted .gguf file back to your Modal volume
OUTPUT_DIR = "/data/multitask-v1-gguf"

image = (
    modal.Image.debian_slim(python_version="3.11")
    .apt_install("git", "cmake", "libcurl4-openssl-dev", "curl", "build-essential")
    .pip_install(
        "torch>=2.4.0",
        "transformers",
        "unsloth",
        "accelerate",
        "bitsandbytes",
        "peft"
    )
)

app = modal.App(APP_NAME)
volume = modal.Volume.from_name(VOL_NAME)
hf_secret = modal.Secret.from_name("huggingface-secret-2")

@app.function(
    image=image,
    gpu="A100", # We need a GPU to load the base model in 4-bit and apply the adapter
    volumes={"/data": volume},
    timeout=3600, # Allow up to 1 hour (conversion usually takes 5-10 mins)
    secrets=[hf_secret],
)
def build_gguf():
    from unsloth import FastLanguageModel
    from peft import PeftModel
    import os
    
    print(f"Loading Base: {BASE_MODEL}...")
    model, tokenizer = FastLanguageModel.from_pretrained(
        model_name=BASE_MODEL,
        max_seq_length=4096,
        dtype=None, 
        load_in_4bit=True, 
    )

    print(f"Applying Adapters from: {ADAPTER_DIR}...")
    # Apply your fine-tuned weights to the base model
    model = PeftModel.from_pretrained(model, ADAPTER_DIR)

    import builtins
    
    # Unsloth has an interactive prompt that crashes in headless Modal ("Press ENTER to install").
    # We patch the built-in input() function to automatically return an empty string (simulating ENTER).
    original_input = builtins.input
    builtins.input = lambda prompt="": ""
    
    try:
        print("Merging LoRA weights natively...")
        # Merge the weights into the base model explicitly
        merged_model = model.merge_and_unload()
        
        print(f"Saving fully merged HF weights to ({OUTPUT_DIR})...")
        import os
        os.makedirs(OUTPUT_DIR, exist_ok=True)
        merged_model.save_pretrained(OUTPUT_DIR)
        tokenizer.save_pretrained(OUTPUT_DIR)
        
        print("Cloning and building llama.cpp...")
        import subprocess
        subprocess.run(["git", "clone", "https://github.com/ggerganov/llama.cpp.git"], check=True)
        subprocess.run(["make", "-C", "llama.cpp", "-j4"], check=True)
        subprocess.run(["pip", "install", "-r", "llama.cpp/requirements.txt"], check=True)
        
        f16_gguf_path = os.path.join(OUTPUT_DIR, "llama3-sinhala.f16.gguf")
        q4_gguf_path = os.path.join(OUTPUT_DIR, "llama3-sinhala.Q4_K_M.gguf")
        
        print(f"Step 1: Converting HF to F16 GGUF...")
        subprocess.run([
            "python", "llama.cpp/convert_hf_to_gguf.py", 
            OUTPUT_DIR, 
            "--outfile", f16_gguf_path,
            "--outtype", "f16"
        ], check=True)

        print(f"Step 2: Quantizing F16 GGUF to Q4_K_M...")
        subprocess.run([
            "./llama.cpp/llama-quantize",
            f16_gguf_path,
            q4_gguf_path,
            "q4_k_m"
        ], check=True)
        
        print("Cleaning up intermediate F16 file to save volume space...")
        os.remove(f16_gguf_path)
        
    finally:
        builtins.input = original_input # Restore it just in case
        
    print(f"✅ Done! The GGUF file rests safely in your Modal volume at {q4_gguf_path}.")

@app.local_entrypoint()
def main():
    print("Starting Modal conversion job...")
    build_gguf.remote()
