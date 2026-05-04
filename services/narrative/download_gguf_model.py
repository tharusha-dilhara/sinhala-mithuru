from huggingface_hub import hf_hub_download

repo_id = "IshiniTecla442/sinhala-mithuru-cpu-backup"
filename = "llama3-sinhala.Q4_K_M.gguf"

print(f"Downloading {filename} from {repo_id}...")
model_path = hf_hub_download(repo_id=repo_id, filename=filename)
print(f"\n✅ Download complete!")
print(f"Model saved to:\n  {model_path}")
