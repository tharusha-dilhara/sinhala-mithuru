import modal
import os
import random
import time
import json
import re
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

# ==========================================
# 1. CONFIGURATION
# ==========================================
APP_NAME = "sinhala-mithuru-backend-v10"
VOL_NAME = "sinhala-model-storage"

ADAPTER_DIR = "/data/sinhala-multitask-model-v1" 
BASE_MODEL = "ihalage/llama3-sinhala"

# 🟢 vLLM is specifically built for blazing fast inference
image = (
    modal.Image.debian_slim(python_version="3.11")
    .pip_install(
        "vllm", 
        "fastapi",
        "uvicorn",
        "pydantic",
        "transformers" # Need transformers for the tokenizer just in case
    )
    .env({"HF_TOKEN": os.environ.get("HF_TOKEN", "")})
)

app = modal.App(APP_NAME)
volume = modal.Volume.from_name(VOL_NAME)
hf_secret = modal.Secret.from_name("huggingface-secret-2")

# ==========================================
# 2. INFERENCE ENGINE (vLLM EDITION - A100)
# ==========================================
@app.cls(
    image=image,
    gpu="A100", 
    volumes={"/data": volume},
    secrets=[hf_secret],
    min_containers=1, 
    scaledown_window=300, 
    timeout=1200,
)
class StoryEngine:
    @modal.enter()
    def load_model(self):
        from vllm import LLM
        from vllm.lora.request import LoRARequest
        import json

        print(f"🚀 Loading vLLM Engine: {BASE_MODEL} + Adapters: {ADAPTER_DIR}...")
        
        # Read the adapter config to find true lora rank dynamically
        adapter_config_path = os.path.join(ADAPTER_DIR, "adapter_config.json")
        lora_rank = 64
        try:
            with open(adapter_config_path, "r") as f:
                config = json.load(f)
                if "r" in config:
                    lora_rank = config["r"]
                    print(f"Detected LoRA rank: {lora_rank}")
        except Exception as e:
            print(f"Could not read adapter rank, defaulting to 64. Error: {e}")

        # Initialize vLLM with LoRA enabled
        self.llm = LLM(
            model=BASE_MODEL,
            enable_lora=True,
            max_lora_rank=max(lora_rank, 16),
            dtype="bfloat16",
            gpu_memory_utilization=0.9, # Maximize VRAM usage for speed
        )
        self.lora_request = LoRARequest("adapter", 1, ADAPTER_DIR)
        
        # Get tokenizer path so we can format chat prompts properly
        self.tokenizer = self.llm.get_tokenizer()
        
        self.stop_token_ids = [self.tokenizer.eos_token_id]
        if "<|eot_id|>" in self.tokenizer.get_vocab():
            self.stop_token_ids.append(self.tokenizer.convert_tokens_to_ids("<|eot_id|>"))

        print("✅ Model ready for BLITZ-SPEED Inference (vLLM Acceleration).")

    # --------------------------
    # Story Generation Brain
    # --------------------------
    @modal.method()
    def generate_story_text(self, level: str, theme: str, context: str):
        start_time = time.time()
        from vllm import SamplingParams
        
        EASY_INST = "You are an expert primary school teacher in Sri Lanka. Write a highly entertaining and simple Sinhala story for Grade 1 and 2 children using strict Spoken Sinhala grammar with a clear logical flow (Beginning, Action, End), consisting of exactly 6 sentences."
        HARD_INST = "You are an expert primary school teacher in Sri Lanka. Write a meaningful and educational Sinhala story for Grade 3, 4, and 5 children using strict Formal Written Sinhala grammar with correct Subject-Verb agreement, consisting of exactly 7 sentences."

        safe_level = (level or "").strip()
        safe_theme = (theme or "").strip()
        safe_context = (context or "").strip()

        if safe_level == "සරල":
            instruction = EASY_INST
            current_temp = 0.3      
            current_rep_pen = 1.0   
            max_new = 600
        else:
            instruction = HARD_INST
            current_temp = 0.35       
            current_rep_pen = 1.02   
            max_new = 1500           

        input_text = f"මට්ටම: {safe_level} | තේමාව: {safe_theme} | සන්දර්භය: {safe_context}"
        
        messages = [
            {"role": "system", "content": "You are a primary school teacher in Sri Lanka. Follow the instructions strictly. Output Sinhala text only."},
            {"role": "user", "content": f"{instruction}\n\n{input_text}"}
        ]

        # Use the tokenizer template to structure Llama-3 prompt natively
        prompt = self.tokenizer.apply_chat_template(
            messages, tokenize=False, add_generation_prompt=True
        )

        sampling_params = SamplingParams(
            temperature=current_temp,
            top_p=0.85,
            top_k=40,
            repetition_penalty=current_rep_pen,
            max_tokens=max_new,
            stop_token_ids=self.stop_token_ids,
        )

        outputs = self.llm.generate(
            [prompt], 
            sampling_params=sampling_params, 
            lora_request=self.lora_request,
            use_tqdm=False
        )

        story_output = outputs[0].outputs[0].text.strip()
        generation_time = round(time.time() - start_time, 2)
        print(f"⏱️ Story generated in {generation_time} seconds (vLLM accelerated).")
        
        return story_output, generation_time
    
    # --------------------------
    # Quiz Generation Brain
    # --------------------------
    @modal.method()
    def generate_quiz_text(self, story_text: str, level: str):
        start_time = time.time()
        from vllm import SamplingParams
        
        safe_level = (level or "").strip()
        is_simple = safe_level == "සරල"
        
        if is_simple:
            instruction = "Read the simple Sinhala story and generate exactly 1 multiple-choice question for Grade 1 and 2 children. The question must have exactly 3 options. Output strictly as a valid JSON array."
            target_opt_count = 3
        else:
            instruction = "Read the formal Sinhala story and generate exactly 2 multiple-choice questions for Grade 3, 4, and 5 children. Each question must have exactly 4 options. Output strictly as a valid JSON array."
            target_opt_count = 4

        user_content = f"{instruction}\n\nකතාව: {story_text}"

        messages = [
            {"role": "system", "content": "You are an educational API that only outputs valid JSON. Output Sinhala content inside the JSON."},
            {"role": "user", "content": user_content}
        ]

        prompt = self.tokenizer.apply_chat_template(
            messages, tokenize=False, add_generation_prompt=True
        )

        sampling_params = SamplingParams(
            max_tokens=800,
            temperature=0.1,
            top_p=0.9,
            repetition_penalty=1.05,
            stop_token_ids=self.stop_token_ids,
        )

        outputs = self.llm.generate(
            [prompt], 
            sampling_params=sampling_params, 
            lora_request=self.lora_request,
            use_tqdm=False
        )

        decoded = outputs[0].outputs[0].text.strip()

        # ---------------------
        # ROBUST JSON PARSER
        # ---------------------
        try:
            cleaned_json_string = re.sub(r"```json\s*", "", decoded)
            cleaned_json_string = re.sub(r"```\s*", "", cleaned_json_string).strip()

            start_idx = cleaned_json_string.find("[")
            end_idx = cleaned_json_string.rfind("]")
            
            if start_idx != -1 and end_idx != -1:
                cleaned_json_string = cleaned_json_string[start_idx:end_idx+1]
            else:
                raise ValueError("No JSON array found.")

            raw_quizzes = json.loads(cleaned_json_string)
            final_mcq_list = []

            for q in raw_quizzes:
                q_text = q.get("question", "ප්‍රශ්නය සොයාගත නොහැක")
                options = q.get("options", [])
                answer = q.get("answer", "")

                while len(options) < target_opt_count:
                    options.append("වෙනත් පිළිතුරක්")
                options = options[:target_opt_count]

                if answer not in options:
                    options[0] = answer 

                random.shuffle(options)
                
                try:
                    correct_idx = options.index(answer)
                except ValueError:
                    correct_idx = 0

                final_mcq_list.append({
                    "question": q_text,
                    "options": options,
                    "correct_answer": correct_idx 
                })

            if not final_mcq_list: raise ValueError("Empty JSON.")
            
            generation_time = round(time.time() - start_time, 2)
            print(f"⏱️ Quiz JSON parsed perfectly in {generation_time} seconds (vLLM accelerated).")
            return final_mcq_list, generation_time

        except Exception as e:
            print(f"JSON Parsing Error: {e}\nRaw Output: {decoded}")
            fallback_opts = ["ඔව්", "නැහැ", "මතක නැහැ"]
            if target_opt_count == 4: fallback_opts.append("වෙනත්")
            return [{"question": "කතාව කියවා අවසන් ද?", "options": fallback_opts, "correct_answer": 0}], round(time.time() - start_time, 2)
        
# ==========================================
# 3. FASTAPI ENDPOINT
# ==========================================
web_app = FastAPI(title="Sinhala Mithuru Backend V10 (vLLM Accelerated)")

web_app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

class StoryRequest(BaseModel):
    level: str
    theme: str
    context: str 

class QuizRequest(BaseModel):
    story: str
    level: str

engine = StoryEngine()

@web_app.post("/generate_story")
async def api_generate_story(req: StoryRequest):
    story, gen_time = await engine.generate_story_text.remote.aio(
        level=req.level, theme=req.theme, context=req.context
    )
    return {"story": story, "time": gen_time}

@web_app.post("/generate_quiz")
async def api_generate_quiz(req: QuizRequest):
    quiz, gen_time = await engine.generate_quiz_text.remote.aio(
        story_text=req.story, level=req.level
    )
    return {"quiz": quiz, "time": gen_time}

@app.function(image=image, timeout=1800, min_containers=1)
@modal.asgi_app()
def fastapi_app():
    return web_app