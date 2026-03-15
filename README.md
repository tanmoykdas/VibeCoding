# Moneyco – Personal Finance Tracker

> A modern personal money management app built with Flutter

Software Development I (Fifth Semester)  
**This project was developed with assistance from AI tools**

---

## Application Screenshots

<p align="center">
	<img src="Moneyco/assets/screenshots/photo_2026-03-16_03-11-25.jpg" width="200" alt="Home Screen"/>
	<img src="Moneyco/assets/screenshots/photo_2026-03-15_17-49-28.jpg" width="200" alt="Add Transaction Screen"/>
	<img src="Moneyco/assets/screenshots/photo_2026-03-16_03-11-29.jpg" width="200" alt="Profile Screen"/>
	<img src="Moneyco/assets/screenshots/photo_2026-03-16_03-11-39.jpg" width="200" alt="Profile Dark Mode Screen"/>
</p>

---

## About the Project

Moneyco is a mobile application that helps users track income, expenses, and budget goals in one place. Users can continue in guest mode with local storage or sign in with Google to sync data with Firebase.

### Problem Statement
- Students and individuals need a simple way to track daily finances
- Manual expense tracking is inconsistent and hard to maintain
- Many users need both offline usage and cloud sync
- Budget overspending often happens without timely alerts

### Solution
- Simple income/expense transaction flow
- Local-first guest mode with optional Google sign-in
- Real-time Firestore sync for signed-in users
- Budget monitoring with monthly and daily spending alerts

---

## Core Features

### Authentication System
- Google sign-in and sign-out
- Guest mode support
- Profile details (name, email, photo)

### Transaction Management
- Add income and expense transactions
- Category, amount, note, and date support
- Recent transactions on home dashboard
- Delete transactions

### Analytics
- Monthly income vs expense bar chart
- Expense distribution pie chart
- Balance trend chart

### Budget & Alerts
- Set monthly spending limit
- Set daily expense goal
- Alert on 90% monthly usage and limit exceed
- Alert when daily goal is exceeded

### App Experience
- Dark and light mode
- Offline connectivity awareness
- Pull-to-refresh and smooth animated UI

---

## Technology Stack

| Component | Technology |
|-----------|-----------|
| **Framework** | Flutter 3.x |
| **Language** | Dart 3.x |
| **Backend** | Firebase Authentication + Cloud Firestore |
| **State Management** | Provider |
| **Charts** | fl_chart |
| **Platform Support** | Android, iOS, Web, Desktop |

- Flutter framework
- Course instructors and mentors
