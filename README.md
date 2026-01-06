# Sinhala Mithuru

[![Python](https://img.shields.io/badge/Python-3.9%2B-blue?logo=python&logoColor=white)](https://www.python.org/)
[![PyTorch](https://img.shields.io/badge/PyTorch-2.0%2B-EE4C2C?logo=pytorch&logoColor=white)](https://pytorch.org/)
[![TensorFlow](https://img.shields.io/badge/TensorFlow-2.13%2B-FF6F00?logo=tensorflow&logoColor=white)](https://www.tensorflow.org/)
[![Flutter](https://img.shields.io/badge/Flutter-3.0%2B-02569B?logo=flutter&logoColor=white)](https://flutter.dev/)
[![Docker](https://img.shields.io/badge/Docker-Enabled-2496ED?logo=docker&logoColor=white)](https://www.docker.com/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

> **An AI-Powered Adaptive Gamified Ecosystem for Developing Sinhala Language Skills in Primary Students.**

---

## 📖 Abstract

**Sinhala Mithuru** is a cutting-edge research initiative addressing the critical learning gaps in primary education for the low-resource Sinhala language. Moving beyond static digitization, this ecosystem leverages advanced **Deep Learning** and **Adaptive Algorithms** to offer a personalized pedagogy.

The system targets four core competencies: **Handwriting, Pronunciation, Reading Comprehension, and Grammar**. By integrating novel Hybrid Neural Architectures and Transfer Learning, the system acts as an intelligent tutor that diagnoses subtle errors and adapts content in real-time.

---

## 🏗️ System Architecture

The project follows a scalable **Microservices Architecture**, containerized via Docker.

* **Frontend:** A cross-platform tablet application built with **Flutter & Flame Engine**.
* **Backend:** Independent AI inference services (APIs) built with **Python (Flask/FastAPI)**.
* **Orchestration:** Managed via **Docker Compose**.

---

## 🔬 Advanced Research Components

This project introduces significant novelties in applying AI to a morphologically rich, low-resource language.

### 1. ✍️ End-to-End Deep Learning System for Sinhala Handwriting (Component 1)
* **Research Problem:** Addressing the complexity of Sinhala script (60+ characters, 15+ modifiers) and the need for process-oriented feedback.
* **Methodology: Hybrid Deep Neural Framework**
    * **Model A (Visual):** A **Multi-Headed CNN** for static character and modifier prediction.
    * **Model B (Temporal):** An **LSTM/Transformer** network to analyze the writing process (stroke order and direction) as a time series.
* **Key Innovation:** Fusion of spatial and temporal analysis for holistic handwriting evaluation.

### 2. 🗣️ Siamese-Based Metric Learning for Pronunciation Verification (Component 2)

* **Research Problem:**
    Standard Automatic Speech Recognition (ASR) systems are optimized for word transcription, not phonetic verification. They often fail to distinguish between **Sinhala Minimal Pairs**—phonemes with subtle acoustic differences like **'බ' (Retroflex)** vs **'ඹ' (Dental)** . In low-resource settings like child speech, standard classifiers struggle to learn these nuances without massive datasets.

* **Methodology: Deep Metric Learning Framework**
    * **Architecture:** A **Siamese Neural Network** (Twin Network) architecture. It uses **Wav2Vec 2.0 Base** as the shared backbone feature extractor to generate context-aware acoustic embeddings.
    * **Objective Function:** The model is trained using **Triplet Margin Loss**.
        * *Formula:* $L(A, P, N) = \max(\|f(A)-f(P)\|^2 - \|f(A)-f(N)\|^2 + \alpha, 0)$
        * *Mechanism:* The network learns a distance metric where the embedding of a student's correct pronunciation (Positive) is pulled closer to a reference template (Anchor), while an incorrect pronunciation (Negative) is pushed apart by a defined margin ($\alpha$).
    * **Data Strategy:** Utilizes **Hard Negative Mining** during training. Instead of random negatives, the model is explicitly trained on confusing pairs (e.g., using 'බ' as the negative example for 'ඹ') to force it to learn distinct acoustic features.

* **Key Innovation:**
    * **Contrastive Phonetic Disambiguation:** Shifts the paradigm from "Classification" (predicting a label) to "Metric Learning" (measuring acoustic similarity), which is far more robust for error detection.
    * **Few-Shot/Zero-Shot Capability:** The system can verify new words/phonemes without retraining the core model, simply by updating the reference embeddings in the database.

### 3. 📖 Interactive Narrative Module (Component 3)


### 4. ✅ Contextual Grammar Module (Component 4)
Research Problem:
Existing multilingual transformer models (e.g., bert-base-multilingual-cased, xlm-roberta-large) fail to generate grammatically accurate Spoken Sinhala suitable for primary education (Grades 1–5). Standard LSTM and hybrid architectures (LSTM, LSTM+CNN, LSTM with basic position encoding) also underperform due to insufficient modeling of positional and syntactic dependencies in low-resource, agglutinative languages like Sinhala. This makes the generation of simple, child-friendly sentences unreliable.

Methodology: Custom LSTM with Position Encoding

Model Architecture:

Base Layer: LSTM network for sequential modeling of Sinhala word embeddings.

Position Encoding: Custom-designed positional encoding layers to capture the order and syntactic dependencies in sentences. Unlike standard fixed positional encoding, this custom design dynamically adjusts to sentence length and word types, improving model sensitivity to sentence structure.

Output Layer:

Softmax: For predicting the next word in sequence (token-level prediction).

Sigmoid: For binary sequence-level classification tasks (optional, e.g., grammatical correctness verification).

Training Strategy:

Trained on a curated corpus of Spoken Sinhala sentences for Grades 1–5.

Includes augmentation for handling rare words and informal grammar structures typical in spoken Sinhala.

Key Innovation:

Custom Positional Encoding: Improves sequence modeling in agglutinative languages by emphasizing word order and grammatical dependencies, leading to higher generation accuracy than standard LSTM or transformer fine-tuned models.

Low-Resource Optimization: Achieves good accuracy without requiring huge pretrained multilingual models or expensive fine-tuning, making it ideal for resource-constrained educational settings.

Grade-Level Adaptation: Dynamically adjusts predictions based on the target reading level (Grades 1–5), ensuring age-appropriate sentence simplicity.

Performance:

Outperforms:

Standard LSTM models

LSTM + CNN architectures

LSTM with basic or standard positional encoding layers

Provides good grammatical accuracy for spoken Sinhala suitable for primary education.

Research Area: Natural Language Processing (NLP), Low-Resource Language Modeling
Technology Stack: Python, TensorFlow/PyTorch, Custom Embedding & Positional Encoding Layers, LSTM Networks


---

## 📥 Data Collection Tools (Utilities)

We have released standalone tools to facilitate the data collection process for the research. These tools are available as pre-compiled executables (Windows).

| Tool | Version | Description | Download |
| :--- | :--- | :--- | :--- |
| **🎙️ Pronunciation Tool** | `v0.1.0` | Records audio samples for phoneme verification. | [Download Latest](https://github.com/tharusha-dilhara/sinhala-mithuru/releases/tag/v0.1.0) |
| **✍️ Handwriting Tool** | `v0.2.0` | Captures digital handwriting strokes & images. | [Download Latest](https://github.com/tharusha-dilhara/sinhala-mithuru/releases/tag/v0.2.0) |

---

## 🚀 Getting Started

### Prerequisites
* [Docker Desktop](https://www.docker.com/products/docker-desktop) (Required)
* [Git](https://git-scm.com/)

### Installation & Running

1.  **Clone the Repository**
    ```bash
    git clone [https://github.com/tharusha-dilhara/sinhala-mithuru.git](https://github.com/tharusha-dilhara/sinhala-mithuru.git)
    cd sinhala-mithuru
    ```

2.  **Setup Environment Variables**
    Create a `.env` file (refer to `.env.example`).

3.  **Run with Docker Compose**
    This builds all 4 AI services and the Game Frontend.
    ```bash
    docker-compose up --build
    ```

4.  **Access Endpoints**
    * **Game Frontend:** `http://localhost:3000`
    * **Handwriting API:** `http://localhost:8001`
    * **Pronunciation API:** `http://localhost:8002`

---

## 📂 Data & Model Management

To maintain a lightweight repository, we use **DVC (Data Version Control)** and **Hugging Face Hub**.

* **Datasets:** Raw audio and handwriting datasets are versioned via DVC.
    ```bash
    dvc pull
    ```
* **Models:** Trained weights are hosted on Hugging Face and downloaded automatically by the Docker containers.

---

## 👥 Research Team

**Sri Lanka Institute of Information Technology (SLIIT)** - Faculty of Computing

| Component | Research Area | Technology |
| :--- | :--- | :--- |
| **C1: Handwriting** | Computer Vision / Sequence Modeling | TensorFlow, CNN, LSTM |
| **C2: Pronunciation** | Speech Processing / Adaptive AI | Python, Librosa, PyTorch, Transformers, Audiomentations |
| **C3: Narrative** |  |  |
| **C4: Grammar** |  |  |

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---
