import modal

app = modal.App("upload-merged-model-hf")

image = modal.Image.debian_slim().pip_install("huggingface_hub")
volume = modal.Volume.from_name("sinhala-model-storage")

@app.function(
    image=image,
    volumes={"/data": volume}, 
    timeout=3600,
    secrets=[modal.Secret.from_name("huggingface-secret-2")] 
)
def upload_merged_files():
    from huggingface_hub import HfApi
    import os

    # The repo from your screenshot!
    REPO_ID = "IshiniTecla442/ishiniTecla_sinhala-multitask-model-v1" 
    
    # The folder we built earlier
    FOLDER_PATH = "/data/multitask-v1-gguf" 

    api = HfApi(token=os.environ["HF_TOKEN"])

    # Double check it exists
    api.create_repo(
        repo_id=REPO_ID,
        repo_type="model",
        exist_ok=True
    )

    print(f"Uploading entire merged model folder to {REPO_ID}...")
    print("This will upload the 5GB model.safetensors file, so it might take 5-10 minutes.")
    
    try:
        api.upload_folder(
            folder_path=FOLDER_PATH,
            repo_id=REPO_ID,
            repo_type="model",
        )
        print("✅ Upload absolutely complete! Check your Hugging Face page now!")
    except Exception as e:
        print(f"Failed to upload. Error: {e}")

@app.local_entrypoint()
def main():
    upload_merged_files.remote()
