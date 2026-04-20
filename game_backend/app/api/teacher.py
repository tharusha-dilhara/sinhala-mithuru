from fastapi import APIRouter, Depends, HTTPException, Query
from app.api.deps import get_current_user
from app.models.teacher_schemas import AssignmentCreate, AssignmentDetailedReport, BulkPromotionRequest, ClassDifficultyAnalytics, DeadlineExtensionRequest, PatternResetRequest, SmartAssignmentRequest, StudentDetailedReport
from app.models.schemas import ClassCreate, ClassResponse
from app.services.teacher_service import TeacherService
from typing import List, Optional

router = APIRouter()

# --- Classes Management ---
@router.post("/classes", response_model=List[ClassResponse])
async def create_class(data: ClassCreate, current_user: dict = Depends(get_current_user)):
    if current_user["role"] != "teacher":
        raise HTTPException(status_code=403, detail="ගුරුවරුන්ට පමණක් අවසර ඇත.")
    
    # Using ClassCreate, but ignoring school_id passed from front if we want to secure it? 
    # Or assuming front sends correct school_id. 
    # Ideally should check if teacher belongs to that school.
    # For now, pass to service.
    
    # Force teacher_id from token
    return await TeacherService.create_class(current_user["id"], data.class_name, data.grade, data.school_id)

@router.get("/classes", response_model=List[ClassResponse])
async def get_my_classes(current_user: dict = Depends(get_current_user)):
    if current_user["role"] != "teacher":
        raise HTTPException(status_code=403, detail="ගුරුවරුන්ට පමණක් අවසර ඇත.")
    return await TeacherService.get_teacher_classes(current_user["id"])

# --- Dashboard ---
@router.get("/summary")
async def dashboard_summary(
    class_id: Optional[int] = Query(None, description="Optional class_id to filter summary"),
    current_user: dict = Depends(get_current_user)
):
    if current_user["role"] != "teacher":
        raise HTTPException(status_code=403, detail="ගුරුවරුන්ට පමණක් අවසර ඇත.")
    return await TeacherService.get_dashboard_summary(current_user["id"], class_id)

@router.get("/leaderboard")
async def class_leaderboard(
    class_id: Optional[int] = Query(None, description="Optional class_id to filter leaderboard"),
    current_user: dict = Depends(get_current_user)
):
    if current_user["role"] != "teacher":
        raise HTTPException(status_code=403, detail="ගුරුවරුන්ට පමණක් අවසර ඇත.")
    return await TeacherService.get_leaderboard(current_user["id"], class_id)

@router.get("/student/{student_id}/report", response_model=StudentDetailedReport)
async def student_detail_report(student_id: int, current_user: dict = Depends(get_current_user)):
    """ශිෂ්‍යයෙකු පිළිබඳ ගැඹුරු පර්යේෂණාත්මක වාර්තාවක් ලබා දීම"""
    if current_user["role"] != "teacher":
        raise HTTPException(status_code=403, detail="අවසර නැත")
    return await TeacherService.get_student_detailed_report(student_id)

@router.get("/class/weaknesses")
async def class_weaknesses(
    class_id: Optional[int] = Query(None, description="Optional class_id"),
    current_user: dict = Depends(get_current_user)
):
    """පන්තියේ සියලු දරුවන් වැඩිපුරම වරද්දන අකුරු/වචන පෙන්වීම"""
    return await TeacherService.get_class_error_hotspots(current_user["id"], class_id)

@router.get("/analytics/student/{student_id}")
async def get_student_report(student_id: int, current_user: dict = Depends(get_current_user)):
    """ශිෂ්‍යයෙකුගේ ප්‍රගති ප්‍රස්තාරය සහ වැරදීම් විශ්ලේෂණය ලබා දෙන API එක"""
    if current_user["role"] != "teacher":
        raise HTTPException(status_code=403, detail="ගුරුවරුන්ට පමණක් අවසර ඇත.")
    
    return await TeacherService.get_student_detailed_analytics(student_id)

@router.get("/analytics/class-hotspots")
async def get_hotspots(
    class_id: Optional[int] = Query(None, description="Optional class_id"),
    current_user: dict = Depends(get_current_user)
):
    """පන්තියේ පොදු දුර්වලතා හඳුනා ගන්නා API එක"""
    if current_user["role"] != "teacher":
        raise HTTPException(status_code=403, detail="ගුරුවරුන්ට පමණක් අවසර ඇත.")
    
    return await TeacherService.get_class_weakness_report(current_user["id"], class_id)

@router.post("/bulk-promote")
async def promote_students(data: BulkPromotionRequest, current_user: dict = Depends(get_current_user)):
    """පන්තියේ තෝරාගත් සිසුන් පිරිසක් මීළඟ ලෙවල් එකට යැවීම"""
    if current_user["role"] != "teacher": #
        raise HTTPException(status_code=403, detail="මෙය සිදු කිරීමට ගුරුවරුන්ට පමණක් අවසර ඇත.")
    
    return await TeacherService.bulk_promote_students(data.student_ids)

@router.post("/reset-pattern")
async def reset_pattern(data: PatternResetRequest, current_user: dict = Depends(get_current_user)):
    """දරුවෙකුගේ Login Pattern එක අමතක වූ විට එය නැවත සැකසීම"""
    if current_user["role"] != "teacher": #
        raise HTTPException(status_code=403, detail="මෙය සිදු කිරීමට ගුරුවරුන්ට පමණක් අවසර ඇත.")
    
    return await TeacherService.reset_student_pattern(data.student_id, data.new_pattern)

@router.post("/smart-assign")
async def smart_assignment(
    data: SmartAssignmentRequest, 
    current_user: dict = Depends(get_current_user)
):
    """
    ගුරුවරයාට සෘජුවම වචනයක් ලබා දී පැවරුමක් දීමට හැකි API එක.
    """
    # ආරක්ෂාව පරීක්ෂාව
    if current_user["role"] != "teacher":
        raise HTTPException(status_code=403, detail="ගුරුවරුන්ට පමණක් අවසර ඇත.")
    
    # සේවාව ක්‍රියාත්මක කිරීම
    return await TeacherService.create_smart_assignment(
        current_user["id"], 
        data
    )

@router.get("/assignment-report/{assignment_id}", response_model=AssignmentDetailedReport)
async def get_assignment_report(
    assignment_id: int, 
    current_user: dict = Depends(get_current_user)
):
    """ගුරුවරයාට ලබා දුන් පැවරුමක සම්පූර්ණ කාර්යසාධන වාර්තාව ලබා දෙන API එක"""
    
    if current_user["role"] != "teacher":
        raise HTTPException(status_code=403, detail="අවසර නැත.")
    
    result = await TeacherService.get_assignment_performance_report(
        current_user["id"], 
        assignment_id
    )
    
    # FIXED: Handle None response properly
    if result is None:
        raise HTTPException(status_code=404, detail="පැවරුම සොයාගත නොහැක හෝ ප්‍රවේශය නැත.")
    
    return result

@router.post("/extend-deadline")
async def extend_deadline(
    data: DeadlineExtensionRequest, 
    current_user: dict = Depends(get_current_user)
):
    """පැවරුමක කාලය දීර්ඝ කරන API එක"""
    if current_user["role"] != "teacher":
        raise HTTPException(status_code=403, detail="ගුරුවරුන්ට පමණක් අවසර ඇත.")
    
    return await TeacherService.extend_assignment_deadline(
        current_user["id"], 
        data
    )


@router.get("/analytics/difficult-items", response_model=ClassDifficultyAnalytics)
async def get_class_difficulty(
    component: str = Query(..., description="hw හෝ pron"), 
    class_id: Optional[int] = Query(None, description="Optional class_id"),
    current_user: dict = Depends(get_current_user)
):
    """පන්තියේ අමාරුම අකුරු/වචන පිළිබඳ සාරාංශය ලබා දෙන API එක"""
    if current_user["role"] != "teacher":
        raise HTTPException(status_code=403, detail="අවසර නැත.")
    
    return await TeacherService.get_most_difficult_items(
        current_user["id"], 
        component,
        class_id
    )
