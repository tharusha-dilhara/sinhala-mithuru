import modal
import os

# ==========================================
# 1. CONFIGURATION
# ==========================================
APP_NAME = "sinhala-instruct-smart" 
VOL_NAME = "sinhala-model-storage"

# 🟢 THE SAFE CHOICE: Official Llama-3 Instruct
BASE_MODEL = "unsloth/llama-3-8b-Instruct-bnb-4bit"

LOCAL_DATA_FILE = "../data/story_final.jsonl" 
REMOTE_DATA_PATH = "/data/story_grade_smart.jsonl"
REMOTE_OUTPUT_DIR = "/data/sinhala-instruct-final"

# ==========================================
# 2. ENVIRONMENT
# ==========================================
image = (
    modal.Image.debian_slim(python_version="3.11")
    .pip_install(
        "unsloth", 
        "torch", 
        "transformers", 
        "datasets", 
        "trl", 
        "bitsandbytes", 
        "accelerate"
    )
    .env({"HF_TOKEN": os.environ.get("HF_TOKEN", "")})
)

app = modal.App(APP_NAME)
volume = modal.Volume.from_name(VOL_NAME)
hf_secret = modal.Secret.from_name("huggingface-secret-2")

# ==========================================
# 3. HELPER: UPLOAD DATASET
# ==========================================
@app.function(image=image, volumes={"/data": volume}, timeout=600)
def upload_dataset(local_data: bytes):
    print(f"🚀 Uploading Dataset to {REMOTE_DATA_PATH}...")
    with open(REMOTE_DATA_PATH, "wb") as f:
        f.write(local_data)
    volume.commit()

# ==========================================
# 4. MAIN TRAINING FUNCTION
# ==========================================
@app.function(
    image=image,
    gpu="A100",           # A100 for best results
    timeout=86400,        
    volumes={"/data": volume},
    secrets=[hf_secret]
)
def train():
    from unsloth import FastLanguageModel
    from trl import SFTTrainer
    from transformers import TrainingArguments
    from datasets import load_dataset
    import torch

    print(f"🔥 Starting Training with OFFICIAL INSTRUCT MODEL: {BASE_MODEL}...")
    
    # A. LOAD MODEL
    model, tokenizer = FastLanguageModel.from_pretrained(
        model_name = BASE_MODEL,
        max_seq_length = 2048,
        dtype = None,
        load_in_4bit = True, 
    )

    # B. CONFIGURE LORA
    model = FastLanguageModel.get_peft_model(
        model,
        r = 16,
        target_modules = ["q_proj", "k_proj", "v_proj", "o_proj", "gate_proj", "up_proj", "down_proj"],
        lora_alpha = 16,
        lora_dropout = 0, 
        bias = "none",
        use_gradient_checkpointing = "unsloth",
        random_state = 3407,
    )

    # C. LOAD DATASET
    print(f"📚 Loading Dataset...")
    full_dataset = load_dataset("json", data_files=REMOTE_DATA_PATH, split="train")
    
    # 95/5 Split for Safety
    dataset_split = full_dataset.train_test_split(test_size=0.05)
    train_dataset = dataset_split["train"]
    eval_dataset = dataset_split["test"]
    
    print(f"✅ Training on {len(train_dataset)} stories.")

    # D. FORMATTING FUNCTION
    alpaca_prompt = """### Instruction:
{}

### Input:
{}

### Response:
{}"""
    EOS_TOKEN = tokenizer.eos_token 
    
    def formatting_prompts_func(examples):
        texts = []
        for instruction, input, output in zip(examples["instruction"], examples["input"], examples["output"]):
            texts.append(alpaca_prompt.format(instruction, input, output) + EOS_TOKEN)
        return {"text": texts}
    
    train_dataset = train_dataset.map(formatting_prompts_func, batched=True)
    eval_dataset = eval_dataset.map(formatting_prompts_func, batched=True)

    # E. TRAINER CONFIGURATION
    trainer = SFTTrainer(
        model = model,
        tokenizer = tokenizer,
        train_dataset = train_dataset,
        eval_dataset = eval_dataset,
        dataset_text_field = "text",
        max_seq_length = 2048,
        dataset_num_proc = 2,
        args = TrainingArguments(
            output_dir = "outputs",
            
            per_device_train_batch_size = 8,
            gradient_accumulation_steps = 4,
            
            # 🟢 2 Epochs is perfect for Instruct models
            num_train_epochs = 2, 
            learning_rate = 5e-5, 
            
            eval_strategy = "steps", 
            eval_steps = 20, 
            
            fp16 = not torch.cuda.is_bf16_supported(),
            bf16 = torch.cuda.is_bf16_supported(),
            logging_steps = 10,
            optim = "adamw_8bit",
            weight_decay = 0.01,
            lr_scheduler_type = "linear",
            seed = 3407,
        ),
    )

    print("🚀 Training Started...")
    trainer_stats = trainer.train()

    # F. SAVE
    print(f"💾 Saving Instruct Model to {REMOTE_OUTPUT_DIR}...")
    model.save_pretrained(REMOTE_OUTPUT_DIR)
    tokenizer.save_pretrained(REMOTE_OUTPUT_DIR)
    
    volume.commit()
    print("✅ SUCCESS! Instruct Model Saved.")

# ==========================================
# 5. LOCAL ENTRY POINT (THE "START BUTTON")
# ==========================================
@app.local_entrypoint()
def main():
    # Only upload if the file exists locally
    if os.path.exists(LOCAL_DATA_FILE):
        print(f"📖 Reading local file: {LOCAL_DATA_FILE}")
        with open(LOCAL_DATA_FILE, "rb") as f:
            upload_dataset.remote(f.read())
    else:
        print(f"⚠️ Warning: Local file {LOCAL_DATA_FILE} not found. Assuming data is already on server.")

    print("🚀 Triggering Instruct Training Job...")
    train.remote()