# 1. සැහැල්ලු Python පරිසරයක් භාවිතා කිරීම
FROM python:3.10-slim

# 2. Hugging Face සඳහා අවශ්‍ය පරිශීලකයා සෑදීම
RUN useradd -m -u 1000 user
USER user
ENV PATH="/home/user/.local/bin:${PATH}"

# 3. වැඩ කරන ෆෝල්ඩරය සැකසීම
WORKDIR /app

# 4. Requirements පමණක් පළමුව පිටපත් කිරීම (Build Speed වැඩි කිරීමට)
COPY --chown=user:user requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# 5. අනෙකුත් සියලුම ගොනු (app, models ෆෝල්ඩර ඇතුළුව) පිටපත් කිරීම
COPY --chown=user:user . .

# 6. Hugging Face සඳහා Port එක 7860 ලෙස නිරාවරණය කිරීම
EXPOSE 7860

# 7. Uvicorn මගින් API එක ධාවනය කිරීම
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "7860"]