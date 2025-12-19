# 🗺️ SENSEI TRAVEL — PROGRESS REPORT

**Generated:** December 15, 2025  
**Status:** Phase 1 (Partial) — Foundation & Conversational Planner MVP

---

## ✅ COMPLETED FEATURES

### PHASE 0 — Foundation & Scoping

#### ✅ 0.1 — Vision Lock
- **Status:** ✅ Complete
- Product pillars defined: Conversational Agent, Wallet & OCR, Localized Transport, Offline Safety, Booking Aggregation
- One-liner established: "Sensei: The Conversational Travel & Finance OS for South Asia"

#### ✅ 0.2 — Technical Blueprint
- **Status:** ✅ Partial
- **Completed:**
  - ✅ iOS app: SwiftUI + Combine architecture
  - ✅ AI Layer: OpenAI & Ollama provider support
  - ✅ Core Data persistence layer
  - ✅ Firebase Authentication (Google Sign-In)

#### ✅ 0.3 — App IA (Information Architecture)
- **Status:** ✅ Partial
- **Completed Screens:**
  1. ✅ Onboarding/Login (`LoginView.swift`, `WelcomeView.swift`)
  2. ✅ Home (AI agent) (`HomeView.swift`)
  3. ✅ Trip Chat (`TripChatView.swift`)
  4. ✅ New Trip Creation (`NewTripView.swift`)
- **Missing Screens:**
  5. ❌ Itinerary screen (dedicated view)
  6. ❌ Expenses tab
  7. ❌ Wallet
  8. ❌ Bookings inbox
  9. ❌ Offline/safety center
  10. ❌ Settings

---

### PHASE 1 — Conversational Planner MVP (Weeks 2–5)

#### ✅ Week 2 — Base UI
- **Status:** ✅ Complete
- ✅ Home screen with text input
- ✅ Chat bubble structure (`MessageBubble.swift`)
- ✅ Quick action chips (implied in HomeView)
- ✅ Voice input button (UI ready, needs backend)
- ✅ Image picker integration

#### ✅ Week 3 — Itinerary Generator (AI)
- **Status:** ⚠️ Partial
- **Completed:**
  - ✅ AI Service layer (`AIService.swift`)
  - ✅ OpenAI & Ollama providers
  - ✅ Conversational memory (history passed to AI)
  - ✅ System prompt for travel financial assistant
- **Missing:**
  - ❌ Backend route: `POST /generate-itinerary`
  - ❌ Structured itinerary output (day-by-day plan)
  - ❌ Budget constraints in prompt
  - ❌ Travel distances calculation
  - ❌ Safety heuristics
  - ❌ Weather conditions integration
  - ❌ Estimated costs output
  - ❌ Transport type suggestions

#### ⚠️ Week 4 — Multilingual Support
- **Status:** ⚠️ Partial
- **Completed:**
  - ✅ Audio recording capability (`TripChatView.swift`)
  - ✅ Audio message storage
- **Missing:**
  - ❌ Speech-to-text for English, Hindi, Urdu
  - ❌ Translation layer (Gemini or NLLB)
  - ❌ Multilingual AI responses

#### ⚠️ Week 5 — Save & Edit Itinerary
- **Status:** ⚠️ Partial
- **Completed:**
  - ✅ Trip saving (`TripStore.swift`)
  - ✅ Message persistence (`ChatMessageStore.swift`)
  - ✅ Core Data for offline caching
- **Missing:**
  - ❌ Itinerary editing UI
  - ❌ "Regenerate This Day" feature
  - ❌ Structured itinerary data model
  - ❌ Day-by-day plan display

---

## ❌ NOT STARTED — PHASE 2: Expenses & Wallet System

### Week 6 — Basic Expense Tracker
- ❌ Add expense manually UI
- ❌ Category tagging system
- ❌ Currency selection (PKR/INR/BDT/NPR)
- ❌ Expense data model

### Week 7 — OCR Receipt Scanning
- ❌ OCR integration (Google Vision API or Apple VisionKit)
- ❌ Extract: amount, date, merchant name
- ❌ Auto-categorize expenses
- ❌ Auto-split with group members

### Week 8 — Currency Engine
- ❌ Real-time FX rates API
- ❌ Offline cached rates
- ❌ Spend summary by currency
- ❌ Daily budget burn-down graph

### Week 9 — Group Trips
- ⚠️ Partial: Basic group creation exists (`NewTripView.swift` with members)
- ❌ Group-level expense tallies
- ❌ Friend invite system
- ❌ Invite code generation

### Week 10 — Agentic Debt Settlement
- ❌ AI debt detection
- ❌ Settlement prompts
- ❌ Deep-links to UPI, JazzCash, Easypaisa, bKash, eSewa

---

## ❌ NOT STARTED — PHASE 3: Hyper-Local Intelligence

### Week 11 — Local Transport Models
- ❌ Local bus heuristics
- ❌ Shared jeep options
- ❌ Tuk-tuk cost expectations
- ❌ Train options
- ❌ Regional cost expectations

### Week 12 — Local Food/POI Recommendation Engine
- ❌ Embeddings for preference matching
- ❌ Dhaba vs café recommendations
- ❌ Budget vs premium filtering
- ❌ Scenic vs fast route suggestions

### Week 13 — Predictive Alerts
- ❌ Road closure notifications
- ❌ Weather warnings
- ❌ Landslide/flood alerts
- ❌ Protest/bandh alerts

### Week 14 — Smart "Switch Route" Suggestions
- ❌ Route switching logic
- ❌ Alternative route suggestions

---

## ❌ NOT STARTED — PHASE 4: Offline & Safety Systems

### Week 15 — Offline Data Architecture
- ⚠️ Partial: Core Data exists for local storage
- ❌ Sync strategy for offline/online
- ❌ Offline maps
- ❌ Offline bookings storage

### Week 16 — Document Vault
- ❌ Secure offline storage
- ❌ Passport, NIC, Visa, Permits, Tickets storage
- ❌ Document encryption

### Week 17 — Emergency AI Layer
- ❌ One-tap SOS
- ❌ Translation into local languages
- ❌ Coordinates + nearest landmark
- ❌ Emergency contact integration

### Week 18 — Background Safety Monitor
- ❌ Battery % monitoring
- ❌ Last known network tracking
- ❌ Last location tracking
- ❌ Weather-based alerts

---

## ❌ NOT STARTED — PHASE 5: Booking Aggregation

### Week 19 — Booking Inbox
- ❌ Email import
- ❌ Screenshot parsing
- ❌ PDF parsing
- ❌ SMS text parsing
- ❌ AI extraction: timing, PNRs, addresses, cancellation policy

### Week 20 — Timeline Builder
- ❌ Chronological trip builder
- ❌ Flights, Hotels, Buses, Trains, Activities integration

### Week 21–24 — API Integrations
- ❌ SkyScanner/Kiwi/Duffel (flights)
- ❌ Booking.com/Agoda (hotels)
- ❌ Regional buses/trains APIs

---

## 📊 COMPLETION SUMMARY

| Phase | Status | Completion |
|-------|--------|------------|
| **Phase 0: Foundation** | ⚠️ Partial | ~60% |
| **Phase 1: Conversational Planner** | ⚠️ Partial | ~40% |
| **Phase 2: Expenses & Wallet** | ❌ Not Started | 0% |
| **Phase 3: Hyper-Local Intelligence** | ❌ Not Started | 0% |
| **Phase 4: Offline & Safety** | ❌ Not Started | 0% |
| **Phase 5: Booking Aggregation** | ❌ Not Started | 0% |
| **Overall Progress** | 🟡 Early Stage | **~15%** |

---

## 🎯 IMMEDIATE NEXT STEPS (Priority Order)

### 1. **Complete Phase 1 — Conversational Planner** (Weeks 2–5)
   - [ ] Build structured itinerary output from AI
   - [ ] Create dedicated Itinerary screen
   - [ ] Add "Regenerate This Day" feature
   - [ ] Implement speech-to-text for multilingual support
   - [ ] Add translation layer

### 2. **Start Phase 2 — Expenses & Wallet** (Week 6)
   - [ ] Create Expense data model
   - [ ] Build "Add Expense" UI
   - [ ] Implement category tagging
   - [ ] Add multi-currency support (PKR/INR/BDT/NPR)

### 3. **Backend Infrastructure**
   - [ ] Set up Supabase/Postgres database
   - [ ] Create Node.js/Python FastAPI backend
   - [ ] Implement API endpoints for:
     - Itinerary generation
     - Expense tracking
     - Group management
     - OCR processing

### 4. **OCR Integration** (Week 7)
   - [ ] Integrate Google Vision API or Apple VisionKit
   - [ ] Build receipt scanning UI
   - [ ] Implement auto-categorization
   - [ ] Add auto-split functionality

---

## 🔧 TECHNICAL DEBT & IMPROVEMENTS NEEDED

1. **Backend Missing:** All data is currently stored locally (UserDefaults, Core Data). Need cloud sync.
2. **API Key Security:** Fixed in latest commit (uses environment variables), but needs documentation.
3. **Error Handling:** Basic error handling exists, but needs more robust user-facing messages.
4. **Testing:** No unit tests or UI tests found.
5. **Documentation:** Missing API documentation, architecture docs.
6. **Localization:** No i18n support for multiple languages.

---

## 📝 NOTES

- **Current Architecture:** MVVM pattern with SwiftUI, Core Data for persistence
- **AI Integration:** OpenAI & Ollama providers working, but needs structured output for itineraries
- **Authentication:** Firebase Auth with Google Sign-In working
- **UI Design:** Follows dark theme, deep-green palette as specified
- **Data Storage:** Currently using UserDefaults for trips, Core Data for messages

---

**Last Updated:** December 15, 2025

