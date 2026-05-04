import json
import re
import os
import random

# ==========================================
# 1. CONFIGURATION
# ==========================================
INPUT_FILE = "../data/quiz_data.jsonl"       
OUTPUT_FILE = "../data/quiz_data_CLEANED.jsonl" 

# 🟢 NEW SINGLE-LINE INSTRUCTIONS
EASY_QUIZ_INST = "You are an educational API. Read the simple Sinhala story and generate exactly 1 multiple-choice question for Grade 1 and 2 children. The question must have exactly 3 options. Output strictly as a valid JSON array."

HARD_QUIZ_INST = "You are an educational API. Read the formal Sinhala story and generate exactly 2 multiple-choice questions for Grade 3, 4, and 5 children. Each question must have exactly 4 options. Output strictly as a valid JSON array."

# ==========================================
# 2. HELPER FUNCTIONS
# ==========================================
def clean_text_general(text):
    """
    Aggressive cleaning: Removes English, Numbers, Brackets, Double Spaces.
    """
    if not text: return ""
    
    # Standardize Quotes
    text = text.replace("“", '"').replace("”", '"').replace("‘", "'").replace("’", "'")
    
    # 🟢 AUTO-FIX SPECIFIC TYPOS
    # Fixes the 'Rain' story error where 'wetima' merged with 'lamaya'
    text = text.replace("වැටීළමයාට", "වැටීමට")
    
    # Remove content in brackets (e.g. English definitions)
    text = re.sub(r'\s*\([^)]*\)', '', text)
    
    # Remove English letters
    text = re.sub(r'[a-zA-Z]', '', text)
    
    # Remove Numbers (0-9)
    text = re.sub(r'\d+', '', text)
    
    # Remove non-Sinhala artifacts (Hindi, etc.)
    text = re.sub(r'[\u0900-\u097F]', '', text)
    
    # Remove double spaces
    text = re.sub(r'\s+', ' ', text)
    
    return text.strip()

def clean_quiz_dataset():
    # Regex to catch prefixes like "අ) ", "1.", "i."
    prefix_pattern = re.compile(r"^([අ-ෆ]|\d+|[ivx]+)[\)\.]\s*", re.IGNORECASE)
    
    # Letter mapping for answers like "ආ" -> Index 1
    letter_map = {"අ": 0, "ආ": 1, "ඇ": 2, "ඈ": 3, "ඉ": 4}

    print(f"🛠️ Starting Quiz Cleanup on {INPUT_FILE}...")
    
    valid_rows = []
    
    with open(INPUT_FILE, "r", encoding="utf-8") as infile:
        for line_num, line in enumerate(infile):
            if not line.strip(): continue
            
            try:
                data = json.loads(line)
                
                # 1. Clean the Input Story (Context)
                original_input = data.get("input", "")
                
                # If "input" contains "කතාව:", clean the text after it
                if "කතාව:" in original_input:
                    pre, post = original_input.split("කතාව:", 1)
                    clean_story = clean_text_general(post)
                    final_input = f"කතාව: {clean_story}"
                else:
                    final_input = clean_text_general(original_input)

                # 2. Parse and Clean Output JSON
                raw_output_str = data.get("output", "[]")
                
                # Handle cases where output is already a dict/list or string
                if isinstance(raw_output_str, str):
                    try:
                        questions_list = json.loads(raw_output_str)
                    except:
                        print(f"⚠️ Skipping line {line_num}: Invalid JSON string")
                        continue
                else:
                    questions_list = raw_output_str

                # Support {"questions": [...]} format wrapper
                if isinstance(questions_list, dict) and "questions" in questions_list:
                    questions_list = questions_list["questions"]
                
                if not isinstance(questions_list, list):
                    continue

                cleaned_questions = []
                
                for q in questions_list:
                    # Clean Question Text
                    q_text = clean_text_general(q.get("question", ""))
                    q_text = q_text.replace("මම", "ළමයා").replace("මගේ", "ළමයාගේ").replace("මට", "ළමයාට")
                    
                    # Clean Options
                    raw_options = q.get("options", [])
                    clean_options = []
                    for opt in raw_options:
                        # Remove "A)", "1.", "අ)" prefixes
                        opt_text = prefix_pattern.sub("", str(opt)).strip()
                        clean_options.append(clean_text_general(opt_text))
                    
                    # Clean Answer
                    raw_answer = str(q.get("answer", "")).strip()
                    
                    # Logic to fix answer matching
                    final_answer = ""
                    
                    # Check if answer is an index letter (අ, ආ)
                    stripped_answer_letter = prefix_pattern.sub("", raw_answer).strip()
                    
                    if stripped_answer_letter in letter_map and len(clean_options) > letter_map[stripped_answer_letter]:
                        # Map "ආ" to the 2nd option text
                        final_answer = clean_options[letter_map[stripped_answer_letter]]
                    else:
                        # Otherwise clean the text and try to match
                        clean_ans_text = clean_text_general(prefix_pattern.sub("", raw_answer))
                        
                        # Fuzzy match: if exact match fails, check if one contains the other
                        if clean_ans_text in clean_options:
                            final_answer = clean_ans_text
                        else:
                            # Auto-correction: Try to find best match or default to Option 1
                            match_found = False
                            for opt in clean_options:
                                if clean_ans_text in opt or opt in clean_ans_text:
                                    final_answer = opt
                                    match_found = True
                                    break
                            
                            if not match_found and clean_options:
                                final_answer = clean_options[0] # Fallback
                    
                    cleaned_questions.append({
                        "question": q_text,
                        "options": clean_options,
                        "answer": final_answer
                    })

                # 3. Determine Instruction based on Question Count
                # 1 Question = Easy Inst | 2+ Questions = Hard Inst
                if len(cleaned_questions) == 1:
                    final_inst = EASY_QUIZ_INST
                else:
                    final_inst = HARD_QUIZ_INST

                # 4. Save Row
                valid_rows.append({
                    "instruction": final_inst,
                    "input": final_input,
                    "output": json.dumps(cleaned_questions, ensure_ascii=False)
                })

            except Exception as e:
                print(f"❌ Error line {line_num}: {e}")
                continue

    # 🟢 SHUFFLING STEP
    print("🔀 Shuffling the dataset...")
    random.seed(42)  # Ensures the shuffle is reproducible
    random.shuffle(valid_rows)

    # Write to file
    print(f"💾 Saving {len(valid_rows)} cleaned quizzes to {OUTPUT_FILE}...")
    with open(OUTPUT_FILE, "w", encoding="utf-8") as outfile:
        for row in valid_rows:
            outfile.write(json.dumps(row, ensure_ascii=False) + "\n")

    print(f"✅ DONE! Cleaned English, Numbers, Double Spaces, fixed Typos, Shuffled, and applied Strong Instructions.")

if __name__ == "__main__":
    clean_quiz_dataset()