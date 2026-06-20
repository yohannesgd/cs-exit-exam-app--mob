# Architecture Overview

## High-Level Design

CS Exit Exam Ethiopia is built using a modular architecture with clear separation of concerns.

### Core Principles

- **Separation of Concerns** – UI, business logic, and data are separated
- **Single Responsibility** – Each class has one reason to change
- **Dependency Injection** – Services are injected, not instantiated directly

---

## Data Flow Diagram
User Action → Widget → Provider → Service → Database/File → Response → UI Update

## State Management

The app uses **Provider** for state management:

- `ThemeProvider` – Manages dark/light theme
- `QuizProvider` – Manages quiz state (questions, answers, results)
- `UserProvider` – Manages user progress

---

## Database Design

### Results Table

| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER | Primary key |
| subject_id | INTEGER | Subject identifier |
| score | REAL | Percentage score |
| correct_count | INTEGER | Number correct |
| total_questions | INTEGER | Total questions |

### Progress Table

| Column | Type | Description |
|--------|------|-------------|
| subject_id | INTEGER | Subject identifier |
| best_score | REAL | Highest score |
| total_attempts | INTEGER | Number of attempts |

---

## Security Considerations

- No network calls (100% offline)
- No personal data collected
- Data stored locally using SQLite
- Keystore protected (not in repository)