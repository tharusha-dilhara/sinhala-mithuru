# සැහැල්ලු Python පරිසරයක් තෝරා ගැනීම
FROM python:3.10-slim

# වැඩ කරන ෆෝල්ඩරය සැකසීම
WORKDIR /app

# අවශ්‍ය Libraries ස්ථාපනය
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# කේතය සහ මොඩල පිටපත් කිරීම
COPY . .

# API එක ක්‍රියාත්මක කිරීම (Port 8000)
EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]