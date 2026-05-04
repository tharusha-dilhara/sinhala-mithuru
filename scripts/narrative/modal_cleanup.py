import modal

app = modal.App("cleanup-hf-volume")

# Mount your volume
volume = modal.Volume.from_name("sinhala-model-storage")

@app.function(
    image=modal.Image.debian_slim(),
    volumes={"/data": volume}, 
    timeout=600,
)
def clean_volume():
    import os
    import shutil

    # The absolute path to the mounted volume
    BASE_DIR = "/data"

    # === WHAT WE WANT TO KEEP ===
    # Add any folder or file names here that you DO NOT want to delete.
    KEEP_LIST = [
        "sinhala-multitask-model-v1", # Your newest adapter
        "multitask-v1-gguf",          # The GGUF export folder we just made
        "final_multitask_chat.jsonl", # Latest datasets
        "final_multitask_chat1.jsonl"
    ]

    print("Starting Volume Cleanup...")
    print(f"Keeping ONLY: {KEEP_LIST}\n")
    
    # Track how much space we free up
    freed_bytes = 0

    # Get everything in the volume
    for item_name in os.listdir(BASE_DIR):
        item_path = os.path.join(BASE_DIR, item_name)
        
        # If the item is NOT in our keep list, delete it
        if item_name not in KEEP_LIST:
            try:
                # Calculate size before deleting
                if os.path.isfile(item_path):
                    size = os.path.getsize(item_path)
                    os.remove(item_path)
                    print(f"Deleted File: {item_name} ({size / (1024*1024):.2f} MB)")
                    freed_bytes += size
                elif os.path.isdir(item_path):
                    # For directories, we estimate size or just delete
                    print(f"Deleting Directory: {item_name}/ ...")
                    shutil.rmtree(item_path)
                    print(f"   Done.")
            except Exception as e:
                print(f"Failed to delete {item_name}: {e}")
        else:
            print(f"Kept: {item_name}")

    print(f"\nCleanup Complete! Freeing up space on the volume.")


@app.local_entrypoint()
def main():
    # Prompt the user just in case they run this accidentally
    print("WARNING: Automatically deleting ALL models/datasets on your Modal Volume")
    print("EXCEPT for the newest multitask v1 adapters and GGUF exports.")
    clean_volume.remote()
