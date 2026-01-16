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

### **Research Problem**
Standard Large Language Models (LLMs) trained on English-dominant data often fail to capture the morphological richness of "Low-Resource Languages" like Sinhala. They suffer from "hallucinations," token stuttering, and an inability to adhere to strict output formats (e.g., JSON) required for mobile application integration. Furthermore, existing tools lack the ability to generate Context-Aware Distractors for reading comprehension assessment.

### **Methodology**

-**Model Architecture**
The core engine utilizes Llama 3 (8B Parameter Model), adapted specifically for the Sinhala language using Parameter-Efficient Fine-Tuning (PEFT) and Low-Rank Adaptation (LoRA). The model was trained on a curated dataset of primary-level Sinhala literature to ensure age-appropriate syntax.

-**Serverless GPU Infrastructure**
The system is deployed on Modal, a high-performance serverless cloud platform. It employs 4-bit Quantization (bitsandbytes) and a "Warm-Pool" strategy to deliver heavy AI inference with low latency suitable for real-time gaming.

-**Robust Post-Processing Layer**
A novel Deterministic Error-Correction Algorithm acts as a middleware between the AI model and the frontend. It utilizes recursive JSON parsing and Regex-based sanitization to automatically detect and repair "token stuttering" and malformed data structures in real-time, ensuring zero-crash reliability.

-**Assessment Logic** 
The model is fine-tuned not just to write stories, but to simultaneously generate Multiple Choice Questions (MCQs) with context-aware distractor answers, testing deep semantic understanding.
  
### **Key Innovations**

- **Specialized Low-Resource Model**  
  Moving beyond generic commercial APIs, this system uses a custom-trained model that captures the specific "Spoken Sinhala" register required for early childhood education.
  
- **Self-Healing AI Architecture**  
  The implementation of an automated syntax-repair layer solves the stochastic instability common in Generative AI, making the system robust enough for production use in schools.
  
- **Efficient Deployment**  
  Achieves high-quality generation on consumer-grade hardware constraints via quantization and serverless orchestration.
      
### 4. ✅ Contextual Grammar Module (Component 4)
Methodology
Position-Aware Grammar Classification Pipeline

Custom Deep Learning Architecture:
A lightweight neural network designed specifically for short Sinhala sentences (2–5 words), avoiding over-dependence on large pretrained models.

Embedding Layer Design:

Manual Word Embeddings to ensure stable representation of Sinhala vocabulary

Position Embeddings explicitly encode word order, enabling the model to distinguish grammatically correct and incorrect sequences

Hybrid Feature Extraction:

Conv1D Layer: Captures local grammatical patterns and phrase-level relationships

Bidirectional LSTM: Learns long-range dependencies and sentence-level structure from both directions

Binary Grammar Classification:

Softmax output layer predicts Correct / Incorrect sentence labels

Dropout regularization minimizes overfitting on small datasets

Adaptive Evaluation & Bias Control

To prevent memorization and bias:

The system evaluates structural correctness, not surface-level word frequency

Incorrect sentences are generated by systematic word-order permutations, ensuring robust negative samples

Model confidence is monitored; predictions near 0.5 trigger adaptive retraining

Performance Analytics Module

A Predictive Learning Assessment Engine analyzes:

Classification confidence

Error frequency per sentence structure

Repeated mistake patterns

This enables dynamic difficulty adjustment for future grammar tasks.

Key Innovation
Structure-Aware Grammar Intelligence

The first Sinhala grammar classification framework that explicitly models word order using position embeddings, rather than relying on implicit transformer attention alone.

Low-Resource Optimization

Designed to perform reliably with small datasets, outperforming large pretrained models (BERT, XLM-R) that showed bias and instability in Sinhala grammar tasks.

Anti-Memorization Design









---

## 🛠️ Development & Data Utilities

We have released standalone tools to facilitate the data collection process for the research. These tools are available as pre-compiled executables (Windows,android app,web).

| Tool | Version | Description | Download |
| :--- | :--- | :--- | :--- |
| **🎙️ Pronunciation Tool** | `v0.1.0` | Records audio samples for phoneme verification. | [Download Latest](https://github.com/tharusha-dilhara/sinhala-mithuru/releases/tag/v0.1.0) |
| **✍️ Handwriting Tool** | `v0.2.0` | Captures digital handwriting strokes & images. | [Download Latest](https://github.com/tharusha-dilhara/sinhala-mithuru/releases/tag/v0.2.0) |
|🧪 **Sinhala Word Lab** | `v0.3.0` | Advanced analytics dashboard to audit dataset health, monitor phoneme distribution, and set linguistic targets for pronunciation models. | [Download Latest](https://github.com/tharusha-dilhara/sinhala-mithuru/releases/tag/v0.3.0) |
| 🎧 **SinhalaPhonoNet** | `v0.4.0` | Advanced Audio Lab for manual spectral auditing and quality control of phoneme datasets. | [Download](https://github.com/tharusha-dilhara/sinhala-mithuru/releases/tag/v0.4.0) |
| 📱 **SinhalaMithuru recodelab Mobile** | `v0.5.0` | Supervised mobile utility for high-fidelity audio acquisition with external hardware support. | [Download](https://github.com/tharusha-dilhara/sinhala-mithuru/releases/tag/v0.5.0) |
💻 **Handwriting Collector (Web)** | `v6.0.0` | Centralized web ecosystem for digital stroke acquisition and dataset curation. | [Access Tool](https://github.com/tharusha-dilhara/sinhala-mithuru/releases/tag/v0.6.0) |
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
| **C3: Narrative** | Generative AI / Fine-Tuning (PEFT) / Natural Language Processing(NLP) | Python, PyTorch, Llama 3 (LoRA), Modal (Serverless GPU), bitsandbytes |
| **C4: Grammar** |  |  |

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---
