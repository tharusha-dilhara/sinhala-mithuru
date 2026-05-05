import modal
import os

# ==========================================
# 1. CONFIGURATION
# ==========================================
APP_NAME = "sinhala-ihalage-5-epochs" 
VOL_NAME = "sinhala-model-storage"
BASE_MODEL = "ihalage/llama3-sinhala"

# Pointing to your NEW COMBINED AND SHUFFLED dataset
LOCAL_DATA_FILE = "../data/final_multitask_chat1.jsonl" 
REMOTE_DATA_PATH = "/data/final_multitask_chat1.jsonl"

# Where the final 5-epoch model will be saved
REMOTE_OUTPUT_DIR = "/data/outputs_ihalage_5_epochs_lora"

# ==========================================
# 2. ENVIRONMENT SETUP
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
volume = modal.Volume.from_name(VOL_NAME, create_if_missing=True)
hf_secret = modal.Secret.from_name("huggingface-secret-2") 

# ==========================================
# 3. HELPER: UPLOAD DATASET
# ==========================================
@app.function(image=image, volumes={"/data": volume}, timeout=600)
def upload_dataset(local_data: bytes):
    print(f" Uploading Multi-Task Dataset to {REMOTE_DATA_PATH}...")
    with open(REMOTE_DATA_PATH, "wb") as f:
        f.write(local_data)
    volume.commit()
    print(" Upload Complete.")

# ==========================================
# 4. TRAINING FUNCTION
# ==========================================
@app.function(
    image=image,
    gpu="A100",         
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
    from unsloth.chat_templates import get_chat_template

    print("🔥 Starting ihalage Multi-Task Training (5 EPOCHS!)...")
    
    # A. LOAD BASE MODEL
    model, tokenizer = FastLanguageModel.from_pretrained(
        model_name = BASE_MODEL,
        max_seq_length = 2048,
        dtype = None,
        load_in_4bit = True, 
    )

    # B. CONFIGURE LORA (The Fine-Tuning Adapters)
    model = FastLanguageModel.get_peft_model(
        model,
        r = 16,
        target_modules = ["q_proj", "k_proj", "v_proj", "o_proj", "gate_proj", "up_proj", "down_proj"],
        lora_alpha = 32,      
        lora_dropout = 0, 
        bias = "none",
        use_gradient_checkpointing = "unsloth",
        random_state = 3407,
    )

    # C. PREPARE DATASET
    print(f" Loading Data from {REMOTE_DATA_PATH}...")
    dataset = load_dataset("json", data_files=REMOTE_DATA_PATH, split="train")

    # Force the Llama-3 Chat Template format explicitly
    tokenizer = get_chat_template(
        tokenizer,
        chat_template = "llama-3", 
    )

    def formatting_prompts_func(examples):
        convos = examples["messages"]
        texts = [tokenizer.apply_chat_template(convo, tokenize=False, add_generation_prompt=False) for convo in convos]
        return {"text": texts}

    # Apply formatting
    dataset = dataset.map(formatting_prompts_func, batched=True)

    # Split Data
    dataset_split = dataset.train_test_split(test_size=0.05)
    
    print(f" Training rows: {len(dataset_split['train'])}")
    print(f" Evaluation rows: {len(dataset_split['test'])}")

    # D. TRAINER SETUP
    trainer = SFTTrainer(
        model = model,
        tokenizer = tokenizer,
        train_dataset = dataset_split["train"],
        eval_dataset = dataset_split["test"],
        dataset_text_field = "text",
        max_seq_length = 2048,
        dataset_num_proc = 2,
        args = TrainingArguments(
            output_dir = "/data/checkpoints_ihalage_5_epochs",    
            per_device_train_batch_size = 4, 
            gradient_accumulation_steps = 4,
            num_train_epochs = 5,            
            save_strategy = "epoch",              
            eval_strategy = "epoch",
            learning_rate = 2e-4, 
            fp16 = not torch.cuda.is_bf16_supported(),
            bf16 = torch.cuda.is_bf16_supported(),
            logging_steps = 10,
            optim = "adamw_8bit",
            weight_decay = 0.01,
            lr_scheduler_type = "linear",
            seed = 3407,
        ),
    )

    print("Training Started...")
    trainer.train()

    # E. SAVE THE FINAL MODEL
    print(f"Saving 5-Epoch LoRA Adapters to {REMOTE_OUTPUT_DIR}...")
    model.save_pretrained(REMOTE_OUTPUT_DIR)
    tokenizer.save_pretrained(REMOTE_OUTPUT_DIR)
    
    volume.commit()
    print("Training and Exporting Finished Successfully!")

# ==========================================
# 5. EXECUTION ENTRY POINT
# ==========================================
@app.local_entrypoint()
def main():
    if os.path.exists(LOCAL_DATA_FILE):
        print(f"Found local file: {LOCAL_DATA_FILE}. Uploading to Modal...")
        with open(LOCAL_DATA_FILE, "rb") as f:
            upload_dataset.remote(f.read())
        train.remote()
    else:
        print(f"Error: Local file {LOCAL_DATA_FILE} not found. Check your file path!")
