# 🚀 Pocket CFO - Quick Start Guide

## 📋 Pre-Flight Checklist

Before running the app, complete these steps:

### 1. Install Dependencies

```bash
cd "C:\Users\surya\OneDrive\Desktop\New folder\financify"
flutter pub get
```

This will install:
- ✅ `csv` - CSV file parsing
- ✅ `file_picker` - File selection dialog
- ✅ `flutter_local_notifications` - Local push notifications

**Expected Output:**
```
Running "flutter pub get" in financify...
Got dependencies!
```

### 2. Verify Installation

```bash
flutter analyze
```

**Expected:** No errors (LSP errors in csv_import files will disappear after pub get)

---

## 🎮 Running the App

### Option A: With Android Device/Emulator

```bash
flutter devices  # Check connected devices
flutter run
```

### Option B: Specific Device

```bash
flutter run -d <device-id>
```

---

## 🎯 First Launch Flow

### Step 1: Onboarding (Beautiful 3-page flow)

**Page 1: Privacy First** 🔒
- Message: "All data stays on your device"
- Action: Tap "Next"

**Page 2: On-Device AI** 🤖
- Message: "100% offline AI using RunAnywhere"
- Action: Tap "Next"

**Page 3: Smart Insights** 📊
- Two options:
  1. **"Load Demo & Explore"** ← **Recommended for testing**
  2. **"Start Fresh"**

### Step 2: Choose Your Path

#### Path A: Demo Mode (Recommended)
1. Tap **"Load Demo & Explore"**
2. Wait 2-3 seconds for data generation
3. **Dashboard appears with:**
   - Safe-to-Spend: ₹8,200
   - Health Score: 65-75/100
   - Recent transactions
   - Category breakdown

#### Path B: Fresh Start
1. Tap **"Start Fresh"**
2. Dashboard appears empty
3. Tap **"+"** button to add first expense
4. OR go to Settings → Load Demo Data later

---

## 🧪 Testing Features

### Test 1: Dashboard Overview

**What to Check:**
- ✅ Safe-to-Spend card (gradient, shows amount)
- ✅ Health Score (emoji + number)
- ✅ Monthly summary (Income, Spent, Saved)
- ✅ Category chart (pie chart)
- ✅ Recent transactions list

**Expected with Demo Data:**
- Income: ₹35,000
- Spent: ~₹24,000-28,000
- Safe-to-Spend: ~₹7,000-9,000
- Health: 65-75/100

---

### Test 2: Subscription Detection

**Steps:**
1. Tap bottom nav: **"Payments"** tab
2. See calendar with colored dots
3. Scroll to **"Upcoming Payments"** section

**Expected:**
- 5 detected subscriptions:
  - Netflix (₹649/month)
  - Spotify (₹119/month)
  - iCloud+ (₹75/month)
  - YouTube Premium (₹189/month)
  - Amazon Prime (₹299/month)
- Monthly Total: ₹1,331

**Actions to Test:**
- Tap a subscription → See details
- Tap "Dismiss" → Removed from list
- Tap refresh → Re-scan transactions

---

### Test 3: Budgets

**Steps:**
1. Tap bottom nav: **"Insights"** tab
2. Switch to **"Budgets"** tab (top tabs)
3. See 6 pre-set budgets from demo data

**Expected Budgets:**
- Food: ₹8,000
- Transport: ₹3,000
- Shopping: ₹5,000
- Bills: ₹3,000
- Entertainment: ₹2,000
- Health: ₹2,000

**Actions to Test:**
- Tap **"+ New Budget"**
- Select category
- Enter amount
- Save
- See updated dashboard

---

### Test 4: AI Chat (Requires Model Download)

**Step 1: Load AI Model**
1. Dashboard → Top right → **"Load AI"** button (if visible)
2. OR Settings → AI Model → **"Download Model"**
3. Wait 5-10 minutes (~400MB download)
4. Shows progress bar

**Step 2: Test AI**
1. Tap bottom nav: **"Ask AI"** tab
2. See suggested questions
3. Tap: **"Can I afford ₹5000 headphones?"**
4. Wait 2-3 seconds
5. See AI response with specific numbers

**Expected Response Example:**
> "With ₹8,200 remaining and 12 days left in the month, a ₹5,000 purchase would consume 61% of your buffer. This is moderately risky. Consider waiting until next month or setting aside savings first."

**More Questions to Test:**
- "How is my food spending?"
- "Am I financially healthy?"
- "Where am I overspending?"

---

### Test 5: CSV Import

**Step 1: Create Sample CSV**

Save this as `test_transactions.csv`:
```csv
Date,Merchant,Amount,Category
2024-01-15,Starbucks,350,food
2024-01-16,Uber,120,transport
2024-01-17,Amazon,2400,shopping
2024-01-18,DMart,850,food
2024-01-19,Netflix,649,bills
```

**Step 2: Import**
1. Settings → Data → **"Import from CSV"**
2. Tap **"Select CSV File"**
3. Navigate to your CSV file
4. Select it
5. Wait for processing

**Expected Result:**
```
Import Successful!
Transactions Imported: 5
Skipped/Invalid: 0
Success Rate: 100%
```

**Step 3: Verify**
1. Go to Dashboard
2. See new transactions in "Recent"
3. Check updated Safe-to-Spend
4. Check Subscriptions (Netflix detected if recurring)

---

### Test 6: Airplane Mode Demo 🎯

**The Wow Moment!**

**Prerequisites:**
- ✅ AI model downloaded
- ✅ Demo data loaded

**Steps:**
1. Open Settings on phone
2. Enable **Airplane Mode** ✈️
3. Return to Pocket CFO
4. Go to **"Ask AI"** tab
5. Ask: "Can I afford ₹3000?"
6. **IT STILL WORKS!**

**This proves:**
- 100% offline AI
- No cloud dependency
- Complete privacy

---

## 🐛 Troubleshooting

### Issue: "Package not found" errors

**Solution:**
```bash
flutter clean
flutter pub get
```

### Issue: AI model won't download

**Cause:** No internet connection

**Solution:**
1. Connect to WiFi
2. Settings → AI Model → Download
3. Wait for completion
4. Then you can go offline

### Issue: Demo data doesn't load

**Solution:**
1. Settings → Data → Clear All Data
2. Settings → Data → Load Demo Data
3. Refresh dashboard

### Issue: Subscriptions not detected

**Cause:** Need 2+ similar transactions

**Solution:**
- Load demo data (has 3 months of subs)
- Or manually add same merchant 3 times

### Issue: App crashes on CSV import

**Cause:** Packages not installed

**Solution:**
```bash
flutter pub get
flutter run
```

---

## 📊 Demo Data Breakdown

The demo data generator creates:

### Subscriptions (3 months history)
- Netflix: ₹649/month × 3 = ₹1,947
- Spotify: ₹119/month × 3 = ₹357
- iCloud+: ₹75/month × 3 = ₹225
- YouTube Premium: ₹189/month × 3 = ₹567
- Amazon Prime: ₹299/month × 3 = ₹897

### Variable Expenses (2 months)
- Food: ~₹12,000 (Zomato, Swiggy, groceries, restaurants)
- Transport: ~₹4,500 (Uber, Ola, Metro)
- Shopping: ~₹8,000 (Flipkart, Amazon, Myntra)
- Entertainment: ~₹3,500 (movies, gaming)
- Health: ~₹2,500 (pharmacy, gym)

### Big-Ticket Items
- JBL Headphones: ₹6,499
- Zara Clothing: ₹2,800
- Dinner Out: ₹1,400

### Budgets
- Total: ₹23,000/month across 6 categories
- Designed to show 80-95% utilization

---

## 🎬 Demo Script (Hackathon-Ready)

### Setup (Before Demo)
1. ✅ App installed and running
2. ✅ Demo data loaded
3. ✅ AI model downloaded
4. ✅ Know where airplane mode toggle is

### Script (90 seconds)

**[00:00-00:15] Opening**
> "This is Pocket CFO - the world's first 100% offline AI financial advisor. Notice the green 'Privacy Mode' indicator - all your data stays on your device."

*Show dashboard with Privacy Mode badge*

**[00:15-00:35] Dashboard Tour**
> "At a glance, I can see I have ₹8,200 safe to spend this month, with a health score of 72 out of 100. The app automatically categorizes my spending and shows where my money goes."

*Scroll to show Safe-to-Spend card, health score, and category chart*

**[00:35-00:55] Subscription Detection**
> "Here's something cool - it automatically detected all my recurring subscriptions. Netflix, Spotify, YouTube Premium - that's ₹1,331 per month I might not have realized I was spending."

*Navigate to Payments tab, show calendar with markers, point to monthly total*

**[00:55-01:20] AI Magic**
> "Now watch this. I'll ask the AI: 'Can I afford ₹5000 headphones?' It analyzes my spending, remaining balance, and days left in the month... and gives me personalized advice with specific numbers."

*Go to Ask AI tab, ask question, show response*

**[01:20-01:30] Airplane Mode Wow Moment**
> "Here's the best part. Watch what happens when I turn on airplane mode..."

*Enable airplane mode, ask another AI question*

> "It still works! Everything - the AI, the insights, the calculations - runs completely on-device. Your financial data is 100% private."

**[01:30-01:30] Closing**
> "Pocket CFO: Privacy-first personal finance powered by on-device AI."

---

## ✅ Final Pre-Demo Checklist

Before your presentation:

- [ ] Run `flutter pub get`
- [ ] Test app launches successfully
- [ ] Load demo data
- [ ] Download AI model (allow 10 mins)
- [ ] Test AI responds to a question
- [ ] Practice demo script 2-3 times
- [ ] Charge device to 100%
- [ ] Know how to enable airplane mode quickly
- [ ] Have backup plan if AI model download fails
- [ ] Screenshot key screens as backup

---

## 🎯 Success Criteria

Your app is demo-ready if:

✅ Dashboard shows Safe-to-Spend and Health Score
✅ Subscriptions tab shows 5 detected subscriptions  
✅ AI Chat responds to questions with numbers  
✅ Airplane mode demo works  
✅ No crashes during 2-minute demo  

---

## 📞 Quick Reference Commands

```bash
# Install dependencies
flutter pub get

# Run app
flutter run

# Clean build
flutter clean && flutter pub get && flutter run

# Check for issues
flutter analyze

# List devices
flutter devices

# Build release APK
flutter build apk --release
```

---

**You're ready to go! Good luck with your demo! 🚀**
