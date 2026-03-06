from pydantic import BaseModel, EmailStr, ConfigDict
from typing import List, Optional, Dict, Any

# --- Schools ---
class SchoolCreate(BaseModel):
    name: str
    district: str

# --- Classes (New) ---
class ClassCreate(BaseModel):
    class_name: str
    grade: int
    school_id: int

class ClassResponse(BaseModel):
    id: int
    class_name: str
    grade: int
    teacher_id: int
    school_id: int

# --- Auth / Teachers ---
class TeacherSignup(BaseModel):
    name: str
    email: EmailStr
    password: str
    school_id: int
    # grade: int # Removed as grade is now per class

class TeacherLogin(BaseModel):
    email: EmailStr
    password: str

# --- Auth / Students ---
class StudentSignup(BaseModel):
    name: str
    # teacher_id: int # REMOVED: Student now links to Class
    class_id: int     # ADDED
    # grade: int      # Student grade is derived from Class
    pattern: List[int]
    parent_phone: str

class StudentLogin(BaseModel):
    student_id: int
    pattern: List[int]

class PatternVerify(BaseModel):
    student_id: int
    pattern: List[int]

class StudentProfile(BaseModel):
    id: int
    name: str
    grade: int
    class_name: str
    school_name: str
    pattern: List[int]
    total_score: float = 0.0
    current_level: int = 1



# --- Common ---
class ActivitySubmission(BaseModel):
    component_type: str
    is_correct: bool
    score: float
    metadata: Optional[Dict[str, Any]] = None

class AssignmentCreate(BaseModel):
    class_id: int # ADDED: Assignment is for a class
    component_type: str # 'hw', 'pron', 'gram', 'narr'
    content_id: int
    # expiry_hours: Optional[int] = 24 # Optional if using TeacherSchema version? 
    # Let's keep minimal here for game.py usage or robust for both.
    # teacher_schemas.py has a version too.
    # To avoid conflict, let's define it here cleanly.

class EvaluateRequest(BaseModel):
    raw_input: Dict[str, Any]
    assignment_id: Optional[int] = None
    time_taken: float = 0.0 # New field for analytics

    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "raw_input": {
                    "strokes": [[10, 20], [15, 25]],
                    "target_char": "ආ"
                },
                "assignment_id": 2,
                "time_taken": 12.5
            }
        }
    )
