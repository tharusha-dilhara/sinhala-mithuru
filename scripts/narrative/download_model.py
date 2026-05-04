import modal
import os

# ==========================================
# CONFIGURATION
# ==========================================
APP_NAME = "downloader-tool"
VOL_NAME = "sinhala-model-storage"

# The Model in the Cloud (Source)
REMOTE_MODEL_PATH = "/data/sinhala-story-model-v2" 

# 🟢 UPDATE: Save to the 'models' folder (Up one level from 'training')
# This creates: backend/models/sinhala-story-model-v2
LOCAL_SAVE_PATH = "../models/sinhala-story-model-v2"         

image = modal.Image.debian_slim()
app = modal.App(APP_NAME)
volume = modal.Volume.from_name(VOL_NAME)

# 1. Helper to list files in the remote folder
@app.function(image=image, volumes={"/data": volume})
def list_remote_files(folder_path):
    import os
    try:
        files = []
        for root, dirs, filenames in os.walk(folder_path):
            for filename in filenames:
                full_path = os.path.join(root, filename)
                rel_path = os.path.relpath(full_path, folder_path)
                files.append((full_path, rel_path))
        return files
    except Exception as e:
        print(f"Error listing files: {e}")
        return []

# 2. Helper to read a specific file's bytes
@app.function(image=image, volumes={"/data": volume})
def get_file_content(remote_path):
    with open(remote_path, "rb") as f:
        return f.read()

@app.local_entrypoint()
def main():
    # Fix path relative to this script file
    base_dir = os.path.dirname(os.path.abspath(__file__))
    target_dir = os.path.normpath(os.path.join(base_dir, LOCAL_SAVE_PATH))

    print(f"🔍 Connecting to Volume: {VOL_NAME}...")
    print(f"📂 Target Local Folder: {target_dir}")
    
    # Step A: Get list of files
    files_to_download = list_remote_files.remote(REMOTE_MODEL_PATH)
    
    if not files_to_download:
        print(f"❌ Error: No files found at {REMOTE_MODEL_PATH}")
        return

    print(f"📦 Found {len(files_to_download)} files. Starting download...\n")

    # Step B: Download one by one
    for remote_full_path, relative_path in files_to_download:
        # Create full local path
        local_file_path = os.path.join(target_dir, relative_path)
        
        # Ensure directory exists
        os.makedirs(os.path.dirname(local_file_path), exist_ok=True)
        
        print(f"⬇️  Downloading: {relative_path}...")
        
        # Fetch bytes
        file_content = get_file_content.remote(remote_full_path)
        
        # Save to laptop
        with open(local_file_path, "wb") as f:
            f.write(file_content)

    print("\n" + "="*40)
    print("✅ DOWNLOAD COMPLETE!")
    print(f"📂 Your model is cleanly saved here:\n{target_dir}")
    print("="*40)