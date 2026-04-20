from pydantic import BaseModel, ConfigDict
from typing import List, Dict, Optional, Any
from app.models.schemas import StudentSignup # Re-use if needed, or define specific

# --- Teacher Dashboard ---

class StudentRank(BaseModel):
    student_id: int
    name: str
    level: int
    total_score: int

class SkillPerformance(BaseModel):
    component_type: str
    average_score: float

class StrugglingStudent(BaseModel):
    id: int
    name: str
    average: float

class TeacherDashboardSummary(BaseModel):
    total_students: int
    class_average_level: float
    assignment_completion_rate: float
    struggling_students: List[StrugglingStudent]
    skill_stats: List[SkillPerformance]

# --- Analytics ---
class LearningCurvePoint(BaseModel):
    day: str
    avg_score: float

class ErrorDetail(BaseModel):
    target: str
    count: int

class ErrorSummary(BaseModel):
    component: str
    failure_count: int
    breakdown: List[ErrorDetail]

class ClassWeakness(BaseModel):
    weak_point: str
    error_frequency: int

class StudentDetailedReport(BaseModel):
    student_name: str
    learning_curve: List[LearningCurvePoint]
    error_summary: List[ErrorSummary]
    attempt_efficiency: float

# --- Bulk Actions ---
class BulkPromotionRequest(BaseModel):
    student_ids: List[int]
    # class_id: Optional[int] # Might be useful to ensure they are in same class

class PatternResetRequest(BaseModel):
    student_id: int
    new_pattern: List[int]

# --- Assignments ---
class AssignmentCreate(BaseModel):
    class_id: int # ADDED: Assignment is for a class
    component_type: str 
    content_id: int
    expiry_hours: Optional[int] = 24

class SmartAssignmentRequest(BaseModel):
    class_id: int # ADDED
    component_type: str
    target_data: str
    expiry_hours: int
    metadata: Optional[Dict[str, Any]] = None

    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "class_id": 1,
                "component_type": "pron",
                "target_data": "අම්මා",
                "expiry_hours": 24,
                "metadata": {
                    "sample_audio_url": "https://storage.googleapis.com/audio/amma.wav",
                    "instructions": "පැහැදිලිව ශබ්ද නගා පවසන්න"
                }
            }
        }
    )

class StudentAssignmentStatus(BaseModel):
    student_name: str
    status: str
    completed_at: Optional[str] = None

class AssignmentDetailedReport(BaseModel):
    assignment_id: int
    target_data: str
    component_type: str
    deadline: str
    total_students: int
    completed_count: int
    missed_count: int
    in_progress_count: int
    insights: List[str]
    student_details: List[StudentAssignmentStatus]

class DeadlineExtensionRequest(BaseModel):
    assignment_id: int
    extension_hours: int

class DifficultItem(BaseModel):
    item_name: str
    failure_count: int
    average_score: float

class ClassDifficultyAnalytics(BaseModel):
    component_type: str
    top_difficult_items: List[DifficultItem]
