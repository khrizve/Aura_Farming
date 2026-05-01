# ⚔️ Aura Farming

> *"Arise."* — Sung Jin-Woo

A **Solo Leveling-inspired habit tracker** built with Flutter. Complete daily quests, level up your Aura, unlock inventory rewards, and become the Shadow Monarch of your own life.

---

## 🌑 What is Aura Farming?

Aura Farming turns your real-life habits and goals into an RPG progression system. Inspired by the manhwa/anime **Solo Leveling**, you don't just track habits — you **hunt quests**, **earn skill points**, **level up your character**, and **collect legendary rewards** for staying consistent.

The System has chosen you. Will you rise?

---

## ✨ Features

### 🧍 Character & Aura System
- Your character **visually evolves** as you gain Aura Levels
- 4 distinct character forms unlocking at levels 1, 4, 7, and 10+
- Aura XP earned by completing quests feeds into a living progression bar

### ⚔️ Quest System
- **Daily Quests** — reset every midnight, keeping you accountable each day
- **Weekly Quests** — longer-term challenges for bigger rewards
- **Timed Quests** — real-time countdowns for time-boxed habits (e.g. "Meditate for 20 minutes")
- **Custom Quests** — create your own habits with custom names, categories, XP, and duration
- **Time-locked Quests** — set quests that are only available during specific hours or days of the week

### 🧠 Skill System
- Multiple skill trees (Strength, Intelligence, Endurance, etc.)
- Spend **Skill Points** earned from quests to level up individual skills
- Each skill has its own XP bar and level progression

### 🎒 Inventory & Rewards
- Unlock collectible items as you level up your Aura:
  - 🃏 **Aura Cards** — every 3 levels
  - 🗡️ **Fantasy Weapons** — every 5 levels
  - 🐉 **Magical Pets** — every 7 levels
  - 🌑 **Dark Shadows** — every 10 levels
- Items come in 5 rarity tiers: **Common → Rare → Epic → Legendary → Mythical**
- Special achievement items for milestone streaks (7 days, 30 days) and mastering all skills

### 🔥 Streak Tracking
- Daily streak counter with longest streak record
- Completion history with a mini calendar heatmap
- Streak-based achievement rewards to keep the grind going

### 📅 Calendar & Progress
- Monthly mini-calendar showing daily quest completion density
- Horizontal swipe between streak view and calendar view on the Home screen

---

## 🗂️ Project Structure

```
lib/
├── main.dart                  # App entry point & state management
├── screens/
│   ├── home_screen.dart       # Character, aura, streak, skills overview
│   ├── quest_screen.dart      # Quest list, timed quests, custom quest builder
│   ├── inventory_screen.dart  # Item collection & rarity browser
│   └── more_screen.dart       # Settings & about
├── models/
│   ├── aura_level.dart        # XP & level progression logic
│   ├── quest.dart             # Quest model with time validation & timers
│   ├── skill.dart             # Skill leveling & skill point logic
│   ├── inventory_item.dart    # Item categories, rarities & stats
│   └── streak.dart            # Streak tracking & completion history
├── widgets/                   # Reusable UI components
├── data/                      # Default quests, skills & inventory seed data
├── services/
│   └── storage_service.dart   # Local persistence (SharedPreferences)
└── utils/
    └── theme_data.dart        # Dark magical theme & gradients
```

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.0 or higher)
- Dart 3.x
- Android Studio / VS Code with Flutter extension
- An Android or iOS device / emulator

### Installation

```bash
# Clone the repository
git clone https://github.com/your-username/aura-farming.git
cd aura-farming

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Build for Release

```bash
# Android APK
flutter build apk --release

# iOS (requires macOS + Xcode)
flutter build ios --release
```

---

## 📦 Dependencies

| Package | Purpose |
|---|---|
| `table_calendar` | Mini calendar widget for habit heatmap |
| `shared_preferences` | Local data persistence |
| `flutter` | UI framework |

---

## 🎮 How to Play

1. **Open the app** — your Hunter profile awaits at Level 1
2. **Go to Quests** — complete daily and weekly quests to earn XP and Skill Points
3. **Watch your Aura grow** — your character evolves as you level up
4. **Spend Skill Points** — invest in your skills from the Home screen
5. **Check your Inventory** — rare items unlock as you hit level milestones
6. **Keep your streak alive** — consistency is how Hunters become Monarchs

---

## 🌟 Rarity Tiers

| Tier | Color | Unlock Condition |
|---|---|---|
| ⬜ Common | Grey | Level 1–3 |
| 🟦 Rare | Blue | Level 4–6 |
| 🟪 Epic | Purple | Level 7–9 |
| 🟧 Legendary | Orange | Level 10–14 |
| 🟥 Mythical | Red | Level 15+ |

---

## 🛠️ Planned Features

- [ ] Push notifications for daily quest reminders
- [ ] Boss Battle mode — weekly challenge quests with big rewards
- [ ] Party system — share streaks with friends
- [ ] Cloud sync / backup support
- [ ] Animated character evolution cutscenes
- [ ] Custom themes (Shadow Monarch, Brilliant Flame, Iron Body)
- [ ] Widget support for home screen quick-check

---

## 🙏 Inspiration

This app is a love letter to **Solo Leveling** (*나 혼자만 레벨업*) by Chugong. The System, the shadows, the relentless grind to become stronger — all of it maps surprisingly well onto building real-world habits.

> *The weak don't get to choose how they die.*
> You do get to choose how you level up. Make it count.

---

## 📄 License

This project is licensed under the Apache 2.0 License. See [LICENSE](LICENSE) for details.

Solo Leveling and all related characters/concepts are the property of Chugong, D&C Media, and Kakao Entertainment. This is a fan-made project with no commercial intent.

---

## 🤝 Contributing

Pull requests are welcome! If you have ideas for new quest types, skill categories, or inventory items, open an issue and let's build it together.

1. Fork the repo
2. Create your feature branch: `git checkout -b feature/shadow-army`
3. Commit your changes: `git commit -m 'Add shadow soldier companion system'`
4. Push to the branch: `git push origin feature/shadow-army`
5. Open a Pull Request

---

<p align="center">
  <i>Built by a Hunter, for Hunters. 🖤</i>
</p>
