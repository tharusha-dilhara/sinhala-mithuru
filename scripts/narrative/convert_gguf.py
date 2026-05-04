from unsloth import FastLanguageModel

# 1. Provide the Base Model and your new Adapter Directory
BASE_MODEL = "ihalage/llama3-sinhala"
# Point this to the folder where your new `adapter_model.safetensors` is
ADAPTER_DIR = "./sinhala-model-storage/sinhala-multitask-model-v1" 

print("Loading model for conversion...")
model, tokenizer = FastLanguageModel.from_pretrained(
    model_name=BASE_MODEL,
    max_seq_length=4096,
    dtype=None, 
    load_in_4bit=True, # Needs to be true if you trained it in 4-bit
)

# 2. Apply your new adapter weights
from peft import PeftModel
model = PeftModel.from_pretrained(model, ADAPTER_DIR)

print("Converting to GGUF...")
# 3. Unsloth's magic command to convert and save to Q4_K_M (the best balance of speed/quality for CPUs)
model.save_pretrained_gguf(
    "new_model_export", 
    tokenizer,
    quantization_method = "q4_k_m"
)
print("Done! Look inside the 'new_model_export' folder for your new .gguf file.")
