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

### ✍️ End-to-End Deep Learning System for Sinhala Handwriting (Component 1)

## Research Problem
Addressing the structural complexity of the Sinhala script (38 character classes) and providing real-time, process-oriented feedback for learners to improve their writing accuracy.

---

## Methodology: Dual-Stream Neural Framework

### 1. Preprocessing Pipeline
* **Normalization:** Raw stroke data is transformed using **Path-Distance based Linear Interpolation** to normalize varying writing speeds into a fixed temporal resolution (150 points).
* **Extracted Features:**
    * Spatial coordinates: $(x, y)$
    * Velocity: $(dx, dy)$
    * Pen state: $(p)$

### 2. Model A: Character Recognition Engine
A **Deep Recurrent Neural Network (LSTM)** optimized for sequence classification.
* **Architecture:** Includes a **Masking layer** to handle variable padding, followed by **stacked LSTM layers** and **Batch Normalization** to predict character classes with high precision.

### 3. Model B: Quality Assessment Engine
A **Hybrid CNN-LSTM Architecture** designed for binary classification ("Correct" vs. "Wrong").
* **Spatial Analysis:** A **1D-Convolutional layer** acts as a feature extractor to detect subtle jitters or deviations in the stroke.
* **Temporal Analysis:** **LSTM layers** analyze the stroke order and direction for holistic evaluation.



## Key Innovations

* ✨ **Synthetic Balancing:** Implementation of **SMOTE** (Synthetic Minority Over-sampling Technique) to effectively handle class imbalance within Sinhala character datasets.
* ⚙️ **Integrated Inference:** A unified pipeline that concurrently validates both the **shape (Classification)** and the **process (Quality)** of the stroke, providing a comprehensive feedback loop for the user.
---
  
## 2. 🗣️ SiPhon-MetricNet: Multi-task Metric Learning for Phoneme Recognition

### **Research Problem**
Standard Automatic Speech Recognition (ASR) systems are optimized for word transcription, not phonetic verification. They often fail to distinguish between **Sinhala Minimal Pairs**—phonemes with subtle acoustic differences such as **/ක/** (Unvoiced) vs **/ග/** (Voiced).  
In low-resource settings like **child speech**, standard classifiers struggle to capture these nuances without massive datasets.



### **Methodology: Multi-task Deep Metric Learning Framework**

#### **Architecture**
The **SiPhon-MetricNet architecture** uses a self-supervised **Wav2Vec2-XLS-R** (Large-scale Cross-lingual Speech Representation) backbone as the shared feature extractor to generate context-aware acoustic embeddings.



### **Objective Function**
Unlike standard models, this is trained using a **Multi-task Learning (MTL)** objective by jointly optimizing three loss functions:

- **Triplet Margin Loss**:  
  To minimize the distance between similar pronunciations and maximize it between different ones.

- **Cross-Entropy Loss**:  
  To ensure robust phoneme-level classification.

- **Center Loss**:  
  To minimize intra-class variation, making the embedding space highly discriminative.



### **Mechanism**
The network learns an embedding space where a student's correct pronunciation (**Positive**) is pulled closer to a canonical reference (**Anchor**), while incorrect or confusing pronunciations (**Negative**) are pushed apart by a defined margin.



### **Key Innovations**

- **Discriminative Embedding Space**  
  By combining **Triplet Loss** and **Center Loss**, the model effectively separates phonetically similar Sinhala characters (e.g., **/ක/** vs **/ග/**), which is critical for accurate pronunciation assessment.

- **Acoustic Modeling for Education**  
  Specifically designed to evaluate the pronunciation quality of **primary school children**, making it highly robust to the high variability in child speech.

- **Efficiency**  
  The integration of the **XLS-R backbone** allows for high performance even with the limited data availability typical of the **Sinhala language**.

---

### 3. 📖 Generative AI-Powered Interactive Narrative Engine (Component 3)

* **Research Problem:**
    Existing digital reading tools for children rely on static, pre-written content that fails to adapt to a child's specific reading proficiency or interests. Furthermore, there is a lack of Context-Aware Content Generation in Sinhala that distinguishes between the diglossic nature of the language (the distinct difference between "Katasara" (Spoken) and "Likhitha" (Written) styles).

* **Methodology: Deep Metric Learning Framework**
   Visual Storytelling Pipeline: Utilizes Google Gemini 1.5 Flash (via LangChain) to analyze user-uploaded images in real-time. The system employs a Two-Stage Chain-of-Thought (CoT) approach:
   Scene Understanding: Extracts objects, educational themes, and grade-appropriate vocabulary from the raw image.
   Adaptive Synthesis: Generates a narrative using a Dynamic Prompt Injection System that strictly regulates sentence complexity, grammar style (Spoken vs. Written), and length based on the student's Grade (1–5).
   Few-Shot "Golden Dataset" Injection: To ensure cultural and syntactic accuracy, the system dynamically retrieves human-verified "Golden Examples" of high-quality Sinhala stories and injects them into the model's context window during inference.
   Predictive Analytics Engine: Integrates a Random Forest Regressor (Scikit-Learn) to analyze telemetry data (Time Spent, Accuracy, Attempt Count). This model predicts a student's Improvement Score to automatically adjust the complexity of future stories.
  
* **Key Innovation:**
    * **Multi-Modal Curriculum Adaptation:** The first Sinhala educational engine capable of generating grade-appropriate stories on-the-fly from any image provided by the child, turning their real-world environment into learning material.
    * **Closed-Loop Feedback System:** Combines Generative AI (for content creation) with Predictive ML (for student assessment) to create a self-correcting educational loop.
      
### 4. ✅ Contextual Grammar Module (Component 4)


---

## 🛠️ Development & Data Utilities

We have released standalone tools to facilitate the data collection process for the research. These tools are available as pre-compiled executables (Windows,android app,web).

| Tool | Version | Description | Download |
| :--- | :--- | :--- | :--- |
| **🎙️ Pronunciation Tool** | `v0.1.0` | Records audio samples for phoneme verification. | [Download Latest](https://github.com/tharusha-dilhara/sinhala-mithuru/releases/tag/v0.1.0) |
| **✍️ Handwriting Tool** | `v0.2.0` | Captures digital handwriting strokes & images. | [Download Latest](https://github.com/tharusha-dilhara/sinhala-mithuru/releases/tag/v0.2.0) |
| **Dataset Analytics** | 🧪 **Sinhala Word Lab** | v1.0.0 | Advanced analytics dashboard to audit dataset health, monitor phoneme distribution, and set linguistic targets for pronunciation models. | [Download Latest](#) |

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
| **C3: Narrative** | Generative AI / Multi-Modal NLP | Python (FastAPI), LangChain, Google Gemini 1.5, Scikit-Learn |
| **C4: Grammar** |  |  |

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---
