# Python සැහැල්ලු Version එකක්
FROM python:3.10-slim

# Environment Variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# වැඩ කරන තැන
WORKDIR /app

# Non-root user කෙනෙක් සාදාගැනීම (Security සදහා)
RUN useradd -m -u 1000 appuser

# අවශ්‍ය Libraries install කිරීම
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# කෝඩ් එක Copy කිරීම
COPY . .

# ගොනු වල අයිතිය appuser වෙත පැවරීම
RUN chown -R appuser:appuser /app

# Non-root user වෙත මාරු වීම
USER appuser

# Port එක
EXPOSE 8000

# Server එක Start කිරීම (Workers 2ක් යොදා ඇත - Game එකට වේගවත් වීමට)
# NOTE: Changed main:app to app.main:app because main.py is inside app/ folder in new structure
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "2"]
