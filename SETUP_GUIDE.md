# 🚀 Pocket CFO - Quick Setup Guide

This guide will help you get Pocket CFO running in minutes!

---

## ✅ Prerequisites Checklist

Before you begin, make sure you have:

- [ ] Flutter 3.10+ installed ([Get Flutter](https://flutter.dev/docs/get-started/install))
- [ ] Android Studio or Xcode installed
- [ ] A physical device or emulator/simulator
- [ ] ~500MB free space for the AI model

---

## 📦 Installation Steps

### 1. Navigate to Project Directory
```bash
cd C:\Users\surya\OneDrive\Desktop\financify\financify
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Check Flutter Setup
```bash
flutter doctor
```
Fix any issues reported by `flutter doctor` before proceeding.

### 4. Run the App

**For Android:**
```bash
flutter run
```

**For iOS:**
```bash
flutter run
```

**For a specific device:**
```bash
flutter devices  # List available devices
flutter run -d <device-id>
```

---

## 🎮 First-Time Setup (In-App)

Once the app launches:

### Step 1: Load Demo Data (Recommended for Testing)

1. Open the app dashboard
2. Tap the **three-dot menu (⋮)** in the top-right corner
3. Select **"Load Demo Data"**
4. Confirm the action
5. Wait a few seconds for data generation

**What this does:**
- Creates realistic expense transactions
- Sets monthly income to ₹25,000
- Generates 50-80 transactions for the current month
- Populates all expense categories

### Step 2: Set Your Monthly Income (Optional)

If you want to use your own data:

1. Tap the **three-dot menu (⋮)**
2. Select **"Set Monthly Income"**
3. Enter your monthly income (e.g., 50000)
4. Tap **Save**

### Step 3: Load the AI Model

To enable AI-powered financial advice:

1. On the dashboard, you'll see a card: **"AI Model Not Loaded"**
2. Tap **"Load AI Model"**
3. Wait for download (~400MB, requires internet)
4. Progress bar will show download status
5. Model loads automatically after download

**Important:** The model download happens **once**. After that, everything works offline!

---

## 💡 Testing the Features

### Test 1: Add an Expense

1. Tap the **"Add Expense"** floating button
2. Enter amount: `500`
3. Select category: **Food**
4. Add description: `Coffee at Starbucks` (optional)
5. Select date (defaults to today)
6. Tap **"Save Expense"**

### Test 2: View Dashboard

Check these elements on the dashboard:
- **Health Score Card** - Shows your financial health (0-100)
- **Monthly Summary** - Income, spent, remaining, savings rate
- **Category Chart** - Pie chart of spending breakdown
- **Recent Transactions** - Last 10 transactions

### Test 3: Ask Your AI CFO

1. Navigate to **"Ask CFO"** tab at the bottom
2. Try these questions:
   - "Can I afford ₹5000 headphones?"
   - "How is my food spending?"
   - "Am I financially healthy?"
3. AI will analyze your data and respond with advice

### Test 4: View All Transactions

1. Go to **"Transactions"** tab
2. View all your expenses
3. Swipe left to delete
4. Tap filter icon to filter by category

---

## 🎯 Demo Mode for Presentations

For hackathon demos or presentations:

### Quick Demo Setup (2 minutes)

1. **Clear existing data:**
   - Menu (⋮) → "Clear All Data" → Confirm

2. **Load demo data:**
   - Menu (⋮) → "Load Demo Data" → Confirm
   - This creates realistic transaction history

3. **Ensure AI is loaded:**
   - Check "AI Ready" indicator in top-right
   - If not, load the model (one-time download)

4. **You're ready to present!**

### Demo Script

**Opening (Show Privacy):**
- "This app works 100% offline"
- Turn on airplane mode
- Show the app still works perfectly

**Feature Showcase:**
1. **Dashboard** - "Here's my financial health score: 72/100"
2. **Transactions** - "All my expenses, beautifully organized"
3. **AI Chat** - Ask: "Can I afford ₹5000 headphones?"
4. **AI Response** - "See how it analyzes my finances and gives advice"
5. **Offline Demo** - "All of this runs on-device. No internet needed!"

---

## 🔧 Troubleshooting

### Issue: Dependencies not installing
**Solution:**
```bash
flutter clean
flutter pub get
```

### Issue: App not building
**Solution:**
```bash
flutter doctor
# Fix any issues reported
flutter clean
flutter run
```

### Issue: Model download failing
**Solution:**
- Check internet connection
- Ensure ~500MB free space
- Try again - downloads are resumable

### Issue: AI not responding
**Solution:**
- Verify "AI Ready" indicator shows green checkmark
- If not loaded, tap "Load AI Model"
- Restart app if needed

### Issue: No transactions showing
**Solution:**
- Use "Load Demo Data" from menu
- Or manually add expenses via "Add Expense" button

### Issue: Database errors
**Solution:**
```bash
# Clear app data and reinstall
flutter clean
flutter run
# Then load demo data again
```

---

## 📱 Platform-Specific Notes

### Android
- Minimum API level: 24 (Android 7.0)
- Recommended: Android 10+ for best performance
- Storage: Model stored in app's internal storage

### iOS
- Minimum version: iOS 13.0
- Recommended: iOS 14+ for best performance
- Storage: Model stored in app's documents directory

---

## 🎓 Learning the Codebase

### Key Files to Explore

**Data Layer:**
- `lib/database/database_helper.dart` - SQLite operations
- `lib/models/` - Data models (Transaction, Category, etc.)

**Business Logic:**
- `lib/services/finance_engine.dart` - Financial calculations
- `lib/services/prompt_builder.dart` - AI context generation
- `lib/services/ai_cfo_service.dart` - AI integration

**UI Layer:**
- `lib/views/dashboard_view.dart` - Main dashboard
- `lib/views/ai_chat_view.dart` - Chat interface
- `lib/views/add_expense_view.dart` - Expense form
- `lib/widgets/` - Reusable UI components

**Utilities:**
- `lib/utils/demo_data_generator.dart` - Demo data creation

---

## 🚀 Next Steps

1. **Customize Categories**
   - Edit `lib/models/category.dart`
   - Add your own expense categories

2. **Adjust Health Score Algorithm**
   - Modify `lib/services/finance_engine.dart`
   - Tweak the scoring formula

3. **Enhance AI Prompts**
   - Edit `lib/services/prompt_builder.dart`
   - Improve context for better AI responses

4. **Add New Features**
   - Budget limits per category
   - Recurring expense reminders
   - Export to PDF/CSV
   - Receipt OCR scanning

---

## 💬 Need Help?

**Common Questions:**

**Q: How long does model download take?**
A: ~5-10 minutes on average WiFi (~400MB download)

**Q: Can I use my own LLM model?**
A: Yes! Edit `lib/services/model_service.dart` and add your model URL

**Q: Does this work completely offline?**
A: Yes! After initial model download, zero internet needed

**Q: How accurate are the calculations?**
A: 100% accurate - all math is deterministic Dart code, not AI

**Q: Can I change the currency from ₹ to $?**
A: Yes! Search and replace `₹` with `$` in the codebase

---

## ✅ Pre-Flight Checklist

Before demo/presentation:

- [ ] Demo data loaded
- [ ] AI model loaded and showing "AI Ready"
- [ ] Tested adding an expense
- [ ] Tested asking AI a question
- [ ] Airplane mode tested and working
- [ ] Battery charged (demos use CPU for AI)
- [ ] Screen recording ready (optional)

---

**You're all set! Happy hacking! 🚀**

For the complete guide, see [README.md](README.md)
