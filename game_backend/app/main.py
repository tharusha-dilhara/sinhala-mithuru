from fastapi import FastAPI
from app.api import auth, school, game, teacher,student
from fastapi.middleware.cors import CORSMiddleware


app = FastAPI(title="Sinhala Mithuru API")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Router සම්බන්ධ කිරීම
app.include_router(auth.router, prefix="/auth", tags=["Auth"])
app.include_router(school.router, prefix="/school", tags=["School"])
app.include_router(game.router, prefix="/game", tags=["Game"])
app.include_router(teacher.router, prefix="/teacher", tags=["Teacher Dashboard"])
app.include_router(student.router, prefix="/student", tags=["Student"])


@app.get("/")
async def root():
    return {"status": "running", "project": "Sinhala Mithuru Re-Build"}
