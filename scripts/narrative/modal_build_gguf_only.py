import modal

app = modal.App("sinhala-gguf-final")
volume = modal.Volume.from_name("sinhala-model-storage")

image = (
    modal.Image.debian_slim(python_version="3.11")
    .apt_install("git", "cmake", "build-essential")
    .pip_install(
        "torch>=2.4.0",
        "transformers",
        "accelerate",
        "sentencepiece",
        "gguf>=0.10.0",
        "numpy",
    )
)

@app.function(
    image=image,
    volumes={"/data": volume},
    timeout=3600,
)
def convert_and_quantize():
    import os
    import glob
    import subprocess
    import urllib.request

    OUTPUT_DIR = "/data/multitask-v1-gguf"
    F16_GGUF   = os.path.join(OUTPUT_DIR, "llama3-sinhala.f16.gguf")
    Q4_GGUF    = os.path.join(OUTPUT_DIR, "llama3-sinhala.Q4_K_M.gguf")

    print("Files in model directory:")
    for f in sorted(glob.glob(OUTPUT_DIR + "/*")):
        size_mb = os.path.getsize(f) / (1024 * 1024)
        print(f"  {os.path.basename(f)}: {size_mb:.1f} MB")
        
    print("\nRemoving redundant adapter files from the directory so they don't confuse the converter...")
    adapter_weights = os.path.join(OUTPUT_DIR, "adapter_model.safetensors")
    adapter_config = os.path.join(OUTPUT_DIR, "adapter_config.json")
    if os.path.exists(adapter_weights):
        os.remove(adapter_weights)
    if os.path.exists(adapter_config):
        os.remove(adapter_config)
    
    # ─── Download convert_hf_to_gguf.py and its requirements ────────────────
    print("\nDownloading convert_hf_to_gguf.py from llama.cpp...")
    urllib.request.urlretrieve(
        "https://raw.githubusercontent.com/ggerganov/llama.cpp/master/convert_hf_to_gguf.py",
        "convert_hf_to_gguf.py",
    )
    # Also need gguf-py package that the script imports
    subprocess.run(["pip", "install", "gguf", "-q"], check=True)

    # ─── Step 1: Convert HF → F16 GGUF ─────────────────────────────────────
    print("\n=== Step 1/2: Converting HF model to F16 GGUF ===")
    proc = subprocess.run(
        ["python", "convert_hf_to_gguf.py",
         OUTPUT_DIR,
         "--outfile", F16_GGUF,
         "--outtype", "f16",
         "--verbose"]
    )
    if proc.returncode != 0:
        raise RuntimeError(f"convert_hf_to_gguf.py failed with code {proc.returncode}")

    f16_size_gb = os.path.getsize(F16_GGUF) / (1024 ** 3)
    print(f"F16 GGUF created! ({f16_size_gb:.2f} GB)")

    # ─── Step 2: Build llama-quantize (only this target) ────────────────────
    print("\n=== Building llama-quantize binary (Step 2 prep) ===")
    subprocess.run(
        ["git", "clone", "--depth=1",
         "https://github.com/ggerganov/llama.cpp.git", "llama_build"],
        check=True,
    )
    subprocess.run(
        ["cmake", "-B", "llama_build/build", "-S", "llama_build",
         "-DLLAMA_BUILD_TESTS=OFF",
         "-DLLAMA_BUILD_EXAMPLES=OFF",
         "-DBUILD_SHARED_LIBS=OFF",
         "-DGGML_NATIVE=OFF",
         "-DCMAKE_BUILD_TYPE=Release"],
        check=True,
    )
    subprocess.run(
        ["cmake", "--build", "llama_build/build",
         "--config", "Release",
         "--target", "llama-quantize",
         "-j4"],
        check=True,
    )

    # Binary location varies slightly by cmake version
    quantize_bin = "llama_build/build/bin/llama-quantize"
    if not os.path.exists(quantize_bin):
        quantize_bin = "llama_build/build/llama-quantize"
    print(f"Using quantize binary: {quantize_bin}")

    # ─── Step 2: Quantize F16 → Q4_K_M ──────────────────────────────────────
    print("\n=== Step 2/2: Quantizing F16 → Q4_K_M ===")
    proc2 = subprocess.run(
        [quantize_bin, F16_GGUF, Q4_GGUF, "q4_k_m"],
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
    )
    print(proc2.stdout)
    if proc2.returncode != 0:
        raise RuntimeError(f"llama-quantize failed with code {proc2.returncode}")

    print("\nRemoving intermediate F16 GGUF...")
    os.remove(F16_GGUF)

    q4_size = os.path.getsize(Q4_GGUF) / (1024 ** 3)
    print(f"\nSUCCESS! Q4_K_M GGUF at {Q4_GGUF} ({q4_size:.2f} GB)")
    print("Ready to upload to Hugging Face!")

@app.local_entrypoint()
def main():
    print("Starting final GGUF conversion...")
    convert_and_quantize.remote()
