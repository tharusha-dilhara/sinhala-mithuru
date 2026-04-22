import asyncio
from fastapi import APIRouter, HTTPException, status
from app.db.supabase import supabase
from app.core.security import hash_password, verify_password, create_access_token
from app.models.schemas import TeacherSignup, TeacherLogin, StudentSignup, PatternVerify
import json

router = APIRouter()

@router.post("/teacher/signup")
def signup_teacher(data: TeacherSignup):
    hashed = hash_password(data.password)
    try:
        res = supabase.table("teachers").insert({
            "full_name": data.name,
            "email": data.email,
            "password_hash": hashed,
            "school_id": data.school_id
            # "grade": data.grade # Removed as per new schema
        }).execute()
        return {"status": "success", "message": "Teacher created"}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/teacher/login")
def login_teacher(data: TeacherLogin):
    res = supabase.table("teachers").select("*").eq("email", data.email).maybe_single().execute()
    
    if not res or not res.data or not verify_password(data.password, res.data["password_hash"]):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    
    token = create_access_token({"sub": str(res.data["id"]), "role": "teacher"})
    return {"access_token": token, "token_type": "bearer"}

@router.post("/student/signup")
def signup_student(data: StudentSignup):
    try:
        pattern_str = json.dumps(data.pattern)
        hashed_pattern = hash_password(pattern_str)
        # Verify class exists first? Supabase will throw FK error if not. 
        # Rely on DB verification for now.
        
        res = supabase.table("students").insert({
            "name": data.name,
            # "teacher_id": data.teacher_id, # REMOVED
            "class_id": data.class_id,       # ADDED
            # "grade": data.grade,           # REMOVED
            "visual_pattern": hashed_pattern,
            "parent_phone": data.parent_phone
        }).execute()
        return {"status": "success", "student_id": res.data[0]['id']}
    except Exception as e:
        # Better error handling for FK constraint?
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/parent/students/{phone_number}")
def get_students_by_parent(phone_number: str):
    # දුරකථන අංකයට අදාළ දරුවන්ගේ නම සහ ID පමණක් ලබා ගැනීම
    # New query: join students -> classes -> teachers
    res = supabase.table("students") \
        .select("id, name, classes(id, class_name, grade, teachers(full_name))") \
        .eq("parent_phone", phone_number) \
        .execute()
    
    if not res.data:
        raise HTTPException(status_code=404, detail="මෙම අංකය යටතේ සිසුන් ලියාපදිංචි වී නැත.")
        
    # Simplify response for frontend if needed, or send nested structure
    return res.data

@router.post("/student/verify-pattern")
async def verify_student(data: PatternVerify): 
    res = await asyncio.to_thread(
        lambda: supabase.table("students") \
            .select("visual_pattern") \
            .eq("id", data.student_id) \
            .maybe_single() \
            .execute()
    )
    
    pattern_str = json.dumps(data.pattern)
    
    if not res.data or not verify_password(pattern_str, res.data["visual_pattern"]):
        raise HTTPException(status_code=401, detail="රූප රටාව වැරදියි.")
        
    token = create_access_token({"sub": str(data.student_id), "role": "student"})
    return {"access_token": token, "status": "success"}


@router.get("/teacher/search")
def search_teachers(name: str): 
    # grade param removed from search because teachers don't have grade now.
    # We return classes so parent can filter by grade there.
    
    query = supabase.table("teachers") \
        .select("id, full_name, schools(name, district), classes(id, class_name, grade)") \
        .ilike("full_name", f"%{name}%") 

    res = query.execute()
    
    if not res.data:
        return [] 
        
    return res.data
