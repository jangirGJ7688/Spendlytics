# Spendlytics

Spendlytics is an AI-powered expense tracking app built with **SwiftUI** and **SwiftData**.  
It helps users track spending, visualize financial trends, and receive AI-generated insights about their spending habits.

The app combines modern iOS technologies with intelligent analytics to give users a clear understanding of their financial behavior.

---

## General Information

Spendlytics allows users to:

- Track daily expenses
- Categorize spending
- Visualize spending patterns with charts
- Get AI-powered financial insights based on their spending behavior

The goal of the app is to make personal finance tracking simple, insightful, and intelligent.

---

## App Features

### Expense Management
- Add new expenses with category, amount, and date
- Delete expenses
- Automatic persistence using **SwiftData**

### Smart Filtering & Search
- Filter expenses by category
- Filter by date range
- Search expenses by title
- Filter by price range

### Analytics Dashboard
- Category-based pie chart
- Last 3 months spending chart
- Last 4 weeks spending chart
- Summary of total spending

### AI Financial Insights
- AI-generated insights based on user spending
- Insights generated using **Google Gemini API**
- Clean, minimal insight cards

Example insights:
- "Shopping accounts for the majority of your spending."
- "Food expenses are relatively low compared to discretionary purchases."

### Modern UI
- Built with **SwiftUI**
- Clean fintech-style UI
- Smooth animations and modern layouts

---

## Technologies Used

- **Swift**
- **SwiftUI**
- **SwiftData**
- **Swift Charts**
- **Google Gemini API**
- **MVVM Architecture**
- **Xcode**

---

## Architecture

The app follows the **MVVM architecture** to separate UI, business logic, and data handling.
Views → ViewModels → Services → API / Data Layer

Project structure:
Spendlytics
│
├── Models
├── Views
├── ViewModels
├── Services
└── Assets


---

## How to Run the App

1. Clone the repository
2. Open the project in **Xcode**
3. Add your **Gemini API Key**

Inside:InsightsService.swift
Replace:YOUR_API_KEY

with your actual API key. (My APIKey is already deleted)

4. Build and run the app on:

- iOS Simulator
- Physical iPhone

---

## How to Use the App

1. Open the app
2. Add expenses using the **Add Expense** button
3. View your expenses on the **Home Screen**
4. Apply filters or search for specific transactions
5. Open the **Summary Screen** to view analytics and charts
6. Check the **AI Insights section** to understand spending behavior

---

## Author

Ganpat Jangir

iOS Developer

---

## License

This project is open-source and available under the MIT License.
