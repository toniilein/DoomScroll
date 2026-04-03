# DoomScroll — Product Requirements Document
### For Sales & Marketing Teams

---

## 1. Product Overview

**Product Name:** DoomScroll
**Platform:** iOS (iPhone & iPad)
**Minimum OS:** iOS 16.2+
**Category:** Health & Wellness / Digital Wellbeing
**Target Audience:** Gen Z and Millennials who want to reduce screen time in an engaging, non-judgmental way

**One-Liner:** DoomScroll is a screen time tracker with a living kraken mascot that reacts to your phone habits — turning digital wellness into a game you actually want to play.

---

## 2. Value Proposition

| Pain Point | DoomScroll Solution |
|---|---|
| Screen Time app is boring and easy to ignore | Gamified experience with mascot, quests, streaks, and achievements |
| Users don't understand "4h 32m" means anything | Brain Rot Score (0–100) makes usage instantly meaningful |
| Existing blockers feel punitive | Friendly kraken encourages you — moods shift based on your behavior |
| No social accountability | Shareable achievement cards for Instagram/TikTok stories |
| One-size-fits-all limits | Per-app-group limits, schedule-based routines, and quick-block panic button |

---

## 3. Core Features

### 3.1 The Kraken Mascot

A charming animated octopus that lives on the Overview screen and reacts to your daily screen time.

**4 Mood States:**

| Mood | Screen Time | Visual | Personality |
|---|---|---|---|
| Ecstatic | Under 2 hours | Bright green, sparkles, huge smile | "You're a legend!" |
| Happy | 2–4 hours | Soft teal, gentle bounce | "Not bad, keep it up!" |
| Sad | 4–6 hours | Muted purple, droopy eyes | "I'm worried about you..." |
| Zombie | 6+ hours | Dark red, X eyes, skull particles | "Brain... melting..." |

- Speech bubbles with contextual messages
- Animated body, tentacles, and particle effects
- Mood changes in real time as usage accumulates

### 3.2 Brain Rot Score (0–100)

A single number that tells users how "brain-rotted" they are today.

- Based on screen time relative to user's personal daily limit
- Non-linear scale: first 50% of limit = low score, exceeding limit = rapid climb
- Never hits 100 — there's always room to get worse (or better)
- Color-coded: Green (healthy) → Blue (moderate) → Purple (excessive) → Pink (terminal)

### 3.3 4-Tier System

| Tier | Score Range | Name | Description |
|---|---|---|---|
| 1 | 0–29 | Digital Monk | Barely touched your phone |
| 2 | 30–59 | Grass Toucher | Healthy balance |
| 3 | 60–84 | Doomscroller | Over your limit |
| 4 | 85–100 | Brainrot | Terminal phone addiction |

- Visual tier status bar under the kraken
- Tier gallery showing all levels with time ranges
- Tier determines kraken mood, colors, and messages

### 3.4 Shield — App Blocking Suite

Three powerful blocking modes on the Shield tab:

**Quick Block (Panic Button)**
- One tap to instantly block selected apps
- Choose which apps/categories to block
- Toggle on/off instantly — no waiting

**Usage Limits (Time-Based)**
- Set daily time limits per app group (e.g., "Social Media: 1 hour")
- Real-time usage tracking with progress bars
- Apps automatically blocked when limit is exceeded
- Per-day scheduling (e.g., weekdays only)
- Multiple independent limits

**Block Routines (Schedule-Based)**
- Set recurring block schedules (e.g., "Work Mode: 9 AM–5 PM")
- Automatic activation/deactivation
- Weekday selection (every day, weekdays, weekends, or custom)
- Pre-seeded templates: Morning Focus, Work Mode, Night Wind Down

**Unblock All** — Emergency override button to disable everything instantly.

### 3.5 Challenges & Gamification

**3 Daily Quests:**

| Quest | Goal | Target |
|---|---|---|
| Slay the Score | Keep Brain Rot Score below 50 | Score < 50 |
| Time Bandit | Stay under half your daily limit | Screen time ≤ limit/2 |
| Hands Off! | Keep phone pickups under 30 | Pickups ≤ 30 |

- Progress rings show real-time completion
- Kraken mood improves as quests are completed

**Streak System:**

| Streak Length | Tier Name |
|---|---|
| 1–6 days | Bronze |
| 7–13 days | Silver |
| 14–29 days | Gold |
| 30–59 days | Diamond |
| 60+ days | Legendary |

- Milestone messages at key days (3, 7, 14, 30, 60, 100)
- Best streak tracked for bragging rights
- Interactive streak calendar with heat map

**9 Achievements:**
- Grass Toucher — Score under 20
- Zen Master — Score of 0
- Terminal Brainrot — Score over 90
- Phone Addict — 50+ pickups
- Pickup Artist — 80+ pickups
- Marathon Scroller — 3+ hours screen time
- Week Warrior — 7-day streak
- Monthly Master — 30-day streak
- Diamond Hands — 60-day streak

### 3.6 Brain Health Analytics

Weekly analytics dashboard with:
- 7-day screen time trends
- Per-app and per-category breakdowns
- Pickup frequency tracking
- Longest session duration
- Smart KPIs and weekly trend visualization
- Day-by-day breakdown with selectable days

### 3.7 Shareable Achievement Cards

- Beautiful cards featuring the kraken mascot
- Shows tier name, streak count, and score
- Branded with "DoomScroll — Track your screen time"
- Native iOS share sheet (Instagram Stories, TikTok, iMessage, etc.)
- Designed for social media virality

### 3.8 Personalized Settings

- **Daily Limit Slider:** 30 minutes to 8 hours (in 30-min steps)
- **App Selection:** Choose which apps count toward your score
- **Score Preview:** See what your score would be at different usage levels
- **Track All vs. Specific:** Toggle between monitoring everything or just selected apps

---

## 4. Technical Highlights (for partnership & integration conversations)

- Built 100% natively in **SwiftUI** — fast, smooth, battery-efficient
- Uses Apple's **Screen Time API** (FamilyControls, DeviceActivity, ManagedSettings)
- All data stays **on-device** — no cloud, no tracking, no accounts required
- App group container for **real-time cross-process sync** between app and extensions
- **8 custom Device Activity Report extensions** for live data processing
- Shield enforcement runs as a **background system extension** — works even when app is closed

---

## 5. User Journey

```
Download → Onboarding (grant Screen Time access)
    → Overview: See kraken + score + daily screen time
    → Challenges: Complete 3 daily quests, build streak
    → Shield: Set up limits and routines
    → Share: Post achievement card to socials
    → Return daily: Feed the streak, watch the kraken
```

**Retention Hooks:**
1. Daily quests reset each morning — reason to open every day
2. Streak counter creates loss aversion — don't break the chain
3. Kraken mood creates emotional connection — users don't want to disappoint it
4. Achievement unlocks reward exploration
5. Social sharing creates accountability

---

## 6. Competitive Landscape

| Feature | DoomScroll | Apple Screen Time | Opal | One Sec |
|---|---|---|---|---|
| Gamification | Full (quests, streaks, achievements) | None | Basic | None |
| Mascot/Character | Animated kraken | None | None | None |
| Social Sharing | Native share cards | None | Limited | None |
| App Blocking | 3 modes (quick, timed, scheduled) | Basic limits | Yes | Friction-based |
| Tier System | 4 tiers with progression | None | None | None |
| Price Model | TBD | Free (built-in) | Subscription | Subscription |
| Emotional Design | High (mascot reacts to behavior) | Low | Medium | Medium |

**Key Differentiator:** DoomScroll is the only screen time app that makes reducing phone usage feel like a game with an emotional companion, not a punishment.

---

## 7. Key Metrics to Track (for Marketing)

| Metric | What It Shows |
|---|---|
| DAU / MAU | Daily vs monthly engagement (streak drives DAU) |
| Avg. streak length | How sticky the gamification is |
| Quest completion rate | Are users engaging with challenges? |
| Share card generation | Viral loop activation |
| Avg. score over time | Are users actually reducing screen time? |
| Limit/routine creation rate | Shield feature adoption |
| Tier distribution | What percentage of users hit each tier |

---

## 8. Marketing Angles

**For Gen Z / TikTok:**
- "Your phone is giving you brainrot. This app has receipts."
- "My kraken is disappointed in me" (emotional mascot content)
- "Day 30 streak — Diamond tier unlocked" (achievement flex)
- Share card designed for Stories/Reels

**For Wellness / Health:**
- "Know your Brain Health score"
- Weekly analytics dashboard for self-improvement
- "Screen time awareness without the guilt"

**For Productivity:**
- "Block distracting apps in one tap"
- Schedule-based routines for work/study/sleep
- Per-app-group time limits that actually enforce

**For Parents (future):**
- Family sharing capabilities (leverages Apple's FamilyControls framework)
- Set limits for children's devices
- Monitor screen time trends

---

## 9. Roadmap Opportunities

- **Widgets:** Lock screen widget showing score + kraken mood
- **Push Notifications:** Streak reminders, limit warnings, achievement unlocks
- **Apple Watch:** Glanceable score + quick block from wrist
- **Social Features:** Friend leaderboards, challenge friends
- **Custom Themes:** Unlock kraken skins/accessories with streak milestones
- **AI Insights:** Personalized tips based on usage patterns
- **Android Version:** Expand market reach

---

## 10. Brand Identity

**Visual Language:**
- Warm cream backgrounds (#F4F3EE) — not sterile white
- Soft, rounded accent colors — orange, green, blue, purple
- Rounded bold typography (.rounded design)
- Playful but not childish — appeals to 18–35 demographic

**Tone of Voice:**
- Encouraging, not preachy
- Self-aware humor ("brainrot", "doomscroller")
- Uses internet-native language Gen Z relates to
- The kraken speaks like a supportive friend, not a parent

**App Icon / Branding:** "DoomScroll" — provocative name that's instantly understood by the target audience. Leans into the problem rather than away from it.

---

*Document generated from codebase analysis — April 2026*
