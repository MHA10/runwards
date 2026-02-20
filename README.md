# Runwards

Runwards is a complete Flutter-based fitness rewards mobile application. It incentivizes physical activity by converting steps into "Runward Credits" (RC), which can be redeemed for real-world discounts and vouchers. The app also features a strong social and charitable component through NGO event participation and leaderboards.

## 📱 Features

### 1. Activity Tracking & Dashboard
- **Step Syncing**: Automatically pulls step count data from Apple HealthKit (iOS) and Google Health Connect (Android).
- **Daily Goals**: Visual progress ring for the daily 10,000-step goal.
- **Rewards Calculation**: Algorithm awards 10 RC for every 1,000 steps, plus a 50 RC bonus for hitting the daily goal.
- **Streak Tracking**: Monitors 7-day and 30-day activity streaks to encourage consistency.

### 2. Rewards Marketplace
- **Browse Rewards**: Scrollable grid of offers from partner brands (Food, Apparel, Fitness, Charity).
- **Redemption Flow**: Secure transaction logic to deduct RC and issue unique voucher codes.
- **Filtering**: Filter rewards by category.

### 3. Earn & Ads
- **Rewarded Video Ads**: Integration with Google AdMob to allow users to earn extra RC (capped at 5 ads/day).
- **Confetti Rewards**: Fun visual feedback upon successful ad completion.

### 4. NGO Events
- **Charity Walks**: Users can join sponsored events using a unique 6-digit code.
- **Contribution**: Steps taken during the event period automatically contribute to the collective goal.
- **Donations**: Users can donate their earned RC directly to the cause.
- **Event Leaderboard**: Real-time ranking of top contributors within an event.

### 5. Leaderboard
- **Weekly Rankings**: Compete with other users based on weekly step counts.
- **Global vs. Local**: Toggle between global rankings and users in your specific city.
- **Podium View**: Highlighted UI for the top 3 users.

### 6. User Profile
- **Stats Overview**: Lifetime steps, total RC earned, and vouchers redeemed.
- **Badges System**: Unlockable achievements (e.g., "10k Club", "Week Warrior") based on activity milestones.
- **Heatmap**: Visual representation of activity intensity over the last 30 days.

---

## 🛠 Technical Architecture

Runwards is built with **Flutter** and **Supabase**, following a feature-first architecture and modern state management practices.

### Tech Stack
- **Frontend**: Flutter (Dart) with Null Safety.
- **Backend**: Supabase (PostgreSQL) for Auth, Database, and Realtime subscriptions.
- **State Management**: `flutter_riverpod` (using `StateNotifier` and `AsyncNotifier`).
- **Navigation**: `go_router` for declarative routing and deep linking.
- **Ad Network**: `google_mobile_ads` (AdMob).
- **Health Integration**: `health` package for unified access to health stores.

### Folder Structure
The project follows a **Feature-First** directory structure for scalability:

```
lib/
├── core/                  # Core configuration (Router, Supabase Client, Constants)
├── features/
│   ├── auth/              # Authentication (Login, Splash, Providers)
│   ├── dashboard/         # Home screen, Step logic, Daily stats
│   ├── earn/              # AdMob logic and UI
│   ├── events/            # Event listing, Repositories, Leaderboards
│   ├── leaderboard/       # Global/Local rankings
│   ├── marketplace/       # Rewards grid and redemption logic
│   └── profile/           # User stats, Badges, Heatmap
├── services/              # External services (HealthService, AdService)
└── shared/                # Shared widgets (MainLayout, Buttons)
```

### Database Schema (Supabase)
The app relies on a relational PostgreSQL schema with Row Level Security (RLS) enabled:

- **`users`**: Extends Supabase Auth; stores profile, city, RC balance, and total stats.
- **`step_logs`**: Daily step records for every user.
- **`rewards`**: Catalog of available vouchers and costs.
- **`redemptions`**: Log of user redemptions and generated codes.
- **`ad_views`**: Logs ad watches to enforce daily caps.
- **`events`**: details of NGO campaigns (goals, dates, codes).
- **`event_participants`**: Join table tracking user contributions and donations to events.

---

## 🚀 Setup Instructions

### 1. Prerequisites
- Flutter SDK (3.0+)
- Supabase Project (Free tier works)
- Android Studio / Xcode

### 2. Supabase Configuration
1. Create a new Supabase project.
2. Run the SQL migrations found in `supabase/migrations/` in the Supabase SQL Editor. This will create tables, functions, and RLS policies.
3. Enable Email/Password Auth provider in Supabase.

### 3. Environment Variables
The app uses placeholder keys in `lib/core/config.dart`. Pass your real keys at runtime:

```bash
flutter run --dart-define=SUPABASE_URL=https://your-project.supabase.co --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

### 4. Platform Configuration
**Android (`AndroidManifest.xml`)**:
- `ACTIVITY_RECOGNITION` permission is added.
- Google AdMob App ID is configured (currently using Test ID).

**iOS (`Info.plist`)**:
- `NSHealthShareUsageDescription` and `NSHealthUpdateUsageDescription` added.
- Google AdMob App ID is configured (currently using Test ID).

### 5. Running the App
```bash
# Get dependencies
flutter pub get

# Run on emulator/device
flutter run
```

## 🧪 Testing
The project includes widget tests for core UI components.

```bash
flutter test
```
