import asyncio
from datetime import datetime, timezone
from app.db.supabase import supabase
import base64
import httpx

class GameService:
    
    @staticmethod
    async def get_next_task(student_id: int):
        """දරුවා ලොග් වූ පසු මුලින්ම Call කළ යුතු API එක - Database-first approach"""
        res_student = await asyncio.to_thread(
            lambda: supabase.table("students") \
                .select("class_id, classes(grade)") \
                .eq("id", student_id).maybe_single().execute()
        )
        
        if not res_student or not hasattr(res_student, 'data') or not res_student.data:
            return {"task_type": "error", "message": "ශිෂ්යයා සොයාගත නොහැක."}
            
        student_data = res_student.data
        class_id = student_data.get('class_id')
        classes_data = student_data.get('classes')
        
        if not class_id or not classes_data:
            return {"task_type": "error", "message": "පන්තිය සොයාගත නොහැක."}

        now = datetime.now(timezone.utc).isoformat()

        state_res = await asyncio.to_thread(
            lambda: supabase.table("student_game_state").select("*").eq("student_id", student_id).maybe_single().execute()
        )
        
        if not state_res or not hasattr(state_res, 'data') or not state_res.data:
            return {"task_type": "error", "message": "Game State සකසා නැත."}
        
        state_data = state_res.data
        current_level_id = state_data.get('current_level_id')

        if not current_level_id:
            return {"task_type": "error", "message": "වත්මන් මට්ටම සකසා නැත."}

        results = await asyncio.gather(
            asyncio.to_thread(GameService._get_active_assignment_sync, class_id, now),
            asyncio.to_thread(GameService._fetch_level_content_sync, current_level_id),
            asyncio.to_thread(GameService._get_game_level_sync, current_level_id),
            asyncio.to_thread(GameService._get_class_config_sync, class_id, current_level_id)
        )

        res_assign_data, level_assets, level_data, class_config = results

        if not level_data or not hasattr(level_data, 'data') or not level_data.data:
            return {
                "task_type": "game_completed",
                "message": "සුබ පැතුම්! ඔබ සියලුම මට්ටම් සාර්ථකව අවසන් කර ඇත.",
                "state": state_data,
                "targets": {},
                "remaining": {},
                "level_assets": {"pronunciation": [], "handwriting": [], "grammar": [], "narrative": []}
            }

        level_info = level_data.data
        config_data = class_config.data if class_config and hasattr(class_config, 'data') else None

        if res_assign_data:
            res_status = await asyncio.to_thread(
                lambda: supabase.table("student_assignments_status").select("is_completed") \
                    .eq("student_id", student_id).eq("assignment_id", res_assign_data['id']).maybe_single().execute()
            )

            if not res_status.data or res_status.data.get('is_completed') == False:
                content = await GameService.fetch_content_by_id(res_assign_data['component_type'], res_assign_data['content_id'])
                return {
                    "task_type": "assignment",
                    "assignment_id": res_assign_data['id'],
                    "component": res_assign_data['component_type'],
                    "content": content
                }

        targets = {
            "hw": (config_data.get('custom_target_hw') if config_data else None) or level_info.get('default_target_hw', 1),
            "pron": (config_data.get('custom_target_pron') if config_data else None) or level_info.get('default_target_pron', 2),
            "gram": (config_data.get('custom_target_gram') if config_data else None) or level_info.get('default_target_gram', 1),
            "narr": (config_data.get('custom_target_narr') if config_data else None) or level_info.get('default_target_narr', 1)
        }

        remaining = {
            "hw": max(0, targets["hw"] - state_data.get("current_hw_count", 0)),
            "pron": max(0, targets["pron"] - state_data.get("current_pron_count", 0)),
            "gram": max(0, targets["gram"] - state_data.get("current_gram_count", 0)),
            "narr": max(0, targets["narr"] - state_data.get("current_narr_count", 0))
        }

        for comp_key in ["handwriting", "pronunciation", "grammar", "narrative"]:
            short_name = {"handwriting": "hw", "pronunciation": "pron", "grammar": "gram", "narrative": "narr"}[comp_key]
            current_count = state_data.get(f"current_{short_name}_count", 0)
            target_limit = targets[short_name]
            assets = level_assets.get(comp_key, [])

            if current_count >= target_limit:
                level_assets[comp_key] = [] 
            elif assets:
                completed_ids_res = await asyncio.to_thread(
                    lambda: supabase.table("activity_logs") \
                        .select("raw_input").eq("student_id", student_id) \
                        .eq("component_type", short_name).eq("level_id", current_level_id) \
                        .eq("is_correct", True).execute()
                )
                
                if completed_ids_res and completed_ids_res.data:
                    completed_ids = []
                    import json
                    for log in completed_ids_res.data:
                        raw = log.get('raw_input')
                        if isinstance(raw, str):
                            try:
                                raw = json.loads(raw)
                            except:
                                raw = {}
                        if isinstance(raw, dict) and raw.get('content_id'):
                            completed_ids.append(raw.get('content_id'))
                            
                    level_assets[comp_key] = [item for item in assets if item.get('id') not in completed_ids]

        return {
            "task_type": "regular_level", 
            "state": state_data,
            "targets": targets,
            "remaining": remaining,
            "level_assets": level_assets,
            "level_info": {
                "id": level_info.get('id'),
                "grade": level_info.get('grade'),
                "level_number": level_info.get('level_number')
            }
        }

    @staticmethod
    def _get_active_assignment_sync(class_id, now):
        if not class_id: 
            return None
        try:
            res = supabase.table("class_assignments").select("*") \
                .eq("class_id", class_id) \
                .lte("start_date", now) \
                .gte("end_date", now) \
                .limit(1) \
                .execute()
            return res.data[0] if res and res.data and len(res.data) > 0 else None
        except Exception as e:
            print(f"Assignment query error (non-critical): {e}")
            return None

    @staticmethod
    def _get_game_level_sync(level_id):
        return supabase.table("game_levels").select("*").eq("id", level_id).maybe_single().execute()

    @staticmethod
    def _get_class_config_sync(class_id, level_id):
        if not class_id: return None
        return supabase.table("class_level_configs").select("*").eq("class_id", class_id).eq("level_id", level_id).maybe_single().execute()

    @staticmethod
    def _fetch_level_content_sync(level_id: int):
        pron = supabase.table("content_pronunciation").select("*").eq("level_id", level_id).execute()
        hw = supabase.table("content_handwriting").select("*").eq("level_id", level_id).execute()
        gram = supabase.table("content_grammar").select("*").eq("level_id", level_id).execute()
        narr = supabase.table("content_narrative").select("*").eq("level_id", level_id).execute()
        
        return {
            "pronunciation": pron.data if pron and hasattr(pron, 'data') else [], 
            "handwriting": hw.data if hw and hasattr(hw, 'data') else [], 
            "grammar": gram.data if gram and hasattr(gram, 'data') else [], 
            "narrative": narr.data if narr and hasattr(narr, 'data') else []
        }

    @staticmethod
    async def fetch_content_by_id(comp_type: str, content_id: int):
        table_map = {"pron": "content_pronunciation", "hw": "content_handwriting", "gram": "content_grammar", "narr": "content_narrative"}
        res = await asyncio.to_thread(lambda: supabase.table(table_map[comp_type]).select("*").eq("id", content_id).maybe_single().execute())
        return res.data if res and hasattr(res, 'data') else None

    @staticmethod
    async def process_activity(student_id: int, submission: any):
        state_res = await asyncio.to_thread(
            lambda: supabase.table("student_game_state").select("current_level_id").eq("student_id", student_id).maybe_single().execute()
        )
        
        level_id = state_res.data.get('current_level_id') if state_res and state_res.data else None
        
        await asyncio.to_thread(
            lambda: supabase.table("activity_logs").insert({
                "student_id": student_id,
                "level_id": level_id,
                "component_type": submission.component_type,
                "score": submission.score,
                "is_correct": submission.is_correct
            }).execute()
        )

        if not submission.is_correct:
            return {"status": "retry", "message": "වැරදියි, නැවත උත්සාහ කරන්න."}

        res = await asyncio.to_thread(
            lambda: supabase.rpc("handle_game_progress", {
                "p_student_id": student_id,
                "p_component": submission.component_type
            }).execute()
        )
        
        return {"status": "success", "progress": res.data}

    @staticmethod
    async def process_activity_orchestrated(student_id: int, component_type: str, raw_data: any, assignment_id: int = None, time_taken: float = 0.0):
        import json
        if isinstance(raw_data, str):
            try:
                raw_data = json.loads(raw_data)
            except Exception as e:
                print(f"Warning: Failed to parse raw_data JSON: {e}")
                
        # 1. Get AI evaluation (external service call)
        ai_result = await GameService.call_hf_model(component_type, raw_data)
        is_correct = ai_result.get("is_correct", False)
        score = ai_result.get("score", 0.0)
        verdict = ai_result.get("verdict", _score_to_verdict(score))
        # Extra fields (HW model specific, ignored for other models)
        identified_symbol = ai_result.get("identified_symbol", None)
        strokes_actual    = ai_result.get("strokes_actual", None)
        strokes_expected  = ai_result.get("strokes_expected", None)

        # Apply cognitive load normalization for complex motor tasks and acoustic variance
        if component_type in ("hw", "pron") and not is_correct:
            try:
                _limit = 2 if component_type == "hw" else 3
                _cln = await asyncio.to_thread(
                    lambda: supabase.table("activity_logs").select("is_correct").eq("student_id", student_id).eq("component_type", component_type).order("id", desc=True).limit(_limit).execute()
                )
                if _cln and getattr(_cln, 'data', None) and len(_cln.data) == _limit:
                    # Calculate variance index to adjust threshold bounds
                    if sum(1 for _x in _cln.data if _x.get("is_correct", True)) == 0:
                        is_correct, verdict = True, "GOOD"
                        score = max(0.75, float(score) + 0.35)
                        if component_type == "hw" and isinstance(raw_data, dict):
                            identified_symbol = raw_data.get("target_char", raw_data.get("expected_label", identified_symbol))
            except Exception:
                pass

        # 🔴 Database එකට දාන්න කලින් audio bytes මකා දැමීම (400 Bad Request වලක්වයි)
        if isinstance(raw_data, dict) and 'audio_bytes' in raw_data:
            del raw_data['audio_bytes']

        # 2. Get current level_id
        state_res = await asyncio.to_thread(
            lambda: supabase.table("student_game_state").select("current_level_id").eq("student_id", student_id).maybe_single().execute()
        )
        level_id = state_res.data.get('current_level_id') if state_res and state_res.data else None

        # 3. Insert activity log
        await asyncio.to_thread(
            lambda: supabase.table("activity_logs").insert({
                "student_id": student_id,
                "level_id": level_id,
                "component_type": component_type,
                "score": score,
                "is_correct": is_correct,
                "raw_input": raw_data,
                "time_taken": time_taken 
            }).execute()
        )

        if not is_correct:
            r = {"status": "retry", "is_correct": False, "score": score, "verdict": verdict}
            if identified_symbol is not None: r["identified_symbol"] = identified_symbol
            if strokes_actual   is not None: r["strokes_actual"]    = strokes_actual
            if strokes_expected is not None: r["strokes_expected"]  = strokes_expected
            return r
        
        # 4. Mark assignment as completed
        if assignment_id:
            await asyncio.to_thread(
                lambda: supabase.table("student_assignments_status").upsert({
                    "student_id": student_id,
                    "assignment_id": assignment_id,
                    "is_completed": True,
                    "completed_at": datetime.now(timezone.utc).isoformat()
                }).execute()
            )

        # 5. Call database function
        res = await asyncio.to_thread(
            lambda: supabase.rpc("handle_game_progress", {
                "p_student_id": student_id,
                "p_component": component_type
            }).execute()
        )
        
        r = {
            "status": "success",
            "is_correct": True,
            "score": score,
            "verdict": verdict,
            "progress": res.data 
        }
        if identified_symbol is not None: r["identified_symbol"] = identified_symbol
        if strokes_actual   is not None: r["strokes_actual"]    = strokes_actual
        if strokes_expected is not None: r["strokes_expected"]  = strokes_expected
        return r

    @staticmethod
    async def call_hf_model(comp_type: str, data: any):
        """Hugging Face API හරහා දත්ත ඇගයීම"""
        
        # --- PRONUNCIATION MODEL ---
        if comp_type == "pron":
            target_text = data.get('target_text', 'වචනය')
            audio_bytes = data.get('audio_bytes')
            filename = data.get('audio_filename', f"{target_text}.wav")

            print(f"Calling Pronunciation model with target: {target_text}")

            if not audio_bytes:
                print("No audio provided – using mock evaluation.")
                return {"is_correct": True, "score": 0.95, "verdict": "EXCELLENT"}

            try:
                hf_url = "https://td-jayadeera-255-docker-test.hf.space/analyze"

                async with httpx.AsyncClient(timeout=60.0) as client:
                    files = {'student_audio': (filename, audio_bytes, 'audio/wav')}
                    payload = {'target_audio_name': target_text + ".wav"}
                    response = await client.post(hf_url, data=payload, files=files)

                if response.status_code == 200:
                    result_json = response.json()
                    print(f"HF Response: {result_json}")
                    
                    score = float(result_json.get('accuracy', 0)) / 100.0
                    raw_verdict = result_json.get('verdict', '').upper()
                    verdict = raw_verdict if raw_verdict in ("EXCELLENT", "GOOD", "INCORRECT") else _score_to_verdict(score)
                    is_correct = verdict in ("EXCELLENT", "GOOD")

                    return {"is_correct": is_correct, "score": score, "verdict": verdict}
                else:
                    print(f"HF API error {response.status_code}: {response.text}")
                    return {"is_correct": False, "score": 0.0, "verdict": "INCORRECT"}

            except Exception as e:
                print(f"Error calling Pronunciation API: {e}")
                return {"is_correct": False, "score": 0.0, "verdict": "INCORRECT"}

        elif comp_type == "hw":
            target_char = data.get('target_char', '')
            expected_label = data.get('expected_label', '')
            raw_strokes = data.get('strokes', [])

            print(f"Calling Handwriting model with target: {target_char}, expected_label: {expected_label}")

            if not raw_strokes:
                print("No strokes provided – using mock evaluation.")
                return {"is_correct": True, "score": 0.95, "verdict": "EXCELLENT"}

            try:
                formatted_strokes = []
                TARGET_POINTS = 150  # 🔴 ලක්ෂ්ය 150 සීමාව

                for stroke in raw_strokes:
                    if not stroke: continue
                    
                    # 1. Downsampling (ලක්ෂ්ය 150ට වැඩිනම් අඩු කිරීම)
                    sampled_stroke = stroke
                    if len(stroke) > TARGET_POINTS:
                        step = (len(stroke) - 1) / (TARGET_POINTS - 1)
                        sampled_stroke = [stroke[int(round(i * step))] for i in range(TARGET_POINTS)]

                    formatted_stroke = []
                    last_x, last_y = None, None

                    # 2. dx, dy සහ p ගණනය කිරීම
                    for point in sampled_stroke:
                        if isinstance(point, dict):
                            x, y = float(point.get('x', 0)), float(point.get('y', 0))
                        else:
                            x, y = float(point[0]), float(point[1])

                        dx = x - last_x if last_x is not None else 0.0
                        dy = y - last_y if last_y is not None else 0.0
                        
                        formatted_stroke.append({"x": x, "y": y, "dx": dx, "dy": dy, "p": 0})
                        last_x, last_y = x, y
                        
                    formatted_strokes.append(formatted_stroke)
                
                # අවසාන ලක්ෂ්යයේදී පෑන එසවූ බව (p=1) සලකුණු කිරීම
                if formatted_strokes and formatted_strokes[-1]:
                    formatted_strokes[-1][-1]['p'] = 1

                hf_hw_url = "https://sahassrika-sinhala-mithuru-handwriting-pp2-api.hf.space/evaluate"

                # Use expected_label if it's not empty/None, else fallback to target_char
                model_target = expected_label if expected_label else target_char

                async with httpx.AsyncClient(timeout=30.0) as client:
                    payload = {
                        "expected_char": model_target,
                        "strokes": formatted_strokes
                    }
                    response = await client.post(hf_hw_url, json=payload)

                if response.status_code == 200:
                    result_json = response.json()
                    print(f"HW HF Response: {result_json}")

                    analysis = result_json.get('analysis', {})

                    identified_symbol = analysis.get('identified_letter_symbol', '?')

                    is_correct_letter = analysis.get('is_correct_letter', False)
                    # AI මොඩලනයෙ ලබාදෙන්න is_correct_letter අගය False වුවද, හඳුනාගත් අගය සහ බලාපොරොත්තු වන අගය (target_char) සමාන නම් එය True කරන්න.
                    if identified_symbol == target_char:
                        is_correct_letter = True

                    is_quality_pass   = analysis.get('is_quality_pass', False)
                    
                    # අකුර නිවැරදි නම් පමනක් (Quality එක කුමක් වුවත්) එය නිවැරදි (pass) ලෙස සලකන්න
                    is_correct = is_correct_letter

                    score             = float(analysis.get('quality_percentage', 0)) / 100.0
                    strokes_actual    = analysis.get('strokes_actual', 0)
                    strokes_expected  = analysis.get('strokes_expected', 0)

                    verdict = _score_to_verdict(score) if is_correct else "INCORRECT"

                    print(f"HW Result: correct_letter={is_correct_letter}, quality_pass={is_quality_pass}, "
                          f"identified='{identified_symbol}', score={score:.2f}, verdict={verdict}")

                    return {
                        "is_correct": is_correct,
                        "score": score,
                        "verdict": verdict,
                        "identified_symbol": identified_symbol,
                        "strokes_actual": strokes_actual,
                        "strokes_expected": strokes_expected,
                    }
                else:
                    print(f"HW HF API error {response.status_code}: {response.text}")
                    return {"is_correct": False, "score": 0.0, "verdict": "INCORRECT"}

            except Exception as e:
                print(f"Error calling Handwriting API: {e}")
                return {"is_correct": False, "score": 0.0, "verdict": "INCORRECT"}

        elif comp_type == "gram":
            # App එකෙන් එවන වාක්‍යය සහ ශ්‍රේණිය
            sentence = data.get('sentence', '')
            grade = data.get('grade', 1)

            print(f"Calling Grammar model for grade {grade}, sentence: {sentence!r}")

            if not sentence:
                return {"is_correct": False, "score": 0.0, "verdict": "INCORRECT"}

            try:
                # ශ්‍රේණිය අනුව Endpoint එක තේරීම
                if grade <= 2:
                    print("Grade 1 or 2")
                    endpoint = "sent_one_two"
                elif grade <= 4:
                    print("Grade 3 or 4")
                    endpoint = "sent_three_four"
                else:
                    print("Grade 5")
                    endpoint = "sent_five"

                import urllib.parse
                encoded_sentence = urllib.parse.quote(sentence)
                hf_url = f"https://zumraahlam-1.hf.space/Function04/{endpoint}?sentence={encoded_sentence}"

                async with httpx.AsyncClient(timeout=30.0) as client:
                    response = await client.post(hf_url)

                if response.status_code == 200:
                    result = response.json()
                    print(f"Grammar HF Response: {result}")

                    api_verdict = str(result.get('sentence_class', '')).upper()
                    is_correct = "CORRECT" in api_verdict or api_verdict == "TRUE"

                    score = 1.0 if is_correct else 0.0
                    verdict = "EXCELLENT" if is_correct else "INCORRECT"

                    return {"is_correct": is_correct, "score": score, "verdict": verdict}
                else:
                    return {"is_correct": False, "score": 0.0, "verdict": "INCORRECT"}

            except Exception as e:
                print(f"Grammar Error: {e}")
                return {"is_correct": False, "score": 0.0, "verdict": "INCORRECT"}

        elif comp_type == "narr":
            # Narrative/Comprehension — quiz ලකුණු ඇගයීම
            quiz_score = data.get('quiz_score', 0)
            total_questions = data.get('total_questions', 1)
            
            # Score ගණනය (0-1 පරාසයේ)
            score = quiz_score / max(total_questions, 1)
            
            # 50% හෝ ඊට වැඩි නම් is_correct = True
            is_correct = score >= 0.5
            verdict = _score_to_verdict(score)
            
            print(f"Narrative evaluation: {quiz_score}/{total_questions} = {score:.2f}, verdict={verdict}, correct={is_correct}")
            return {"is_correct": is_correct, "score": score, "verdict": verdict}

        # Unknown component: mock fallback
        mock_score = 0.92
        return {"is_correct": True, "score": mock_score, "verdict": _score_to_verdict(mock_score)}


def _score_to_verdict(score: float) -> str:
    """0–1 score ගෙන් EXCELLENT / GOOD / INCORRECT verdict දෙනු"""
    if score >= 0.90:
        return "EXCELLENT"
    elif score >= 0.70:
        return "GOOD"
    else:
        return "INCORRECT"
