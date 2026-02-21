# 💰 Pocket CFO - Your Private Financial Brain

**Version:** 1.0.0  
**Hackathon Project:** RunAnywhere SDK + Flutter  
**Tagline:** "100% Offline, 100% Secure, 100% Intelligent"

---

## 🚀 Project Overview

**Pocket CFO** is the world's first **fully offline AI-powered personal CFO** that provides intelligent financial advice without ever sending data to the cloud. Built using Flutter and the RunAnywhere SDK, it demonstrates the power of on-device AI for privacy-critical applications.

### Key Features

- ✅ **On-Device AI Financial Advisor** - Ask questions in natural language, get personalized advice
- ✅ **Complete Offline Functionality** - Works without internet connection
- ✅ **Financial Health Scoring** - Intelligent algorithm rates your financial health (0-100)
- ✅ **Risk Assessment** - Real-time analysis of purchase affordability
- ✅ **Smart Expense Tracking** - Beautiful, intuitive expense management
- ✅ **Category Analysis** - Visual breakdown of spending patterns
- ✅ **Zero Privacy Compromise** - Data never leaves your device

---

## 🎯 The Problem We Solve

Traditional personal finance apps have critical flaws:
- Send sensitive financial data to cloud servers
- Require constant internet connectivity
- Risk data breaches and privacy violations
- Incur expensive API costs for AI features
- Provide generic, non-contextual advice

**Pocket CFO solves all of these problems.**

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────┐
│          Flutter UI Layer               │
│  (Dashboard, Charts, Chat Interface)    │
└──────────────┬──────────────────────────┘
               ↓
┌─────────────────────────────────────────┐
│       Business Logic Layer              │
│  • FinanceEngine (Calculations)         │
│  • RiskAssessor (Risk Analysis)         │
│  • HealthScoreCalculator                │
└──────────────┬──────────────────────────┘
               ↓
┌─────────────────────────────────────────┐
│         AI Reasoning Layer              │
│  • PromptBuilder (Context Generation)   │
│  • RunAnywhere LLM (On-device AI)       │
│  • AICFOService (Response Handler)      │
└──────────────┬──────────────────────────┘
               ↓
┌─────────────────────────────────────────┐
│           Data Layer                    │
│  • SQLite (Local database)              │
│  • TransactionRepository                │
└─────────────────────────────────────────┘
```

---

## 🧠 How the AI Works

### The Magic Behind Pocket CFO

Pocket CFO uses a **hybrid architecture** that separates pure computation from AI reasoning:

1. **Deterministic Finance Engine** (Dart)
   - Calculates totals, percentages, health scores
   - Performs risk assessments
   - Analyzes spending patterns
   - **100% accurate, no AI hallucination**

2. **AI Reasoning Layer** (RunAnywhere LLM)
   - Receives structured financial context
   - Generates natural language explanations
   - Provides personalized recommendations
   - **Runs completely on-device**

### Example Flow

**User asks:** "Can I afford ₹5000 headphones?"

```
1. Finance Engine calculates:
   - Remaining balance: ₹7000
   - Days left: 12
   - Risk level: HIGH (71% of remaining balance)
   
2. Prompt Builder creates context:
   PURCHASE ANALYSIS:
   Proposed Amount: ₹5000
   Remaining: ₹7000
   Days Left: 12
   Risk: HIGH
   
3. RunAnywhere LLM generates advice:
   "With ₹7000 remaining and 12 days left, a ₹5000 
   purchase would leave you with only ₹2000. This is 
   high-risk spending. Consider postponing or saving 
   up over 2-3 months instead."
```

**Key Insight:** Numbers are calculated deterministically, AI explains them conversationally.

---

## 📊 Financial Health Score Algorithm

**Formula:** `Health Score = (40% Savings) + (30% Budget Adherence) + (20% Consistency) + (10% Buffer)`

### Components:

1. **Savings Rate (40 points)**
   - 30%+ savings = 40 points (Excellent)
   - 20-30% = 35 points (Great)
   - 15-20% = 30 points (Good)
   - 10-15% = 20 points (Fair)
   - 5-10% = 10 points (Poor)

2. **Budget Adherence (30 points)**
   - Compares actual spending pace vs. expected pace
   - Rewards staying on track throughout the month

3. **Spending Consistency (20 points)**
   - Penalizes overspending in specific categories
   - E.g., food > 25% of income loses 5 points

4. **Emergency Buffer (10 points)**
   - Rewards maintaining healthy daily budget buffer
   - ₹500+/day = 10 points

**Result:** Score from 0-100
- 80-100: Excellent 🟢
- 60-79: Good 🟡
- 40-59: Fair 🟠
- 0-39: Needs Attention 🔴

---

## 🛠️ Tech Stack

### Core Technologies
- **Flutter** 3.10+
- **Dart** 3.0+
- **RunAnywhere SDK** 0.16.0
  - `runanywhere`: Core SDK
  - `runanywhere_llamacpp`: LLM backend
  - `runanywhere_onnx`: STT/TTS support

### Key Packages
- `sqflite`: Local SQLite database
- `fl_chart`: Beautiful charts and graphs
- `provider`: State management
- `uuid`: Transaction ID generation
- `intl`: Date/number formatting

### AI Model
- **SmolLM2-360M-Instruct-Q8_0** (~400MB)
- Small, fast, efficient for mobile
- Perfect for conversational financial advice

---

## 📱 Features Breakdown

### 1. Dashboard
- Financial health score card with visual indicator
- Monthly summary (income, spent, savings rate)
- Category breakdown pie chart
- Recent transactions list
- Quick actions

### 2. Expense Management
- Quick add expense form
- 9 predefined categories with icons
- Optional descriptions
- Date picker
- Instant save

### 3. AI Chat Interface
- Suggested question chips
- Free-form text input
- Conversational chat history
- Real-time streaming responses
- Context-aware advice

### 4. Transaction History
- All transactions with swipe-to-delete
- Filter by category
- Grouped by date
- Beautiful category icons

### 5. Demo Mode
- One-click demo data generation
- Realistic transaction patterns
- Perfect for presentations

---

## 🎮 Getting Started

### Prerequisites
- Flutter 3.10 or higher
- Android SDK (for Android) or Xcode (for iOS)
- ~500MB free space (for app + AI model)

### Installation

1. **Navigate to the project**
   ```bash
   cd financify
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

4. **Load demo data** (for testing)
   - Open the app
   - Tap the menu icon (⋮) in the dashboard
   - Select "Load Demo Data"
   - This generates realistic transactions for the current month

5. **Load AI Model**
   - Tap "Load AI Model" on the dashboard
   - Wait for download (~400MB)
   - Model loads automatically after download
   - Now you can ask AI questions!

---

## 💡 Usage Examples

### Example 1: Check Affordability
**User:** "Can I afford ₹5000 headphones?"

**AI Response:**
> "With ₹7000 remaining and 12 days left in the month, a ₹5000 purchase would leave you with only ₹2000. This is classified as high-risk spending. Consider postponing this purchase or saving up over 2-3 months instead."

### Example 2: Category Analysis
**User:** "How is my food spending?"

**AI Response:**
> "Your food spending of ₹6000 is 33% higher than last month and exceeds the recommended 20% of income. Try meal prepping or reducing restaurant visits to bring this down to ₹5000 next month."

### Example 3: Financial Health Check
**User:** "How am I doing financially?"

**AI Response:**
> "You're doing well with a health score of 72/100 - Good! You're saving 18% and spending responsibly. Keep maintaining your current pace to end the month with a comfortable ₹4000 buffer."

---

## 🎯 Hackathon Demo Script

### Opening (30 seconds)
**"Most finance apps send your data to the cloud. We don't."**
- Show Pocket CFO working in airplane mode
- Emphasize "100% offline" messaging

### Problem Statement (30 seconds)
**"Your financial data is too sensitive for the cloud."**
- Mention data breach statistics
- Highlight user privacy concerns

### Solution Demo (3 minutes)

#### Part 1: Add Expenses (30s)
- Quickly add 2-3 expenses
- Show category selection
- Emphasize speed and simplicity

#### Part 2: Dashboard (30s)
- Show health score
- Show category breakdown chart
- Show monthly summary

#### Part 3: AI Magic (90s)
Ask these questions:
1. "Can I afford ₹5000 headphones?" → Get risk analysis
2. "How is my food spending?" → Get category advice
3. "Am I financially healthy?" → Get overall assessment

#### Part 4: The Wow Moment (30s)
**Turn off WiFi and ask another question**
- Show airplane mode
- AI still responds instantly
- Emphasize "This is 100% on your device"

### Closing (30 seconds)
**"The future of fintech is private, offline, and intelligent."**

---

## 🔒 Privacy & Security

### Our Guarantees
1. **Zero Network Calls for AI** - RunAnywhere runs locally
2. **No Cloud Storage** - All data in local SQLite
3. **No Analytics** - We don't track anything
4. **No Third-Party SDKs** - No ads, no tracking
5. **Open Architecture** - Code is auditable

### Data Flow
```
User Input → SQLite (Local) → FinanceEngine (Local) → 
RunAnywhere LLM (Local) → UI Display

NEVER: User Data → Internet → Cloud Server
```

---

## 📈 Future Roadmap

### Phase 1 (Post-Hackathon)
- [ ] Receipt OCR (scan bills to auto-add expenses)
- [ ] Budget planning (set category-wise limits)
- [ ] Goal tracking (savings goals with progress)
- [ ] Export reports (PDF financial summaries)
- [ ] Multi-currency support

### Phase 2 (3-6 Months)
- [ ] Investment tracking (stocks, mutual funds)
- [ ] Bill reminders (recurring payments)
- [ ] Family accounts (shared household finances)
- [ ] Voice interface (speak questions to AI)
- [ ] Home screen widgets

### Phase 3 (Long-term)
- [ ] Wearable support (smartwatch)
- [ ] Desktop apps (Windows, macOS, Linux)
- [ ] Advanced AI models (larger context)
- [ ] Bank sync (privacy-preserving local sync)

---

## 🏆 Competitive Advantage

| Feature | Pocket CFO | Mint | YNAB | Wallet |
|---------|-----------|------|------|--------|
| **Offline AI** | ✅ | ❌ | ❌ | ❌ |
| **Privacy-First** | ✅ | ❌ | ⚠️ | ❌ |
| **Natural Language** | ✅ | ❌ | ❌ | ❌ |
| **Zero API Costs** | ✅ | ❌ | ❌ | ❌ |
| **Works Offline** | ✅ | ❌ | ❌ | ❌ |

**Unique Position:** First and only offline AI-powered personal CFO.

---

## 🤝 Contributing

This is a hackathon project, but we welcome contributions!

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

---

## 📄 License

MIT License - feel free to use this code for learning and building!

---

## 🙏 Acknowledgments

- **RunAnywhere Team** for the amazing on-device AI SDK
- **Flutter Team** for the incredible cross-platform framework
- **HuggingFace** for the SmolLM2 model
- **All hackathon participants** for the inspiration!

---

## 💬 Elevator Pitch

*"Pocket CFO is the world's first fully offline AI-powered personal finance assistant. Unlike traditional apps that send your sensitive financial data to the cloud, we run everything locally on your device using on-device AI. Ask questions like 'Can I afford this?' or 'Where am I overspending?' and get intelligent, personalized advice instantly—no internet required, no privacy compromised. We're making AI-powered financial intelligence accessible to everyone while keeping their data completely private."*

---

**Built with ❤️ using RunAnywhere SDK and Flutter**

**100% Offline • 100% Private • 100% Intelligent**
