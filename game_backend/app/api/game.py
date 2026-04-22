from fastapi import APIRouter, Depends, HTTPException, Query, UploadFile, File, Form
import asyncio
import json
import traceback
from app.api.deps import get_current_user 
from app.db.supabase import supabase
from app.models.schemas import ActivitySubmission, AssignmentCreate
from app.services.game_service import GameService

router = APIRouter()

@router.get("/next-task")
async def get_next_task(current_user: dict = Depends(get_current_user)):
    """දරුවා ලොග් වූ පසු මුලින්ම Call කළ යුතු API එක"""
    return await GameService.get_next_task(current_user["id"])

@router.post("/evaluate")
async def evaluate_and_update(
    component: str = Query(..., description="අදාළ අංශය (hw, pron, gram, narr)"),
    time_taken: float = Form(...),
    raw_input: str = Form(...),          # Flutter එකෙන් JSON string ලෙස එයි
    assignment_id: int = Form(None),
    audio_file: UploadFile = File(None), # .wav ෆයිල් (optional)
    current_user: dict = Depends(get_current_user)
):
    try:
        # JSON string → dict
        raw_data = json.loads(raw_input)

        # Audio file ලැබුනොත් bytes ආකාරයෙන් raw_data එකට inject කිරීම
        if audio_file:
            audio_bytes = await audio_file.read()
            raw_data['audio_bytes'] = audio_bytes
            raw_data['audio_filename'] = audio_file.filename

        return await GameService.process_activity_orchestrated(
            student_id=current_user["id"],
            component_type=component,
            raw_data=raw_data,
            assignment_id=assignment_id,
            time_taken=time_taken
        )
    except json.JSONDecodeError as e:
        raise HTTPException(status_code=422, detail=f"raw_input JSON error: {e}")
    except Exception as e:
        print("----- ERROR IN EVALUATE API -----")
        traceback.print_exc() 
        print("---------------------------------")
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/submit-activity")
async def submit(data: ActivitySubmission, current_user: dict = Depends(get_current_user)):
    return await GameService.process_activity(current_user["id"], data)

@router.post("/teacher/create-assignment")
async def create_assignment(data: AssignmentCreate, current_user: dict = Depends(get_current_user)):
    if current_user["role"] != "teacher":
        raise HTTPException(status_code=403, detail="අවසර නැත")
    
    from datetime import datetime, timedelta, timezone
    start_date = datetime.now(timezone.utc)
    end_date = start_date + timedelta(days=7) 
    
    res = await asyncio.to_thread(
        lambda: supabase.table("class_assignments").insert({
            "class_id": data.class_id,
            "component_type": data.component_type,
            "level_id": 1,
            "start_date": start_date.isoformat(),
            "end_date": end_date.isoformat(),
            "created_by": current_user["id"]
        }).execute()
    )
    
    return {"status": "assignment_created", "assignment_id": res.data[0]['id']}


