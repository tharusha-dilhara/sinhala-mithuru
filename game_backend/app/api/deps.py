from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import jwt, JWTError
from app.core.config import get_settings

settings = get_settings()

# Swagger UI එකේ 'Authorize' බොත්තම වැඩ කිරීමට මෙය උපකාරී වේ
security = HTTPBearer()

def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)):
    token = credentials.credentials
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="වලංගු නොවන ටෝකන් එකකි (Invalid token)",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        # ටෝකන් එක Decode කර දත්ත ලබා ගැනීම
        payload = jwt.decode(
            (token), 
            settings.SECRET_KEY, 
            algorithms=[settings.ALGORITHM]
        )
        user_id: str = payload.get("sub")
        role: str = payload.get("role")
        
        if user_id is None:
            raise credentials_exception
            
        # FIXED: Convert user_id to int to match database integer fields
        # ටෝකන් එකේ ඇති දත්ත Dictionary එකක් ලෙස ලබා දීම
        return {"id": int(user_id), "role": role}
        
    except JWTError:
        raise credentials_exception


def get_current_student(current_user: dict = Depends(get_current_user)):
    if current_user["role"] != "student":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Valid student credentials required",
        )
    return current_user
