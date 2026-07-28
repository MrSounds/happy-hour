# Happy Hour

Happy Hour is an iPhone app that helps people protect one hour each day for activities that make them feel happier, calmer, more energised, or more like themselves.

## The idea

The app is built around a personal **Happy Hour**: a one-hour appointment with yourself. Instead of a generic habit tracker or task list, it gives that hour a clear place in the week and makes it feel worth looking forward to.

Each day can have its own hour, time, and set of activities. The plan repeats weekly until the user changes it.

### Example weekly plan

| Day | Happy Hour | Activities |
| --- | --- | --- |
| Monday | 13:00–14:00 | Go for a run, take a cold shower |
| Tuesday | 09:00–10:00 | Meditate, take a cold shower, play guitar |

## Core experience

1. The user sets up a Happy Hour for each day of the week.
2. For every hour, they choose a start time and one or more activities.
3. The weekly plan repeats automatically.
4. When the hour starts, the app sends a friendly notification with the day’s activities.
5. The main screen keeps the selected day, time, and activities visible without
   completion pressure, countdowns, or streaks.

## First iPhone version

- Weekly planner for setting a time and activities for each day.
- A large, centred beer mug that contains the selected day’s activity rows.
- One to ten custom activities per configured day, with optional detail notes.
- Local notifications when Happy Hour starts.
- A calm, low-pressure weekly overview without checklists or completion tracking.
- One-off calendar export from the day editor, with no later synchronisation.

## UX direction

The first version should feel calm, personal, and intentionally simple.

### Main screen

- A near-black background and one large, realistic beer mug as the main focus.
- “Happy Hour” is centred in the top bar, with settings on the left and a pencil
  for editing the selected day on the right.
- A Monday-to-Sunday strip and the selected Happy Hour time sit above the mug.
- Swipe left and right to move between days, or select a day directly in the strip.
- The mug body stays centred on screen while its large glass handle can extend
  beyond the right edge.

### Activities inside the beer mug

- Every activity is shown as a horizontal row inside the mug.
- Five rows fill the usable interior. With fewer than five activities, rows keep
  the same height at the bottom while white foam fills the unused space above.
  With six to ten activities, all rows shrink evenly to fit.
- A permanent foam crown, glass highlights, a subtle amber glow, and a heavy glass
  base make the mug feel dimensional. The foam is decorative and never indicates
  progress or completion.
- Each row has a muted, warm colour so the mug feels visual rather than like a
  task list. Suitable colours include dusty sage, blue-grey, lavender, sand, and
  soft terracotta.
- The row shows a short activity name, such as “Cold shower.”
- The whole row opens its optional details, with a small right-pointing chevron
  as the visual affordance. Rows have no activity icons.

### Editing

- Add, rename, reorder, and remove activities.
- Set a start and end time; one hour is the default, but longer intervals are allowed.
- Add the selected Happy Hour to Calendar from inside the editor. The main screen
  has no separate calendar or bottom edit controls.
- Keep editing separate from the viewing experience, so the everyday screen stays peaceful and focused.

### Design guardrails

- Maximum ten activities per day.
- No account or social features in version one.
- No guilt mechanics, streaks, or pressure if the user misses or moves a Happy Hour.

## Locked decisions for version one

- **Platform and UI:** iPhone app built with SwiftUI.
- **Data:** the weekly plan and activities are stored locally on the device. There are no accounts, sign-in, or cloud sync in version one.
- **Notifications:** onboarding asks for notification permission; the app sends a reminder when the day’s Happy Hour begins.
- **Calendar:** include a simple “Add to Calendar” action inside the day editor.
  It creates the selected Happy Hour as a single calendar event; there is no
  ongoing calendar sync in version one.
- **Scope:** one Happy Hour per weekday, with a default duration of one hour and an option to choose a longer interval.

## Product principles

- **Joy before productivity:** the app should support a better life, not add another obligation.
- **Simple enough to keep using:** planning and changing the week should take only a few moments.
- **Flexible, never punishing:** skipping or moving an hour is normal.
- **Personal:** the activities and schedule are entirely the user’s own.

## Future possibilities

- Reflection after an hour: “How did this make you feel?”
- Helpful weekly suggestions based on what the user enjoys.
- Widgets and Apple Watch support.
- Shared Happy Hours with a friend or partner.

## Development

The app follows the current, locked version-one brief. Some of the product notes
above describe possible later directions; checklists, completion tracking,
rescheduling completed hours, suggestions, reflections, streaks, widgets, sharing,
and Apple Watch support are intentionally outside the current build.
The version-one interface language is Norwegian Bokmål.

### Requirements

- The current stable Xcode with Swift 6 support.
- An iPhone simulator or device running iOS 17 or later.
- An Apple Developer Team is only required for signing a physical-device build or
  archive. Simulator builds and tests do not require signing.
- No third-party packages or external services are required.

### Open, run, and test

Open `HappyHour.xcodeproj`, select the shared `HappyHour` scheme and an iPhone
destination, then run the app. Use **Product → Test** (`⌘U`) to run the unit and UI
test targets together.

Pull requests and pushes to `main` run the same shared scheme in GitHub Actions.
CI discovers an available simulator from the latest installed iOS runtime instead
of depending on a particular iPhone model.

### Architecture

The source is organised by responsibility:

- `App` owns startup, navigation, and app-wide state.
- `Domain` contains weekdays, plans, activities, drafts, and validation rules.
- `Features` contains the SwiftUI onboarding, weekly pager, editor, settings, and
  supporting screens.
- `Services` contains SwiftData persistence, schedule calculations, local
  notifications, and one-off EventKit export.
- `DesignSystem` contains the beer-mug presentation, colour tokens, and shared
  styling.

System-facing behaviour is behind small injectable types so scheduling,
notification reconciliation, calendar event construction, and persistence can be
tested without relying on live system services.

### Local data and privacy

Happy Hour has no account, server, analytics, tracking, CloudKit container, or
network dependency. Plans are stored locally with SwiftData and local notification
requests contain activity names, never activity details. “Add to Calendar” presents
Apple’s event editor for one explicit event; the app does not retain its identifier
or synchronise later changes. A calendar selected by the user may still sync
through that calendar provider. Removing the app removes its local plan unless the
device restores it through an operating-system backup.
