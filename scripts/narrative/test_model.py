import modal

# ==========================================
# 1. CONFIGURATION
# ==========================================
APP_NAME = "sinhala-story-tester" 
VOL_NAME = "sinhala-model-storage"
# By default, pointing to your 5-epoch test model! Change this if you want to test another folder.
MODEL_DIR = "/data/outputs_ihalage_5_epochs_lora" 

# ==========================================
# 2. ENVIRONMENT SETUP
# ==========================================
image = (
    modal.Image.debian_slim(python_version="3.11")
    .pip_install("unsloth", "torch", "transformers", "accelerate")
)

app = modal.App(APP_NAME)
volume = modal.Volume.from_name(VOL_NAME)

# ==========================================
# 3. INFERENCE FUNCTION
# ==========================================
@app.function(
    image=image,
    gpu="A10G",           
    timeout=600,        
    volumes={"/data": volume}
)
def run_evaluations():
    from unsloth import FastLanguageModel
    
    print(f"🚀 Loading your fine-tuned model from {MODEL_DIR}...")
    model, tokenizer = FastLanguageModel.from_pretrained(
        model_name = MODEL_DIR,
        max_seq_length = 2048,
        dtype = None,
        load_in_4bit = True,
    )
    FastLanguageModel.for_inference(model)

    print("="*80)
    print(f"🔥 GENERATING STORY & QUIZ EVALUATIONS FOR: {MODEL_DIR}")
    print("="*80)
    
    # TIER 1: SIMPLE (EASY - Grade 1-2)
    print("\n" + "="*80)
    print("--- TIER 1: SIMPLE (GRADE 1-2) ---")
    print("="*80)
    easy_sys = "You are an expert primary school teacher in Sri Lanka. Write a highly entertaining and simple Sinhala story for Grade 1 and 2 children using strict Spoken Sinhala grammar with a clear logical flow (Beginning, Action, End), consisting of exactly 6 sentences."
    easy_user = "මට්ටම: සරල | තේමාව: යහපුරුදු | සන්දර්භය: වැඩිහිටියන්ට සැලකීම"
    story_messages = [{"role": "system", "content": easy_sys}, {"role": "user", "content": easy_user}]
    s_prompt = tokenizer.apply_chat_template(story_messages, tokenize=False, add_generation_prompt=True)
    s_inputs = tokenizer([s_prompt], return_tensors="pt").to("cuda")
    s_outs = model.generate(**s_inputs, max_new_tokens=400, temperature=0.3, top_p=0.85, repetition_penalty=1.05)
    story_text = tokenizer.decode(s_outs[0], skip_special_tokens=True).split(easy_user)[-1].strip()
    if story_text.startswith("assistant"): story_text = story_text.replace("assistant", "", 1).strip()
    print(f"[SIMPLE STORY OUTPUT]\n{story_text}\n")
    
    quiz_messages = [
        {"role": "system", "content": "You are an educational API that only outputs valid JSON. Output Sinhala content inside the JSON."},
        {"role": "user", "content": f"Read the simple Sinhala story and generate exactly 1 multiple-choice question for Grade 1 and 2 children. The question must have exactly 3 options. Output strictly as a valid JSON array.\n\nකතාව: {story_text}"}
    ]
    q_prompt = tokenizer.apply_chat_template(quiz_messages, tokenize=False, add_generation_prompt=True)
    q_inputs = tokenizer([q_prompt], return_tensors="pt").to("cuda")
    q_outs = model.generate(**q_inputs, max_new_tokens=400, temperature=0.1, top_p=0.9, repetition_penalty=1.05)
    quiz_text = tokenizer.decode(q_outs[0], skip_special_tokens=True).split("Output strictly as a valid JSON array.")[-1].strip()
    if quiz_text.startswith("assistant"): quiz_text = quiz_text.replace("assistant", "", 1).strip() 
    if quiz_text.startswith("කතාව:"): quiz_text = quiz_text.split("\n\n", 1)[-1].strip()
    print(f"[SIMPLE QUIZ JSON OUTPUT]\n{quiz_text}\n")
    
    # TIER 2: HARD (GRADE 3-5)
    print("\n" + "="*80)
    print("--- TIER 2: HARD (GRADE 3-5) ---")
    print("="*80)
    hard_sys = "You are an expert primary school teacher in Sri Lanka. Write a meaningful and educational Sinhala story for Grade 3, 4, and 5 children using strict Formal Written Sinhala grammar with correct Subject-Verb agreement, consisting of exactly 7 sentences."
    hard_user = "මට්ටම: උසස් | තේමාව: විනෝද චාරිකා | සන්දර්භය: බඹරකන්ද දිය ඇල්ල"
    h_story_messages = [{"role": "system", "content": hard_sys}, {"role": "user", "content": hard_user}]
    h_s_prompt = tokenizer.apply_chat_template(h_story_messages, tokenize=False, add_generation_prompt=True)
    h_s_inputs = tokenizer([h_s_prompt], return_tensors="pt").to("cuda")
    h_s_outs = model.generate(**h_s_inputs, max_new_tokens=600, temperature=0.3, top_p=0.85, repetition_penalty=1.05)
    h_story_text = tokenizer.decode(h_s_outs[0], skip_special_tokens=True).split(hard_user)[-1].strip()
    if h_story_text.startswith("assistant"): h_story_text = h_story_text.replace("assistant", "", 1).strip()
    print(f"[HARD STORY OUTPUT]\n{h_story_text}\n")
    
    h_quiz_messages = [
        {"role": "system", "content": "You are an educational API that only outputs valid JSON. Output Sinhala content inside the JSON."},
        {"role": "user", "content": f"Read the Sinhala story and generate exactly 2 multiple-choice questions for Grade 3, 4, and 5 children. Each question must have exactly 4 options. Output strictly as a valid JSON array.\n\nකතාව: {h_story_text}"}
    ]
    hq_prompt = tokenizer.apply_chat_template(h_quiz_messages, tokenize=False, add_generation_prompt=True)
    hq_inputs = tokenizer([hq_prompt], return_tensors="pt").to("cuda")
    hq_outs = model.generate(**hq_inputs, max_new_tokens=600, temperature=0.1, top_p=0.9, repetition_penalty=1.05)
    h_quiz_text = tokenizer.decode(hq_outs[0], skip_special_tokens=True).split("Output strictly as a valid JSON array.")[-1].strip()
    if h_quiz_text.startswith("assistant"): h_quiz_text = h_quiz_text.replace("assistant", "", 1).strip() 
    if h_quiz_text.startswith("කතාව:"): h_quiz_text = h_quiz_text.split("\n\n", 1)[-1].strip()
    print(f"[HARD QUIZ JSON OUTPUT]\n{h_quiz_text}\n")

# ==========================================
# 4. EXECUTION
# ==========================================
@app.local_entrypoint()
def main():
    print("Initiating Multi-Task Verification Test on Modal...")
    run_evaluations.remote()