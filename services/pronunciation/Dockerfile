# සැහැල්ලු Python 3.10 Image එක
FROM python:3.10-slim

# Audio processing සඳහා අවශ්‍ය Linux C++ Libraries ස්ථාපනය
RUN apt-get update && apt-get install -y \
    libsndfile1 \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# 🌟 Hugging Face Space Security Requirement: අලුත් User කෙනෙක් සෑදීම
RUN useradd -m -u 1000 user
USER user
ENV PATH="/home/user/.local/bin:$PATH"

# වැඩ කරන ෆෝල්ඩරය සැකසීම
WORKDIR /app

# Requirements ෆයිල් එක කොපි කර පැකේජ ස්ථාපනය කිරීම (User permissions සමග)
COPY --chown=user requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Requirements ස්ථාපනයට පසු මෙය එක් කරන්න
RUN python3 -c "from transformers import Wav2Vec2FeatureExtractor; Wav2Vec2FeatureExtractor.from_pretrained('facebook/wav2vec2-xls-r-300m')"

# 🌟 ඔබගේ Audio ෆෝල්ඩරය සහ කේතය Docker එක ඇතුළට කොපි කිරීම
COPY --chown=user reference_audios/ ./reference_audios/
COPY --chown=user main.py .

# 🌟 Hugging Face භාවිතා කරන Port එක විවෘත කිරීම
EXPOSE 7860

# FastAPI සර්වර් එක ආරම්භ කිරීම
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "7860"]