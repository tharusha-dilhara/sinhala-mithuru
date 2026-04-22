from fastapi import APIRouter, Depends, HTTPException, status, Query
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from app.db.supabase import supabase
from app.core.security import hash_password, verify_password, create_access_token
from app.core.config import get_settings
from jose import jwt, JWTError
from pydantic import BaseModel, EmailStr
from typing import List, Optional
import asyncio

router = APIRouter()
settings = get_settings()
security = HTTPBearer()

# --- Admin Auth Models ---
class AdminLogin(BaseModel):
    email: EmailStr
    password: str

class AdminCreate(BaseModel):
    email: EmailStr
    password: str
    name: str

# --- Admin Auth Dependency ---
def get_current_admin(credentials: HTTPAuthorizationCredentials = Depends(security)):
    token = credentials.credentials
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        user_id: str = payload.get("sub")
        role: str = payload.get("role")
        if user_id is None or role != "admin":
            raise HTTPException(status_code=401, detail="Admin access required")
        return {"id": int(user_id), "role": role}
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid admin token")


# ===========================
# ADMIN AUTH ROUTES
# ===========================

@router.post("/login")
def admin_login(data: AdminLogin):
    """Admin login with email and password"""
    res = supabase.table("admins").select("*").eq("email", data.email).maybe_single().execute()
    if not res or not res.data or not verify_password(data.password, res.data["password_hash"]):
        raise HTTPException(status_code=401, detail="Invalid admin credentials")
    token = create_access_token({"sub": str(res.data["id"]), "role": "admin"})
    return {"access_token": token, "token_type": "bearer", "name": res.data.get("name", "Admin")}


@router.post("/create-admin")
def create_admin(data: AdminCreate):
    """Bootstrap: Create the first admin (should be secured in production)"""
    hashed = hash_password(data.password)
    try:
        res = supabase.table("admins").insert({
            "email": data.email,
            "password_hash": hashed,
            "name": data.name
        }).execute()
        return {"status": "success", "message": "Admin created successfully"}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


# ===========================
# SCHOOLS MANAGEMENT
# ===========================

@router.get("/schools")
async def get_all_schools(
    search: Optional[str] = Query(None),
    district: Optional[str] = Query(None),
    current_admin: dict = Depends(get_current_admin)
):
    """Get all schools with teacher and student counts"""
    try:
        query = supabase.table("schools").select(
            "*, teachers(id), classes(id, students(id))"
        )
        if search:
            query = query.ilike("name", f"%{search}%")
        if district:
            query = query.ilike("district", f"%{district}%")
        
        res = await asyncio.to_thread(lambda: query.execute())
        
        schools = []
        for school in (res.data or []):
            teachers = school.get("teachers", []) or []
            classes = school.get("classes", []) or []
            student_count = sum(len(c.get("students", []) or []) for c in classes)
            schools.append({
                "id": school["id"],
                "name": school["name"],
                "district": school.get("district", ""),
                "teacher_count": len(teachers),
                "class_count": len(classes),
                "student_count": student_count,
            })
        return schools
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/schools/{school_id}")
async def delete_school(school_id: int, current_admin: dict = Depends(get_current_admin)):
    """Delete a school (cascades to teachers, classes, students)"""
    try:
        res = await asyncio.to_thread(
            lambda: supabase.table("schools").delete().eq("id", school_id).execute()
        )
        return {"status": "success", "message": "School deleted"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ===========================
# TEACHERS MANAGEMENT
# ===========================

@router.get("/teachers")
async def get_all_teachers(
    school_id: Optional[int] = Query(None),
    search: Optional[str] = Query(None),
    current_admin: dict = Depends(get_current_admin)
):
    """Get all teachers with school info and class counts"""
    try:
        query = supabase.table("teachers").select(
            "id, full_name, email, school_id, schools(name, district), classes(id, class_name, grade, students(id))"
        )
        if school_id:
            query = query.eq("school_id", school_id)
        if search:
            query = query.ilike("full_name", f"%{search}%")
        
        res = await asyncio.to_thread(lambda: query.execute())
        
        teachers = []
        for t in (res.data or []):
            classes = t.get("classes", []) or []
            student_count = sum(len(c.get("students", []) or []) for c in classes)
            school = t.get("schools") or {}
            teachers.append({
                "id": t["id"],
                "full_name": t.get("full_name", ""),
                "email": t.get("email", ""),
                "school_id": t.get("school_id"),
                "school_name": school.get("name", ""),
                "school_district": school.get("district", ""),
                "class_count": len(classes),
                "student_count": student_count,
            })
        return teachers
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/teachers/{teacher_id}")
async def delete_teacher(teacher_id: int, current_admin: dict = Depends(get_current_admin)):
    """Delete a teacher account"""
    try:
        res = await asyncio.to_thread(
            lambda: supabase.table("teachers").delete().eq("id", teacher_id).execute()
        )
        return {"status": "success", "message": "Teacher deleted"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ===========================
# CLASSES MANAGEMENT
# ===========================

@router.get("/classes")
async def get_all_classes(
    school_id: Optional[int] = Query(None),
    teacher_id: Optional[int] = Query(None),
    current_admin: dict = Depends(get_current_admin)
):
    """Get all classes with teacher and student info"""
    try:
        query = supabase.table("classes").select(
            "id, class_name, grade, teacher_id, school_id, teachers(full_name, email), schools(name, district), students(id)"
        )
        if school_id:
            query = query.eq("school_id", school_id)
        if teacher_id:
            query = query.eq("teacher_id", teacher_id)
        
        res = await asyncio.to_thread(lambda: query.execute())
        
        classes = []
        for c in (res.data or []):
            teacher = c.get("teachers") or {}
            school = c.get("schools") or {}
            students = c.get("students", []) or []
            classes.append({
                "id": c["id"],
                "class_name": c.get("class_name", ""),
                "grade": c.get("grade"),
                "teacher_id": c.get("teacher_id"),
                "teacher_name": teacher.get("full_name", ""),
                "teacher_email": teacher.get("email", ""),
                "school_id": c.get("school_id"),
                "school_name": school.get("name", ""),
                "school_district": school.get("district", ""),
                "student_count": len(students),
            })
        return classes
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/classes/{class_id}")
async def delete_class(class_id: int, current_admin: dict = Depends(get_current_admin)):
    """Delete a class"""
    try:
        res = await asyncio.to_thread(
            lambda: supabase.table("classes").delete().eq("id", class_id).execute()
        )
        return {"status": "success", "message": "Class deleted"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ===========================
# STUDENTS MANAGEMENT
# ===========================

@router.get("/students")
async def get_all_students(
    class_id: Optional[int] = Query(None),
    school_id: Optional[int] = Query(None),
    search: Optional[str] = Query(None),
    current_admin: dict = Depends(get_current_admin)
):
    """Get all students with class and school info"""
    try:
        query = supabase.table("students").select(
            "id, name, parent_phone, class_id, classes(class_name, grade, school_id, schools(name, district), teachers(full_name))"
        )
        if class_id:
            query = query.eq("class_id", class_id)
        if search:
            query = query.ilike("name", f"%{search}%")
        
        res = await asyncio.to_thread(lambda: query.execute())
        
        students = []
        for s in (res.data or []):
            cls = s.get("classes") or {}
            school = cls.get("schools") or {}
            teacher = cls.get("teachers") or {}
            
            # Filter by school_id if provided
            if school_id and cls.get("school_id") != school_id:
                continue
            
            students.append({
                "id": s["id"],
                "name": s.get("name", ""),
                "parent_phone": s.get("parent_phone", ""),
                "class_id": s.get("class_id"),
                "class_name": cls.get("class_name", ""),
                "grade": cls.get("grade"),
                "school_name": school.get("name", ""),
                "school_district": school.get("district", ""),
                "teacher_name": teacher.get("full_name", ""),
            })
        return students
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/students/{student_id}")
async def delete_student(student_id: int, current_admin: dict = Depends(get_current_admin)):
    """Delete a student account"""
    try:
        res = await asyncio.to_thread(
            lambda: supabase.table("students").delete().eq("id", student_id).execute()
        )
        return {"status": "success", "message": "Student deleted"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ===========================
# OVERVIEW STATS
# ===========================

@router.get("/overview")
async def get_overview_stats(current_admin: dict = Depends(get_current_admin)):
    """Get high-level dashboard statistics"""
    try:
        schools_res = await asyncio.to_thread(
            lambda: supabase.table("schools").select("id", count="exact").execute()
        )
        teachers_res = await asyncio.to_thread(
            lambda: supabase.table("teachers").select("id", count="exact").execute()
        )
        classes_res = await asyncio.to_thread(
            lambda: supabase.table("classes").select("id", count="exact").execute()
        )
        students_res = await asyncio.to_thread(
            lambda: supabase.table("students").select("id", count="exact").execute()
        )

        return {
            "total_schools": schools_res.count or 0,
            "total_teachers": teachers_res.count or 0,
            "total_classes": classes_res.count or 0,
            "total_students": students_res.count or 0,
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ===========================
# GAME STATE MANAGEMENT
# ===========================

@router.get("/students/{student_id}/game-state")
async def get_student_game_state(student_id: int, current_admin: dict = Depends(get_current_admin)):
    """Get full game state + profile for a student"""
    try:
        # Student basic info with class/school
        student_res = await asyncio.to_thread(
            lambda: supabase.table("students").select(
                "id, name, parent_phone, class_id, classes(class_name, grade, school_id, schools(name, district), teachers(full_name))"
            ).eq("id", student_id).maybe_single().execute()
        )
        if not student_res or not student_res.data:
            raise HTTPException(status_code=404, detail="Student not found")

        student = student_res.data
        cls = student.get("classes") or {}
        school = cls.get("schools") or {}
        teacher = cls.get("teachers") or {}

        # Game state
        state_res = await asyncio.to_thread(
            lambda: supabase.table("student_game_state").select(
                "*, game_levels(id, level_number, grade, default_target_hw, default_target_pron, default_target_gram, default_target_narr)"
            ).eq("student_id", student_id).maybe_single().execute()
        )
        game_state = state_res.data if state_res and state_res.data else None

        # All game levels (for level selector)
        levels_res = await asyncio.to_thread(
            lambda: supabase.table("game_levels").select("id, level_number, grade").order("level_number").execute()
        )
        all_levels = levels_res.data if levels_res and levels_res.data else []

        # Recent activity logs (last 20)
        logs_res = await asyncio.to_thread(
            lambda: supabase.table("activity_logs").select(
                "id, component_type, score, is_correct, time_taken, created_at"
            ).eq("student_id", student_id).order("created_at", desc=True).limit(20).execute()
        )
        activity_logs = logs_res.data if logs_res and logs_res.data else []

        return {
            "student": {
                "id": student["id"],
                "name": student.get("name", ""),
                "parent_phone": student.get("parent_phone", ""),
                "class_name": cls.get("class_name", ""),
                "grade": cls.get("grade"),
                "school_name": school.get("name", ""),
                "school_district": school.get("district", ""),
                "teacher_name": teacher.get("full_name", ""),
            },
            "game_state": game_state,
            "all_levels": all_levels,
            "activity_logs": activity_logs,
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


class LevelUpdateRequest(BaseModel):
    new_level_id: int


@router.put("/students/{student_id}/game-level")
async def update_student_game_level(
    student_id: int,
    data: LevelUpdateRequest,
    current_admin: dict = Depends(get_current_admin)
):
    """
    Admin: Safely update a student's current game level.
    Resets hw/pron/gram/narr counts so the student starts fresh at the new level.
    """
    try:
        # Verify level exists
        level_res = await asyncio.to_thread(
            lambda: supabase.table("game_levels").select("id, level_number, grade")
            .eq("id", data.new_level_id).maybe_single().execute()
        )
        if not level_res or not level_res.data:
            raise HTTPException(status_code=404, detail="Game level not found")

        level_info = level_res.data

        # Verify student exists
        student_res = await asyncio.to_thread(
            lambda: supabase.table("students").select("id, name")
            .eq("id", student_id).maybe_single().execute()
        )
        if not student_res or not student_res.data:
            raise HTTPException(status_code=404, detail="Student not found")

        # Check if game state exists
        state_res = await asyncio.to_thread(
            lambda: supabase.table("student_game_state").select("id")
            .eq("student_id", student_id).maybe_single().execute()
        )

        update_payload = {
            "current_level_id": data.new_level_id,
            "current_hw_count": 0,
            "current_pron_count": 0,
            "current_gram_count": 0,
            "current_narr_count": 0,
        }

        if state_res and state_res.data:
            # Update existing
            await asyncio.to_thread(
                lambda: supabase.table("student_game_state")
                .update(update_payload)
                .eq("student_id", student_id).execute()
            )
        else:
            # Create new game state
            update_payload["student_id"] = student_id
            update_payload["total_score"] = 0.0
            await asyncio.to_thread(
                lambda: supabase.table("student_game_state")
                .insert(update_payload).execute()
            )

        return {
            "status": "success",
            "message": f"Student '{student_res.data['name']}' moved to Level {level_info['level_number']} (Grade {level_info['grade']})",
            "new_level": level_info,
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/game-levels")
async def get_all_game_levels(current_admin: dict = Depends(get_current_admin)):
    """Get all available game levels"""
    try:
        res = await asyncio.to_thread(
            lambda: supabase.table("game_levels").select("*").order("level_number").execute()
        )
        return res.data or []
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
