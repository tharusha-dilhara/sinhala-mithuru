from fastapi import APIRouter, HTTPException
from app.db.supabase import supabase
from app.models.schemas import SchoolCreate
import asyncio

router = APIRouter()

@router.post("/add")
async def add_school(school: SchoolCreate):
    """පාසලක් එකතු කිරීම (සරල insert)"""
    try:
        res = await asyncio.to_thread(
            lambda: supabase.table("schools").insert({
                "name": school.name,
                "district": school.district
            }).execute()
        )
        return res.data
    except Exception as e:
        print(f"Error: {e}")
        raise HTTPException(status_code=500, detail="Database processing error")

@router.post("/smart-create")
async def smart_create_school(school: SchoolCreate):
    """නව පාසලක් smart ලෙස එකතු කිරීම (duplicate detection සමග)"""
    try:
        # Use the add_smart_school RPC function for fuzzy matching
        result = await asyncio.to_thread(
            lambda: supabase.rpc("add_smart_school", {
                "input_name": school.name,
                "input_district": school.district
            }).execute()
        )
        
        if not result or not result.data:
            raise HTTPException(status_code=500, detail="Failed to process school creation")
        
        data = result.data
        status = data.get('status', 'unknown')
        school_info = data.get('school', {})
        
        return {
            "status": status,  # 'exists' or 'created'
            "message": "පාසල දැනටමත් පවතී" if status == 'exists' else "නව පාසල සාර්ථකව එකතු කරන ලදී",
            "school": school_info
        }
        
    except Exception as e:
        print(f"Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/search")
async def search_schools(name: str = None, district: str = None):
    """පාසල් සෙවීම"""
    try:
        query = supabase.table("schools").select("*")
        
        if name:
            query = query.ilike("name", f"%{name}%")
        if district:
            query = query.ilike("district", f"%{district}%")
        
        res = await asyncio.to_thread(lambda: query.execute())
        return res.data if res and res.data else []
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

