import asyncio
from app.db.supabase import supabase

async def main():
    res = supabase.table("activity_logs").select("student_id").limit(1).execute()
    if res.data:
        student_id = res.data[0]['student_id']
        print(f"Testing with student_id {student_id}")
        prog_res = supabase.rpc("get_student_learning_curve", {"p_student_id": student_id}).execute()
        print("Learning Curve:", prog_res.data)
        
        act_res = supabase.table("activity_logs").select("*").eq("student_id", student_id).limit(2).execute()
        print("Activities:", act_res.data)
    else:
        print("No students found.")

if __name__ == "__main__":
    asyncio.run(main())
