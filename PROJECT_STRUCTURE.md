# 📁 Pocket CFO - Project Structure

Complete overview of the codebase architecture and file organization.

---

## 🗂️ Directory Structure

```
pocket_cfo/
├── lib/
│   ├── main.dart                           # App entry point
│   │
│   ├── models/                             # Data models
│   │   ├── transaction.dart                # Transaction entity
│   │   ├── category.dart                   # Category & DefaultCategories
│   │   └── financial_state.dart            # MonthlyFinancialState, RiskAssessment
│   │
│   ├── database/                           # Data persistence
│   │   └── database_helper.dart            # SQLite operations
│   │
│   ├── services/                           # Business logic
│   │   ├── model_service.dart              # RunAnywhere model management
│   │   ├── finance_engine.dart             # Financial calculations
│   │   ├── prompt_builder.dart             # AI context generation
│   │   └── ai_cfo_service.dart             # AI integration & responses
│   │
│   ├── views/                              # App screens
│   │   ├── dashboard_view.dart             # Main dashboard
│   │   ├── add_expense_view.dart           # Add/edit expense form
│   │   ├── ai_chat_view.dart               # AI chat interface
│   │   ├── transactions_view.dart          # Transaction list
│   │   ├── home_view.dart                  # (Legacy - from starter)
│   │   ├── chat_view.dart                  # (Legacy - from starter)
│   │   ├── speech_to_text_view.dart        # (Legacy - from starter)
│   │   ├── text_to_speech_view.dart        # (Legacy - from starter)
│   │   ├── tool_calling_view.dart          # (Legacy - from starter)
│   │   └── voice_pipeline_view.dart        # (Legacy - from starter)
│   │
│   ├── widgets/                            # Reusable UI components
│   │   ├── health_score_card.dart          # Health score display
│   │   ├── monthly_summary_card.dart       # Monthly stats card
│   │   ├── category_chart.dart             # Pie chart for categories
│   │   ├── recent_transactions_list.dart   # Transaction list widget
│   │   ├── feature_card.dart               # (Legacy - from starter)
│   │   ├── model_loader_widget.dart        # (Legacy - from starter)
│   │   ├── chat_message_bubble.dart        # (Legacy - from starter)
│   │   └── audio_visualizer.dart           # (Legacy - from starter)
│   │
│   ├── theme/                              # App styling
│   │   └── app_theme.dart                  # Dark theme configuration
│   │
│   └── utils/                              # Utilities
│       └── demo_data_generator.dart        # Demo data creation
│
├── android/                                # Android platform files
├── ios/                                    # iOS platform files
│
├── pubspec.yaml                            # Dependencies & metadata
├── README.md                               # Main documentation
├── SETUP_GUIDE.md                          # Quick start guide
└── PROJECT_STRUCTURE.md                    # This file
```

---

## 📦 Key Files Explained

### 🎯 Core Application

#### `lib/main.dart`
**Purpose:** App initialization and root widget

**Key Responsibilities:**
- Initialize RunAnywhere SDK
- Register LlamaCpp and ONNX backends
- Register default AI models
- Setup Provider state management
- Define app theme

**Dependencies:**
- `ModelService` - Model management
- `AICFOService` - AI chat service
- `AppTheme` - UI theme
- `DashboardView` - Entry screen

---

### 📊 Models Layer

#### `lib/models/transaction.dart`
**Purpose:** Transaction entity definition

**Key Components:**
```dart
enum TransactionType { income, expense }

class Transaction {
  - id: String
  - amount: double
  - category: String
  - description: String
  - date: DateTime
  - type: TransactionType
  - createdAt: DateTime
}
```

**Methods:**
- `toMap()` - Convert to database format
- `fromMap()` - Create from database
- `formattedAmount` - Display as ₹X
- `formattedDate` - Human-readable date

#### `lib/models/category.dart`
**Purpose:** Expense category definitions

**Key Components:**
```dart
class Category {
  - id, name, icon, color, budgetLimit
}

class DefaultCategories {
  - 9 predefined categories
  - Food, Transport, Shopping, Bills, etc.
}
```

#### `lib/models/financial_state.dart`
**Purpose:** Financial analysis results

**Key Components:**
```dart
class MonthlyFinancialState {
  - income, totalSpent, remaining
  - categorySpending: Map<String, double>
  - savingsRate, healthScore
  - daysRemainingInMonth
}

enum RiskLevel { low, medium, high, critical }

class RiskAssessment {
  - level: RiskLevel
  - riskScore: double
  - factors: List<String>
  - recommendation: String
}
```

---

### 💾 Database Layer

#### `lib/database/database_helper.dart`
**Purpose:** SQLite database operations

**Schema:**
```sql
-- Transactions
CREATE TABLE transactions (
  id TEXT PRIMARY KEY,
  amount REAL,
  category TEXT,
  description TEXT,
  date TEXT,
  type TEXT,
  created_at TEXT
);

-- Monthly Budgets
CREATE TABLE monthly_budgets (
  id INTEGER PRIMARY KEY,
  month TEXT,
  income REAL,
  savings_goal REAL
);
```

**CRUD Operations:**
- `insertTransaction()`, `updateTransaction()`, `deleteTransaction()`
- `getAllTransactions()`, `getTransactionsByMonth()`, `getTransactionsByCategory()`
- `setMonthlyIncome()`, `getMonthlyIncome()`
- `clearAllData()` - Reset database

---

### 🧮 Services Layer

#### `lib/services/finance_engine.dart`
**Purpose:** Core financial calculations

**Key Methods:**
```dart
calculateMonthlyState(): MonthlyFinancialState
- Calculates income, spending, remaining balance
- Computes category breakdown
- Calculates savings rate
- Generates health score (0-100)

assessPurchase(amount, state): RiskAssessment
- Determines risk level (LOW/MEDIUM/HIGH/CRITICAL)
- Generates risk factors
- Provides recommendations

getSpendingTrends(): Map<String, dynamic>
- Week-over-week comparison
- Trend analysis (increasing/decreasing)
```

**Health Score Formula:**
```
Score = (40% Savings) + (30% Budget Adherence) + 
        (20% Consistency) + (10% Emergency Buffer)
```

#### `lib/services/prompt_builder.dart`
**Purpose:** Generate AI context from financial data

**Key Methods:**
```dart
getSystemPrompt(): String
- Defines AI CFO role and guidelines
- Sets tone and constraints

buildFinancialContext(state): String
- Converts MonthlyFinancialState to text
- Formats numbers, percentages, categories

buildPurchaseContext(amount, state, risk): String
- Purchase-specific analysis context
- Risk factors and daily budget impact

buildCategoryContext(category, state): String
- Category-specific spending analysis
- Percentage of income, recommendations

buildFullPrompt(userQuery, state, ...): String
- Combines system + context + user query
- Ready-to-send prompt for LLM
```

#### `lib/services/ai_cfo_service.dart`
**Purpose:** AI integration and response generation

**Key Methods:**
```dart
askQuestion(question): Future<String>
- Extracts purchase amount from query (if present)
- Extracts category from query (if present)
- Gets current financial state
- Builds prompt with context
- Generates AI response via RunAnywhere
- Returns formatted advice

_generateResponse(prompt): Future<String>
- Streams LLM tokens
- Assembles complete response
- Handles errors
```

**Question Parsing:**
- Detects purchase amounts: "₹5000", "Rs 5000", "5000 rupees"
- Detects categories: "food", "transport", "shopping", etc.

#### `lib/services/model_service.dart`
**Purpose:** Manage RunAnywhere AI models

**Registered Models:**
- **LLM:** SmolLM2-360M-Instruct-Q8_0 (~400MB)
- **STT:** Sherpa Whisper Tiny EN (~80MB)
- **TTS:** Piper TTS US English Medium (~100MB)

**Key Methods:**
- `downloadAndLoadLLM()`, `downloadAndLoadSTT()`, `downloadAndLoadTTS()`
- `isModelDownloaded()`, progress tracking
- State management with `ChangeNotifier`

---

### 🖥️ Views Layer

#### `lib/views/dashboard_view.dart`
**Purpose:** Main app screen

**Features:**
- Financial health score card
- Monthly summary
- Category breakdown chart
- Recent transactions
- Quick actions (Add Expense, Ask CFO)
- Settings menu (Load Demo Data, Set Income, Clear Data)
- Model loading indicator

**State Management:**
- Loads data from `FinanceEngine`
- Refreshes on navigation return
- Handles empty states

#### `lib/views/add_expense_view.dart`
**Purpose:** Expense creation form

**Form Fields:**
- Amount (required, numeric)
- Category (required, visual grid selector)
- Description (optional, text)
- Date (required, date picker)

**Validation:**
- Amount > 0
- Category selected
- Saves to database via `DatabaseHelper`

#### `lib/views/ai_chat_view.dart`
**Purpose:** Conversational AI interface

**Features:**
- Suggested question chips
- Free-form text input
- Chat history with bubbles
- Streaming response indicator
- Model status banner

**Flow:**
1. User enters question
2. Question added to chat
3. Loading indicator shown
4. `AICFOService.askQuestion()` called
5. Response streamed back
6. Chat updated with AI response

#### `lib/views/transactions_view.dart`
**Purpose:** All transactions list

**Features:**
- Scrollable transaction list
- Swipe-to-delete with confirmation
- Filter by category
- Grouped by date
- Empty state handling

---

### 🎨 Widgets Layer

#### `lib/widgets/health_score_card.dart`
**Purpose:** Visual health score display

**Features:**
- Gradient background (color-coded by score)
- Large score number (0-100)
- Status text (Excellent/Good/Fair/Needs Attention)
- Progress bar
- Remaining balance text

**Color Scheme:**
- 80-100: Green gradient
- 60-79: Blue gradient
- 40-59: Orange gradient
- 0-39: Red gradient

#### `lib/widgets/monthly_summary_card.dart`
**Purpose:** Key financial metrics

**Displays:**
- Income
- Spent (amount + percentage)
- Remaining
- Savings rate
- Days remaining
- Daily burn rate

#### `lib/widgets/category_chart.dart`
**Purpose:** Spending breakdown visualization

**Features:**
- Pie chart using `fl_chart`
- Legend with category colors
- Percentage labels
- Sorted by spending amount

#### `lib/widgets/recent_transactions_list.dart`
**Purpose:** Transaction list component

**Features:**
- Last N transactions
- Category icons with colors
- Amount highlighting (red for expenses)
- Date formatting
- Empty state

---

### 🛠️ Utilities

#### `lib/utils/demo_data_generator.dart`
**Purpose:** Generate realistic demo transactions

**Features:**
- Clears existing data
- Sets income to ₹25,000
- Generates 2-4 transactions per day
- Realistic amounts and descriptions per category
- Current month only

**Transaction Templates:**
- Food: Coffee, Lunch, Groceries (₹50-₹1200)
- Transport: Uber, Metro, Fuel (₹30-₹500)
- Shopping: Clothes, Electronics (₹500-₹3000)
- Bills: Netflix, Internet, Rent (₹200-₹10000)
- Entertainment: Movie, Concert (₹200-₹1500)
- Health: Gym, Medicine (₹100-₹2000)

---

## 🎨 Theme Configuration

#### `lib/theme/app_theme.dart`
**Purpose:** App-wide styling

**Key Colors:**
- Primary: Blue (#2563EB) - Trust, stability
- Success: Green (#10B981) - Positive actions
- Warning: Orange (#F59E0B) - Caution
- Error: Red (#EF4444) - High risk

**Theme:**
- Dark mode optimized
- Material 3 design
- Custom card elevations
- Consistent spacing

---

## 📋 Configuration Files

### `pubspec.yaml`
**Purpose:** Project metadata and dependencies

**Key Dependencies:**
```yaml
# RunAnywhere SDK
runanywhere: 0.16.0
runanywhere_llamacpp: 0.16.0
runanywhere_onnx: 0.16.0

# Database
sqflite: ^2.3.0

# Charts
fl_chart: ^0.66.0

# State Management
provider: ^6.1.2

# Utilities
uuid: ^4.2.1
intl: ^0.19.0
```

---

## 🔄 Data Flow Architecture

### User Adds Expense
```
1. AddExpenseView (UI input)
   ↓
2. Transaction model created
   ↓
3. DatabaseHelper.insertTransaction()
   ↓
4. SQLite database updated
   ↓
5. Navigator.pop() returns to dashboard
   ↓
6. DashboardView._loadData() refreshes
```

### User Asks AI Question
```
1. AIChatView (user input)
   ↓
2. AICFOService.askQuestion(question)
   ↓
3. FinanceEngine.calculateMonthlyState()
   ↓
4. PromptBuilder.buildFullPrompt(...)
   ↓
5. RunAnywhere.generateTextStream(prompt)
   ↓
6. Response streamed back to UI
   ↓
7. Chat history updated
```

### Financial Health Calculation
```
1. DashboardView._loadData()
   ↓
2. FinanceEngine.calculateMonthlyState()
   ↓
3. DatabaseHelper.getTransactionsByMonth()
   ↓
4. Aggregate spending by category
   ↓
5. Calculate health score (0-100)
   ↓
6. Return MonthlyFinancialState
   ↓
7. UI renders health card, chart, summary
```

---

## 🧩 Extension Points

### Adding a New Category

1. **Edit `lib/models/category.dart`:**
```dart
Category(
  id: 'gym',
  name: 'Gym',
  icon: Icons.fitness_center,
  color: const Color(0xFF9B59B6),
  budgetLimit: 2000,
)
```

### Adding a New AI Question Type

1. **Edit `lib/services/prompt_builder.dart`:**
```dart
static String buildComparisonContext(
  String category1,
  String category2,
  MonthlyFinancialState state,
) {
  // Build context for comparing two categories
}
```

2. **Edit `lib/services/ai_cfo_service.dart`:**
```dart
// Add detection logic
if (question.contains('compare')) {
  final categories = _extractTwoCategories(question);
  prompt = PromptBuilder.buildFullPrompt(
    userQuery: question,
    state: state,
    comparisonCategories: categories,
  );
}
```

### Adding a New Screen

1. **Create view in `lib/views/`:**
```dart
class BudgetPlanningView extends StatefulWidget {
  // New feature screen
}
```

2. **Add navigation in `lib/views/dashboard_view.dart`:**
```dart
onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const BudgetPlanningView(),
    ),
  );
}
```

---

## 📚 Learning Path

**For Beginners:**
1. Start with `lib/main.dart` - understand app initialization
2. Explore `lib/models/` - learn data structures
3. Read `lib/views/dashboard_view.dart` - see UI in action
4. Study `lib/services/finance_engine.dart` - understand calculations

**For Intermediate:**
1. Deep dive into `lib/services/ai_cfo_service.dart` - AI integration
2. Study `lib/services/prompt_builder.dart` - prompt engineering
3. Explore `lib/database/database_helper.dart` - data persistence
4. Customize widgets in `lib/widgets/`

**For Advanced:**
1. Optimize health score algorithm
2. Implement new AI question types
3. Add advanced visualizations
4. Integrate receipt OCR
5. Build voice interface

---

**Happy Coding! 🚀**
