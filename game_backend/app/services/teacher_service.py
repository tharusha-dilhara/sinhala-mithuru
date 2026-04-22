import json
from typing import List, Optional
from app.db.supabase import supabase
from app.core.security import hash_password 
from datetime import datetime, timedelta, timezone
from dateutil import parser as dateutil_parser
import asyncio

from app.models.teacher_schemas import AssignmentCreate, DeadlineExtensionRequest, SmartAssignmentRequest, StudentAssignmentStatus

class TeacherService:
    
    # --- PROMOTED: Class Management ---
    @staticmethod
    async def create_class(teacher_id: int, class_name: str, grade: int, school_id: int):
        res = await asyncio.to_thread(
            lambda: supabase.table("classes").insert({
                "class_name": class_name,
                "grade": grade,
                "teacher_id": teacher_id,
                "school_id": school_id
            }).execute()
        )
        return res.data

    @staticmethod
    async def get_teacher_classes(teacher_id: int):
        res = await asyncio.to_thread(
            lambda: supabase.table("classes").select("*").eq("teacher_id", teacher_id).execute()
        )
        return res.data if res.data else []

    @staticmethod
    async def get_dashboard_summary(teacher_id: int, class_id: Optional[int] = None):
        # 1. Get Classes for Teacher (and filter if class_id provided)
        query = supabase.table("classes").select("*").eq("teacher_id", teacher_id)
        if class_id:
            query = query.eq("id", class_id)
            
        classes_res = await asyncio.to_thread(lambda: query.execute())
        classes = classes_res.data if classes_res.data else []
        class_ids = [c['id'] for c in classes]
        
        if not class_ids:
             return {
                "total_students": 0,
                "class_average_level": 0.0,
                "assignment_completion_rate": 0.0,
                "struggling_students": [],
                "skill_stats": [],
                "recent_activities": []
            }

        # 2. Get Students in those Classes
        res_students = await asyncio.to_thread(
            lambda: supabase.table("students").select("id, name").in_("class_id", class_ids).execute()
        )
        students = res_students.data if res_students.data else []
        student_ids = [s['id'] for s in students]

        total_students = len(students)
        
        if total_students == 0:
            return {
                "total_students": 0,
                "class_average_level": 0.0,
                "assignment_completion_rate": 0.0,
                "struggling_students": [],
                "skill_stats": [],
                "recent_activities": []
            }

        # 3. Get Activities
        logs_res = await asyncio.to_thread(
            lambda: supabase.table("activity_logs") \
                .select("student_id, score, is_correct, component_type, created_at") \
                .in_("student_id", student_ids) \
                .order("created_at", desc=True) \
                .limit(50) \
                .execute()
        )
        
        all_logs = logs_res.data if logs_res.data else []

        # 4. Weak Students Logic
        weak_students = []
        avg_progress = 0

        if all_logs:
            student_scores = {}
            for s in students:
                s_id = s['id']
                s_logs = [l['score'] for l in all_logs if l.get('student_id') == s_id]
                
                if s_logs:
                    avg = sum(s_logs) / len(s_logs)
                    student_scores[s_id] = avg
                    if avg < 0.5: 
                        weak_students.append({
                            "id": s_id,
                            "name": s['name'],
                            "average": round(avg * 100, 1)
                        })
            
            all_scores = [l['score'] for l in all_logs]
            if all_scores:
                avg_progress = (sum(all_scores) / len(all_scores)) * 100

        return {
            "total_students": total_students,
            "class_average_level": round(avg_progress, 1),
            "assignment_completion_rate": 0.0,
            "struggling_students": weak_students,
            "skill_stats": [],
            "recent_activities": all_logs[:10]
        }

    # ... get_student_details is mostly for viewing a specific student, 
    # ensuring they belong to one of the teacher's classes.
    @staticmethod
    async def get_student_details(teacher_id: int, student_id: int):
        # 1. Verify Student-Teacher link via Class
        # Query: Student -> Class -> Teacher
        student_res = await asyncio.to_thread(
            lambda: supabase.table("students") \
                .select("*, classes!inner(teacher_id)") \
                .eq("id", student_id) \
                .eq("classes.teacher_id", teacher_id) \
                .maybe_single().execute()
        )
        
        # Let's try the safer logic:
        # Get student's class_id
        s_check = await asyncio.to_thread(
            lambda: supabase.table("students").select("class_id").eq("id", student_id).maybe_single().execute()
        )
        if not s_check.data: return None
        class_id = s_check.data['class_id']
        
        # Check if class belongs to teacher
        c_check = await asyncio.to_thread(
            lambda: supabase.table("classes").select("id").eq("id", class_id).eq("teacher_id", teacher_id).maybe_single().execute()
        )
        if not c_check.data: return None

        # Now fetch details
        student_info = await asyncio.to_thread(
            lambda: supabase.table("students").select("*").eq("id", student_id).single().execute()
        )
        state_res = await asyncio.to_thread(
            lambda: supabase.table("student_game_state").select("*").eq("student_id", student_id).maybe_single().execute()
        )
        
        history_res = await asyncio.to_thread(
            lambda: supabase.table("activity_logs") \
                .select("*") \
                .eq("student_id", student_id) \
                .order("created_at", desc=True) \
                .limit(20) \
                .execute()
        )

        return {
            "student": student_info.data,
            "game_state": state_res.data,
            "history": history_res.data if history_res.data else []
        }

    @staticmethod
    async def get_leaderboard(teacher_id: int, class_id: Optional[int] = None):
        # Include optional class_id filtering
        
        # Supabase join: FIXED to use current_level_id instead of current_level
        query = supabase.table("students") \
            .select("id, name, student_game_state(current_level_id, total_score), classes!inner(teacher_id)") \
            .eq("classes.teacher_id", teacher_id) \
            .order("total_score", desc=True, foreign_table="student_game_state")
            
        if class_id:
            query = query.eq("class_id", class_id)
            
        res = await asyncio.to_thread(lambda: query.execute())

        leaderboard = []
        for student in res.data:
            game_state = student.get('student_game_state') or {}
            leaderboard.append({
                "student_id": student['id'],
                "name": student['name'],
                "level_id": game_state.get('current_level_id', None),  # Changed from current_level
                "total_score": int(game_state.get('total_score', 0))
            })
            
        return leaderboard

    @staticmethod
    async def get_student_detailed_report(student_id: int):
        """FIXED: Properly join students and student_game_state tables"""
        # Get student basic info
        student_info_res = await asyncio.to_thread(
            lambda: supabase.table("students") \
                .select("id, name, class_id, parent_phone, created_at") \
                .eq("id", student_id).single().execute()
        )
        
        # Get student game state separately (total_score is here, not in students table)
        game_state_res = await asyncio.to_thread(
            lambda: supabase.table("student_game_state") \
                .select("*") \
                .eq("student_id", student_id).maybe_single().execute()
        )

        activity_res = await asyncio.to_thread(
            lambda: supabase.table("activity_logs") \
                .select("*") \
                .eq("student_id", student_id) \
                .order("created_at", desc=True) \
                .limit(20).execute()
        )

        # Fetch all activity logs to calculate daily stats
        all_act_res = await asyncio.to_thread(
            lambda: supabase.table("activity_logs") \
                .select("created_at, is_correct, component_type, raw_input") \
                .eq("student_id", student_id) \
                .execute()
        )

        # Error Summary (component, {failure_count: int, details: dict(target -> count)})
        error_summary_dict = {}
        total_attempts = 0
        correct_attempts = 0

        if all_act_res.data:
            import json
            for act in all_act_res.data:
                total_attempts += 1
                comp = act.get('component_type', 'Unknown')
                if comp not in error_summary_dict:
                    error_summary_dict[comp] = {"count": 0, "details": {}}
                    
                if act.get('is_correct'):
                    correct_attempts += 1
                else:
                    error_summary_dict[comp]["count"] += 1
                    
                    raw_str = act.get('raw_input')
                    target = "Unknown Detail"
                    if raw_str:
                        if isinstance(raw_str, str):
                            try:
                                raw_data = json.loads(raw_str)
                            except:
                                raw_data = {}
                        elif isinstance(raw_str, dict):
                            raw_data = raw_str
                        else:
                            raw_data = {}
                            
                        if comp == "pron":
                            target = raw_data.get('target_text', target)
                        elif comp == "hw":
                            target = raw_data.get('expected_label', raw_data.get('target_char', target))
                        elif comp == "gram":
                            target = raw_data.get('sentence', target)
                        elif comp == "narr":
                            target = "Comprehension Quiz"
                    
                    error_summary_dict[comp]["details"][target] = error_summary_dict[comp]["details"].get(target, 0) + 1
                    
        error_summary_list = []
        for comp, data in error_summary_dict.items():
            if data["count"] > 0:
                # convert details dict to sorted list of ErrorDetail dicts
                breakdown = [{"target": t, "count": c} for t, c in sorted(data["details"].items(), key=lambda x: x[1], reverse=True)]
                error_summary_list.append({"component": comp, "failure_count": data["count"], "breakdown": breakdown})
        attempt_efficiency = (correct_attempts / total_attempts) if total_attempts > 0 else 0.0

        progress_res = await asyncio.to_thread(
            lambda: supabase.rpc("get_student_learning_curve", {"p_student_id": student_id}).execute()
        )
        learning_curve_raw = progress_res.data if progress_res.data else []
        
        # Ensure learning curve has 'day' and 'avg_score' keys required by Dart model
        learning_curve = []
        for point in learning_curve_raw:
            learning_curve.append({
                "day": point.get('date', point.get('day', '')),
                "avg_score": point.get('average_score', point.get('avg_score', 0.0))
            })

        # Group and calculate daily stats
        # daily_stats: [{"date": "2024-03-01", "total": x, "correct": y, "incorrect": z, "percentage": p}]
        daily_stats_dict = {}
        for act in all_act_res.data:
            created_at_str = act.get('created_at', '')
            if len(created_at_str) >= 10:
                date_key = created_at_str[:10]
            else:
                date_key = "Unknown Date"
                
            if date_key not in daily_stats_dict:
                daily_stats_dict[date_key] = {"total": 0, "correct": 0, "incorrect": 0}
                
            daily_stats_dict[date_key]["total"] += 1
            if act.get('is_correct'):
                daily_stats_dict[date_key]["correct"] += 1
            else:
                daily_stats_dict[date_key]["incorrect"] += 1

        daily_stats = []
        for date_val, stats in sorted(daily_stats_dict.items(), reverse=True):
            pct = (stats["correct"] / stats["total"] * 100) if stats["total"] > 0 else 0
            daily_stats.append({
                "date": date_val,
                "total": stats["total"],
                "correct": stats["correct"],
                "incorrect": stats["incorrect"],
                "percentage": pct
            })

        return {
            "student_name": student_info_res.data.get('name', 'Unknown') if student_info_res.data else 'Unknown',
            "learning_curve": learning_curve,
            "error_summary": error_summary_list,
            "attempt_efficiency": attempt_efficiency,
            "recent_activities": activity_res.data if activity_res.data else [],
            "daily_stats": daily_stats
        }

    @staticmethod
    async def get_class_error_hotspots(teacher_id: int, class_id: Optional[int] = None):
        # Get all students for teacher, filtered by class_id if present
        query = supabase.table("classes").select("id").eq("teacher_id", teacher_id)
        if class_id:
            query = query.eq("id", class_id)
            
        classes_res = await asyncio.to_thread(lambda: query.execute())
        class_ids = [c['id'] for c in classes_res.data]
        
        if not class_ids: return []
        
        students_res = await asyncio.to_thread(
            lambda: supabase.table("students").select("id").in_("class_id", class_ids).execute()
        )
        student_ids = [s['id'] for s in students_res.data]
        
        if not student_ids: return []

        res = await asyncio.to_thread(
            lambda: supabase.table("activity_logs") \
                .select("component_type, raw_input") \
                .in_("student_id", student_ids) \
                .eq("is_correct", False) \
                .execute()
        )
        return res.data

    @staticmethod
    async def get_student_detailed_analytics(student_id: int):
        """Use database RPC function for learning curve analytics"""
        student_res = await asyncio.to_thread(
            lambda: supabase.table("students").select("name").eq("id", student_id).single().execute()
        )
        
        # Use the new RPC function get_student_learning_curve
        curve_res = await asyncio.to_thread(
            lambda: supabase.rpc("get_student_learning_curve", {"p_student_id": student_id}).execute()
        )
        
        return {
            "student_name": student_res.data['name'] if student_res and student_res.data else "Unknown",
            "learning_curve": curve_res.data if curve_res and curve_res.data else []
        }

    @staticmethod
    async def get_class_weakness_report(teacher_id: int, class_id: Optional[int] = None):
        """Use database RPC function for class weakness analysis"""
        # If class_id provided, use it directly; otherwise get all teacher's classes
        if class_id:
            class_ids = [class_id]
        else:
            # Get all classes for this teacher
            classes_res = await asyncio.to_thread(
                lambda: supabase.table("classes").select("id").eq("teacher_id", teacher_id).execute()
            )
            class_ids = [c['id'] for c in classes_res.data] if classes_res and classes_res.data else []
        
        if not class_ids:
            return {"weaknesses": []}
        
        # Call RPC for each class and aggregate
        all_weaknesses = []
        for cid in class_ids:
            weakness_res = await asyncio.to_thread(
                lambda: supabase.rpc("get_class_weaknesses", {"p_class_id": cid}).execute()
            )
            if weakness_res and weakness_res.data:
                all_weaknesses.extend(weakness_res.data)
        
        # Aggregate by component_type
        component_totals = {}
        for w in all_weaknesses:
            comp = w.get('component', 'unknown')
            count = w.get('error_count', 0)
            component_totals[comp] = component_totals.get(comp, 0) + count
        
        return {
            "weaknesses": [{
                "component": comp,
                "error_count": count
            } for comp, count in sorted(component_totals.items(), key=lambda x: x[1], reverse=True)]
        }

    @staticmethod
    async def bulk_promote_students(student_ids: List[int]):
        """Promote students to next level in their grade - uses grade-based structure"""
        updated_students = []
        
        for student_id in student_ids:
            # Get current level info
            state_res = await asyncio.to_thread(
                lambda: supabase.table("student_game_state") \
                    .select("current_level_id").eq("student_id", student_id).single().execute()
            )
            
            if not state_res or not state_res.data:
                continue
            
            current_level_id = state_res.data.get('current_level_id')
            
            # Get current level's grade and level_number
            level_res = await asyncio.to_thread(
                lambda: supabase.table("game_levels") \
                    .select("grade, level_number").eq("id", current_level_id).single().execute()
            )
            
            if not level_res or not level_res.data:
                continue
            
            grade = level_res.data.get('grade')
            level_number = level_res.data.get('level_number')
            
            # Find next level in same grade
            next_level_res = await asyncio.to_thread(
                lambda: supabase.table("game_levels") \
                    .select("id").eq("grade", grade).eq("level_number", level_number + 1) \
                    .maybe_single().execute()
            )
            
            if next_level_res and next_level_res.data:
                next_level_id = next_level_res.data.get('id')
                
                # Update student state to next level
                await asyncio.to_thread(
                    lambda: supabase.table("student_game_state").update({
                        "current_level_id": next_level_id,
                        "current_pron_count": 0,
                        "current_hw_count": 0,
                        "current_gram_count": 0,
                        "current_narr_count": 0,
                        "last_updated": datetime.now(timezone.utc).isoformat()
                    }).eq("student_id", student_id).execute()
                )
                
                updated_students.append(student_id)
        
        return {
            "promoted_count": len(updated_students),
            "promoted_students": updated_students
        }

    @staticmethod
    async def reset_student_pattern(student_id: int, new_pattern: List[int]):
        pattern_str = json.dumps(new_pattern)
        hashed_pattern = hash_password(pattern_str)
        res = await asyncio.to_thread(
            lambda: supabase.table("students") \
                .update({"visual_pattern": hashed_pattern}) \
                .eq("id", student_id) \
                .execute()
        )
        return {"status": "success", "message": "රූප රටාව සාර්ථකව වෙනස් කරන ලදී."}

    @staticmethod
    async def create_smart_assignment(teacher_id: int, data: SmartAssignmentRequest):
        """Create assignment - FIXED to use class_assignments table and correct schema"""
        table_map = {
            "hw": "content_handwriting",
            "pron": "content_pronunciation",
            "gram": "content_grammar",
            "narr": "content_narrative"
        }
        target_table = table_map.get(data.component_type)
        
        # FIXED: Removed teacher_id - content tables don't have this column
        content_payload = {
            "level_id": 1 
        }
        
        if data.component_type == "hw":
            content_payload["target_char"] = data.target_data
        elif data.component_type == "pron":
            content_payload["target_text"] = data.target_data
            content_payload["audio_url"] = "https://example.com/audio/placeholder.mp3"  # Required field

        content_res = await asyncio.to_thread(
            lambda: supabase.table(target_table).insert(content_payload).execute()
        )
        new_content_id = content_res.data[0]['id']

        # FIXED: Use class_assignments table with correct schema
        start_date = datetime.now(timezone.utc)
        end_date = start_date + timedelta(hours=data.expiry_hours)
        
        assignment_res = await asyncio.to_thread(
            lambda: supabase.table("class_assignments").insert({
                "class_id": data.class_id,
                "component_type": data.component_type,
                "level_id": 1,
                "start_date": start_date.isoformat(),
                "end_date": end_date.isoformat(),
                "created_by": teacher_id
            }).execute()
        )
        
        return {
            "assignment_id": assignment_res.data[0]['id'],
            "content_id": new_content_id,
            "message": f"'{data.target_data}' සඳහා වන පැවරුම සාර්ථකයි."
        }

    @staticmethod
    async def get_assignment_performance_report(teacher_id: int, assignment_id: int):
        """FIXED: Use class_assignments and student_assignment_progress tables"""
        assign_res = await asyncio.to_thread(
            lambda: supabase.table("class_assignments").select("*").eq("id", assignment_id).maybe_single().execute()
        )
        if not assign_res.data: return None
        assignment = assign_res.data
        
        # DEBUG: Print types and values
        print(f"[DEBUG] Assignment created_by: {assignment.get('created_by')} (type: {type(assignment.get('created_by'))})")
        print(f"[DEBUG] Teacher ID: {teacher_id} (type: {type(teacher_id)})")
        print(f"[DEBUG] Match: {assignment.get('created_by') == teacher_id}")
        
        # Verify teacher owns this assignment via created_by
        if assignment.get('created_by') != teacher_id: return None

        # FIXED: Use robust datetime parsing
        end_date = dateutil_parser.parse(assignment['end_date'])
        now = datetime.now(timezone.utc)

        # Get students in the assigned CLASS
        class_id = assignment.get('class_id')
        students_res = await asyncio.to_thread(
            lambda: supabase.table("students").select("id, name").eq("class_id", class_id).execute()
        )
        all_students = students_res.data
        
        # FIXED: Use student_assignment_progress table
        status_res = await asyncio.to_thread(
            lambda: supabase.table("student_assignment_progress").select("*").eq("assignment_id", assignment_id).execute()
        )
        completion_map = {s['student_id']: s for s in status_res.data}

        report_details = []
        comp_count, missed_count, in_prog_count = 0, 0, 0

        for student in all_students:
            s_id = student['id']
            status_entry = completion_map.get(s_id)
            s_status = "In-Progress"
            comp_time = None

            if status_entry and status_entry['is_completed']:
                s_status = "Completed"
                comp_time = status_entry['completed_at']
                comp_count += 1
            elif now > end_date:
                s_status = "Missed"
                missed_count += 1
            else:
                in_prog_count += 1

            report_details.append(StudentAssignmentStatus(
                student_name=student['name'],
                status=s_status,
                completed_at=comp_time
            ))

        insights = []
        total = len(all_students)
        if total > 0:
            missed_percentage = (missed_count / total) * 100
            if missed_percentage > 50:
                insights.append("⚠️ මෙම පැවරුම සඳහා ලබා දී ඇති කාලය ප්‍රමාණවත් නොවන බව පෙනේ (Missed > 50%).")
            if comp_count == total:
                insights.append("🌟 විශිෂ්ටයි! පන්තියේ සියලු දෙනාම නියමිත කාලය තුළ පැවරුම නිම කර ඇත.")

        return {
            "assignment_id": assignment_id,
            "component_type": assignment['component_type'],
            "end_date": assignment['end_date'],
            "total_students": total,
            "completed_count": comp_count,
            "missed_count": missed_count,
            "in_progress_count": in_prog_count,
            "insights": insights,
            "student_details": report_details
        }

    @staticmethod
    async def extend_assignment_deadline(teacher_id: int, data: DeadlineExtensionRequest):
        """FIXED: Use class_assignments table and end_date column"""
        assign_res = await asyncio.to_thread(
            lambda: supabase.table("class_assignments") \
                .select("end_date, created_by") \
                .eq("id", data.assignment_id) \
                .eq("created_by", teacher_id) \
                .single().execute()
        )
            
        if not assign_res.data:
            return {"status": "error", "message": "පැවරුම සොයාගත නොහැක."}

        # FIXED: Use robust datetime parsing  
        current_deadline = dateutil_parser.parse(assign_res.data['end_date'])
        now = datetime.now(timezone.utc)
        
        base_time = max(current_deadline, now)
        new_deadline = base_time + timedelta(hours=data.extension_hours)

        res = await asyncio.to_thread(
            lambda: supabase.table("class_assignments") \
                .update({
                    "end_date": new_deadline.isoformat()
                }) \
                .eq("id", data.assignment_id) \
                .execute()
        )
            
        return {
            "status": "success", 
            "new_deadline": new_deadline.isoformat(),
            "message": f"කාලය සාර්ථකව පැය {data.extension_hours} කින් දීර්ඝ කරන ලදී."
        }

    @staticmethod
    async def get_most_difficult_items(teacher_id: int, component_type: str, class_id: Optional[int] = None):
        # 1. Get students via classes (filtered by class_id)
        query = supabase.table("classes").select("id").eq("teacher_id", teacher_id)
        if class_id:
            query = query.eq("id", class_id)
            
        classes_res = await asyncio.to_thread(lambda: query.execute())
        class_ids = [c['id'] for c in classes_res.data]
        if not class_ids: return {"component_type": component_type, "top_difficult_items": []}
        
        students_res = await asyncio.to_thread(
            lambda: supabase.table("students").select("id").in_("class_id", class_ids).execute()
        )
        student_ids = [s['id'] for s in students_res.data]
        
        if not student_ids:
            return {"component_type": component_type, "top_difficult_items": []}

        logs_res = await asyncio.to_thread(
            lambda: supabase.table("activity_logs") \
                .select("raw_input, score, is_correct") \
                .in_("student_id", student_ids) \
                .eq("component_type", component_type) \
                .execute()
        )

        analytics_map = {} 

        for log in logs_res.data:
            raw = log['raw_input']
            if not raw: continue
            item = raw.get('target_char') or raw.get('target_text') or "Unknown"
            
            if item not in analytics_map:
                analytics_map[item] = {"scores": [], "failures": 0}
            
            analytics_map[item]["scores"].append(log['score'])
            if not log['is_correct']:
                analytics_map[item]["failures"] += 1

        difficult_items = []
        for item, stats in analytics_map.items():
            avg_score = sum(stats["scores"]) / len(stats["scores"])
            difficult_items.append({
                "item_name": item,
                "failure_count": stats["failures"],
                "average_score": round(avg_score, 2)
            })

        sorted_items = sorted(difficult_items, key=lambda x: x['average_score'])[:10]

        return {
            "component_type": component_type,
            "top_difficult_items": sorted_items
        }
