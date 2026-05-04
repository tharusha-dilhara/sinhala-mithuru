import json
import os
import random
import re

# ==========================================
# 1. CONFIGURATION
# ==========================================
# Input Files (From your previous cleaning steps)
STORY_INPUT_FILE = "../data/story_level_STRONG.jsonl"
QUIZ_INPUT_FILE = "../data/quiz_data_CLEANED.jsonl" 

# Final Output File (For Unsloth Training)
OUTPUT_FILE = "../data/final_multitask_chat1.jsonl"

# --- SYSTEM PROMPTS (The "Brain" Definition) ---
# We use two different system prompts to help the model switch "Modes"
STORY_SYSTEM_PROMPT = "You are a primary school teacher in Sri Lanka. Follow the instructions strictly. Output Sinhala text only."
QUIZ_SYSTEM_PROMPT = "You are an educational API that only outputs valid JSON. Output Sinhala content inside the JSON."

def convert_and_merge():
    all_chat_rows = []
    
    # ==========================================
    # 2. PROCESS STORIES
    # ==========================================
    if os.path.exists(STORY_INPUT_FILE):
        print(f"📖 Reading Stories from {STORY_INPUT_FILE}...")
        with open(STORY_INPUT_FILE, "r", encoding="utf-8") as infile:
            for line in infile:
                if not line.strip(): continue
                try:
                    row = json.loads(line)
                    
                    # 1. Get the Strong Instruction we saved earlier
                    instruction = row.get("instruction", "").strip()
                    input_text = row.get("input", "").strip()
                    output_text = row.get("output", "").strip()
                    
                    # 2. Safety Clean: Remove hallucinated image tags if any exist
                    output_text = re.sub(r'\[Image of.*?\]\s*', '', output_text, flags=re.IGNORECASE)
                    
                    # 3. Construct User Prompt
                    user_content = f"{instruction}\n\n{input_text}"
                    
                    # 4. Create ChatML Object
                    chat_row = {
                        "messages": [
                            {"role": "system", "content": STORY_SYSTEM_PROMPT},
                            {"role": "user", "content": user_content},
                            {"role": "assistant", "content": output_text}
                        ]
                    }
                    all_chat_rows.append(chat_row)
                    
                except json.JSONDecodeError:
                    continue
        print(f"✅ Loaded Stories. Total rows so far: {len(all_chat_rows)}")
    else:
        print(f"⚠️ Warning: {STORY_INPUT_FILE} not found.")

    # ==========================================
    # 3. PROCESS QUIZZES
    # ==========================================
    if os.path.exists(QUIZ_INPUT_FILE):
        print(f"📝 Reading Quizzes from {QUIZ_INPUT_FILE}...")
        with open(QUIZ_INPUT_FILE, "r", encoding="utf-8") as infile:
            for line in infile:
                if not line.strip(): continue
                try:
                    row = json.loads(line)
                    
                    # 1. Get the Strong Quiz Instruction
                    instruction = row.get("instruction", "").strip()
                    
                    # Optimization: If the instruction repeats the system prompt, clean it slightly
                    # (Optional, but makes input cleaner)
                    instruction = instruction.replace("You are an educational API. ", "")
                    
                    input_text = row.get("input", "").strip()
                    output_text = row.get("output", "").strip()
                    
                    # 2. Construct User Prompt
                    user_content = f"{instruction}\n\n{input_text}"
                    
                    # 3. Create ChatML Object
                    chat_row = {
                        "messages": [
                            {"role": "system", "content": QUIZ_SYSTEM_PROMPT},
                            {"role": "user", "content": user_content},
                            {"role": "assistant", "content": output_text}
                        ]
                    }
                    all_chat_rows.append(chat_row)
                    
                except json.JSONDecodeError:
                    continue
        print(f"✅ Loaded Quizzes. Total rows so far: {len(all_chat_rows)}")
    else:
        print(f"⚠️ Warning: {QUIZ_INPUT_FILE} not found.")

    # ==========================================
    # 4. SHUFFLE AND SAVE
    # ==========================================
    if not all_chat_rows:
        print("❌ Error: No data found to process.")
        return

    print("🔀 Shuffling the mixed dataset (Stories + Quizzes)...")
    random.seed(42) # Seed ensures the shuffle is the same every time you run it
    random.shuffle(all_chat_rows)

    print(f"💾 Saving final dataset to {OUTPUT_FILE}...")
    with open(OUTPUT_FILE, "w", encoding="utf-8") as outfile:
        for row in all_chat_rows:
            outfile.write(json.dumps(row, ensure_ascii=False) + "\n")

    print("\n" + "="*60)
    print(f"🚀 SUCCESS! {len(all_chat_rows)} rows are ready for Unsloth.")
    print(f"📂 File: {OUTPUT_FILE}")
    print("="*60)

if __name__ == "__main__":
    convert_and_merge()