# Kipepeo Engine
### High-Frequency Micro-Lending Risk Engine for Offline Markets

## Description
Kipepeo is a localized, Edge-deployed Credit Risk Assessment Engine designed for micro-lending institutions operating in regions with intermittent connectivity. Unlike traditional cloud-based scoring, Kipepeo runs locally on low-resource hardware to provide instant credit decisions for small-scale traders and "Mama Mbogas."

## Key Requirements

### 🚀 On-Device Inference
Uses quantized GGUF/TFLite models to analyze alternative data (transaction SMS, mobile money patterns, and supply chain history) without uploading sensitive raw data to the cloud.

### 🛡️ Privacy-First Governance
Implements a localized version of your AI Quality Governance Layer to ensure bias-free lending decisions and prevent predatory scoring patterns.

### 🔒 Differential Privacy
Employs noise-injection techniques to ensure that individual financial records remain private even during model retraining cycles.

### 🛡️ Offline-First Logic
Ensures that the entire loan lifecycle—from scoring to contract generation and repayment tracking—happens entirely on the device.

---

## 🛠 Development Roadmap

### Phase 1: Edge Data Architecture
- [x] **SMS & Transaction Scrapers**: Build localized parsers for M-Pesa/Airtel Money SMS receipts.
- [x] **Local Vector Store**: Integrate SQLite with Vector extensions for on-device profile storage.
- [x] **Data Schema**: Design a privacy-preserving schema for "Mama Mboga" profiles.

### Phase 2: On-Device ML Pipeline
- [x] **Model Selection**: Expert Rule Engine (localized for Kenya) and TFLite support.
- [x] **Inference Service**: Implement a background service in Flutter using `FeatureService`.
- [x] **Feature Engineering**: Create a local pipeline to convert SMS text into numerical risk vectors.

### Phase 3: Privacy & Governance Layer
- [x] **Bias Detection**: Implement the "Governance Layer" to check for demographic parity in lending decisions.
- [x] **Noise Injection**: Add a Differential Privacy module to "fuzz" sensitive financial aggregates before any cloud sync.
- [x] **Audit Logs**: Local immutable logs for transparency in scoring decisions.

### Phase 4: Offline Business Logic (The Loan Lifecycle)
- [ ] **Repayment Tracker**: Monitor SMS for loan repayment confirmation (e.g., "Paid back 500 Ksh").
- [ ] **Loan Calculator**: Local interest rate calculation and repayment scheduling.
- [ ] **Contract Builder**: Generate a local summary/shareable agreement for the borrower.

### Phase 5: Agent Interface (UI/UX)
- [x] **Navigation Hub**: 3-page layout (Hub, Vault, Shield) for professional agent use.
- [x] **Instant Decision Dashboard**: 5-second visualization of creditworthiness.
- [ ] **Loan Application Flow**: Interactive UI to apply for and track a loan locally.
