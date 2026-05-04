import time
import json
import re
from llama_cpp import Llama

# ==========================================
# SET YOUR LOCAL MODEL PATH HERE
# ==========================================
# After the download finishes, copy the path printed by test_generation.py
# e.g: "Model path: C:\Users\owner\.cache\huggingface\hub\..."
MODEL_PATH = r"C:\Users\owner\.cache\huggingface\hub\models--IshiniTecla442--sinhala-mithuru-cpu-backup\snapshots\e64db68e64e3094859916b32a4e29e7c796be023\llama3-sinhala.Q4_K_M.gguf"

# ==========================================
# TEST SETTINGS
# ==========================================
LEVEL   = "සරල"           # "සරල" (Easy) or "උසස්" (Hard)
THEME   = "සතුන්"         # Topic/theme
CONTEXT = "වනාන්තරයේ මිතුරන්"  # Context/scenario


def load_model():
    print(f"Loading model from:\n  {MODEL_PATH}\n")
    start = time.time()
    llm = Llama(
        model_path=MODEL_PATH,
        n_ctx=2048,
        chat_format="llama-3",
        verbose=False
    )
    print(f"Model loaded in {time.time() - start:.2f}s\n")
    return llm


def generate_story(llm):
    if LEVEL == "සරල":
        instruction = (
            "You are an expert primary school teacher in Sri Lanka. "
            "Write a highly entertaining and simple Sinhala story for Grade 1 and 2 children "
            "using strict Spoken Sinhala grammar with a clear logical flow (Beginning, Action, End), "
            "consisting of exactly 6 sentences."
        )
    else:
        instruction = (
            "You are an expert primary school teacher in Sri Lanka. "
            "Write a meaningful and educational Sinhala story for Grade 3, 4, and 5 children "
            "using strict Formal Written Sinhala grammar with correct Subject-Verb agreement, "
            "consisting of exactly 7 sentences."
        )

    messages = [
        {"role": "system", "content": "You are a primary school teacher in Sri Lanka. Follow the instructions strictly. Output Sinhala text only."},
        {"role": "user",   "content": f"{instruction}\n\nමට්ටම: {LEVEL} | තේමාව: {THEME} | සන්දර්භය: {CONTEXT}"}
    ]

    print("--- Generating Story ---")
    start = time.time()
    response = llm.create_chat_completion(
        messages=messages,
        max_tokens=600 if LEVEL == "සරල" else 1000,
        temperature=0.3,
        stop=["<|eot_id|>"]
    )
    story = response["choices"][0]["message"]["content"].strip()
    print(f"Time: {time.time() - start:.2f}s\n")
    print("Story:\n" + story + "\n")
    return story


def generate_quiz(llm, story_text):
    if LEVEL == "සරල":
        instruction = (
            "Read the simple Sinhala story and generate exactly 1 multiple-choice question "
            "for Grade 1 and 2 children. The question must have exactly 3 options. "
            "Output strictly as a valid JSON array."
        )
    else:
        instruction = (
            "Read the formal Sinhala story and generate exactly 2 multiple-choice questions "
            "for Grade 3, 4, and 5 children. Each question must have exactly 4 options. "
            "Output strictly as a valid JSON array."
        )

    messages = [
        {"role": "system", "content": "You are an educational API that only outputs valid JSON. Output Sinhala content inside the JSON."},
        {"role": "user",   "content": f"{instruction}\n\nකතාව: {story_text}"}
    ]

    print("--- Generating Quiz ---")
    start = time.time()
    response = llm.create_chat_completion(
        messages=messages,
        max_tokens=800,
        temperature=0.1,
        stop=["<|eot_id|>"]
    )
    raw = response["choices"][0]["message"]["content"].strip()
    print(f"Time: {time.time() - start:.2f}s\n")
    print("Raw Quiz JSON:\n" + raw + "\n")

    # Parse and pretty-print the JSON
    try:
        cleaned = re.sub(r"```json\s*|```\s*", "", raw).strip()
        start_i = cleaned.find("[")
        end_i   = cleaned.rfind("]")
        if start_i != -1 and end_i != -1:
            cleaned = cleaned[start_i:end_i+1]
        quiz = json.loads(cleaned)
        print("Parsed Quiz:\n" + json.dumps(quiz, ensure_ascii=False, indent=2))
    except Exception as e:
        print(f"Could not parse JSON: {e}")


if __name__ == "__main__":
    if MODEL_PATH == "PASTE_YOUR_MODEL_PATH_HERE":
        print("❌ Please set MODEL_PATH at the top of this file before running.")
    else:
        llm   = load_model()
        story = generate_story(llm)
        generate_quiz(llm, story)
