from fastapi import APIRouter, Depends, HTTPException, status
from app.db.supabase import supabase
from app.models.schemas import StudentProfile
from app.api.deps import get_current_student
from app.services.teacher_service import TeacherService

router = APIRouter()

@router.get("/profile", response_model=StudentProfile)
async def get_student_profile(current_student: dict = Depends(get_current_student)):
    """
    Get the profile of the currently logged-in student.
    Includes data from student, class, school, and game state.
    """
    student_id = current_student["id"]
    
    try:
        # 1. Fetch Student Details with Class and School info
        # We need to join with classes and schools
        # Supabase-py select with nested joins: "*, classes(*, schools(*))"
        
        student_res = supabase.table("students").select(
            "*, classes(class_name, grade, schools(name))"
        ).eq("id", student_id).single().execute()
        
        if not student_res.data:
            raise HTTPException(status_code=404, detail="Student not found")
            
        student_data = student_res.data
        class_data = student_data.get("classes", {})
        school_data = class_data.get("schools", {})
        
        # 2. Fetch Game State for score and level
        game_state_res = supabase.table("student_game_state").select(
            "total_score, current_level_id, game_levels(level_number)"
        ).eq("student_id", student_id).single().execute()
        
        total_score = 0.0
        current_level_num = 1
        
        if game_state_res.data:
            total_score = game_state_res.data.get("total_score", 0.0)
            # Try to get level number from joined game_levels, else fallback or default
            level_data = game_state_res.data.get("game_levels")
            if level_data:
                current_level_num = level_data.get("level_number", 1)
        
        # Construct response
        profile = StudentProfile(
            id=student_data["id"],
            name=student_data["name"],
            grade=class_data.get("grade", 0),
            class_name=class_data.get("class_name", "Unknown"),
            school_name=school_data.get("name", "Unknown"),
            pattern=[], # Cannot return actual pattern as it is hashed
            total_score=total_score,
            current_level=current_level_num
        )
        
        return profile

    except Exception as e:
        print(f"Error fetching profile: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/report")
async def get_my_report(current_student: dict = Depends(get_current_student)):
    """
    Get the detailed performance report for the currently logged-in student.
    """
    try:
        return await TeacherService.get_student_detailed_report(current_student["id"])
    except Exception as e:
        print(f"Error fetching student report: {e}")
        raise HTTPException(status_code=500, detail="වාර්තාව ලබා ගැනීමේදී දෝෂයක් ඇතිවිය.")
