import json
import re
import os
import random

# ==========================================
# 1. CONFIGURATION
# ==========================================
INPUT_FILE = "../data/story_level.jsonl"       
OUTPUT_FILE = "../data/story_level_STRONG.jsonl" 

# 🟢 UPDATE: These are the NEW "Strong" Instructions
# They explicitly enforce Grammar, Flow, and Content constraints.

EASY_INST = "You are an expert primary school teacher in Sri Lanka. Write a highly entertaining and simple Sinhala story for Grade 1 and 2 children using strict Spoken Sinhala grammar with a clear logical flow (Beginning, Action, End), consisting of exactly 6 sentences."

HARD_INST = "You are an expert primary school teacher in Sri Lanka. Write a meaningful and educational Sinhala story for Grade 3, 4, and 5 children using strict Formal Written Sinhala grammar with correct Subject-Verb agreement, consisting of exactly 7 sentences."

# ==========================================
# 2. HELPER FUNCTIONS
# ==========================================
def clean_text_general(text):
    """
    Master cleaning function for ANY text (Input Context or Output Story).
    Removes: English letters, Numbers, Hindi chars, Brackets, and Double Spaces.
    """
    if not text: return ""
    
    # 1. Standardize Quotes
    text = text.replace("“", '"').replace("”", '"')
    text = text.replace("‘", "'").replace("’", "'")
    
    # 2. Remove Content inside Parentheses (often English definitions like '(Cat)')
    text = re.sub(r'\s*\([^)]*\)', '', text)
    
    # 3. Remove ALL English Letters (a-z, A-Z) - Strict cleaning
    text = re.sub(r'[a-zA-Z]', '', text)

    # 4. Remove Numeric Digits (0-9) - We want pure text stories
    text = re.sub(r'\d+', '', text)
    
    # 5. Remove Hindi/Foreign Devanagari characters (common artifacts)
    text = re.sub(r'[\u0900-\u097F]', '', text)
    
    # 6. Replace multiple spaces with a single space (The Final Polish)
    text = re.sub(r'\s+', ' ', text)
    
    return text.strip()

def extract_metadata(input_str):
    """
    Extracts Level, Theme, and Context from the old input string.
    """
    if not input_str: return "Unknown", "General", ""
    
    # Extract Level
    level_match = re.search(r"මට්ටම:\s*(සරල|උසස්)", input_str)
    level = level_match.group(1).strip() if level_match else "Unknown"
    
    # Extract Theme
    theme_match = re.search(r"තේමාව:\s*([^|]+)", input_str)
    theme = theme_match.group(1).strip() if theme_match else "General"
    
    # Extract Context
    context_match = re.search(r"සන්දර්භය:\s*(.+)", input_str)
    raw_context = context_match.group(1).strip() if context_match else ""
    
    # Clean the context string specifically
    clean_context = clean_text_general(raw_context)
    
    return level, theme, clean_context

# ==========================================
# 3. MAIN SCRIPT
# ==========================================
def clean_and_group_dataset():
    if not os.path.exists(INPUT_FILE):
        print(f"❌ Error: File {INPUT_FILE} not found.")
        return

    print(f"📂 Reading {INPUT_FILE}...")
    
    processed_rows = []
    
    with open(INPUT_FILE, "r", encoding="utf-8") as f:
        for line_num, line in enumerate(f):
            if not line.strip(): continue
            try:
                row = json.loads(line)
                
                # 1. Extract metadata from the existing input field
                original_input = row.get("input", "")
                level, theme, context = extract_metadata(original_input)
                
                # 2. Clean the Output Story (Crucial Step)
                clean_output = clean_text_general(row.get("output", ""))
                
                # 3. Construct the NEW clean Input string
                # We rebuild this string to ensure no double spaces or dirt remain
                new_input_str = f"මට්ටම: {level} | තේමාව: {theme}"
                if context:
                    new_input_str += f" | සන්දර්භය: {context}"
                
                # 4. Assign the Correct Strong Instruction based on Level
                if level == "සරල":
                    new_instruction = EASY_INST
                elif level == "උසස්":
                    new_instruction = HARD_INST
                else:
                    # If level is unknown, skip this row
                    continue 

                # 5. Build Final Row
                final_row = {
                    "instruction": new_instruction,
                    "input": new_input_str,
                    "output": clean_output
                }
                
                processed_rows.append(final_row)
                
            except json.JSONDecodeError:
                print(f"⚠️ JSON Error on line {line_num}")
                continue

    print(f"🔄 Processed {len(processed_rows)} valid stories.")
    
    # Shuffling
    print("🔀 Shuffling dataset...")
    random.seed(42) 
    random.shuffle(processed_rows)

    # Saving
    print(f"💾 Saving to {OUTPUT_FILE}...")
    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        for row in processed_rows:
            f.write(json.dumps(row, ensure_ascii=False) + "\n")

    print("\n" + "="*50)
    print(f"✅ CLEANING COMPLETE!")
    print(f"1. Applied STRONG instructions (Logical Flow & Grammar Rules).")
    print(f"2. Removed English, Numbers, and Brackets.")
    print(f"3. Removed Double Spaces.")
    print(f"4. Saved {len(processed_rows)} rows to '{OUTPUT_FILE}'")
    print("="*50)

if __name__ == "__main__":
    clean_and_group_dataset()