# Smoke Test: Pomodoro + Task Manager (Android APK)

Tests droid persistence across a large multi-module productivity app with foreground services, Room DB, WorkManager, and statistics. Expected runtime: 10-14+ hours.

## The Prompt

```
droid Build a complete productivity app combining a Pomodoro timer with task management as a native Android app in Kotlin with Jetpack Compose. Generate a signed APK.

REQUIREMENTS:

Core features:

1. TASK MANAGEMENT
- Create tasks with: title (required), description (optional), estimated pomodoros (1-10), priority (Low/Medium/High/Urgent), due date (optional), project/category tag
- Task states: Todo, In Progress, Done, Archived
- Drag-to-reorder tasks within each state column
- Swipe right to complete, swipe left to delete with undo snackbar (5 second window)
- Subtasks: each task can have checklist subtasks (text + checkbox), progress bar shows completion percentage
- Recurring tasks: daily, weekdays, weekly, monthly — auto-recreate on completion
- Task search: full-text search across title and description
- Bulk actions: long-press to select multiple, then complete/delete/move/change priority
- Sort by: priority, due date, estimated effort, creation date, alphabetical

2. POMODORO TIMER
- Standard intervals: 25min work, 5min short break, 15min long break (every 4 pomodoros)
- All intervals customizable in settings (work: 15-60min, short break: 3-15min, long break: 10-30min, long break interval: 2-8)
- Timer runs as a foreground service with persistent notification showing:
  - Current phase (Work/Short Break/Long Break)
  - Time remaining (MM:SS)
  - Task name if linked to a task
  - Pause/Resume and Skip buttons in notification
- Timer links to a task: when starting a pomodoro, select from task list or create new
- Auto-start next phase option (work → break → work) or pause between phases
- When work pomodoro completes: increment task's completed pomodoros counter
- Visual timer: circular progress ring filling counter-clockwise, color changes by phase (red=work, green=short break, blue=long break)
- Screen stays on during active pomodoro (FLAG_KEEP_SCREEN_ON)
- Timer vibration pattern at phase end: 3 short pulses for break end, 2 long pulses for work end

3. STATISTICS & ANALYTICS
- Daily view: pomodoros completed per task shown as horizontal bar chart
- Weekly view: total pomodoros per day as vertical bar chart (Mon-Sun), average line overlay
- Monthly calendar heatmap: color intensity by pomodoros completed that day (like GitHub contribution graph)
- Streak tracking: consecutive days with at least 1 completed pomodoro
- Current streak and longest streak displayed
- Focus time: total hours in pomodoro work sessions this day/week/month
- Task completion rate: completed vs total tasks per week
- Productivity score: weighted formula: (completed_pomodoros × 10) + (completed_tasks × 20) + (streak_days × 5), displayed as daily score with trend arrow
- Export statistics as CSV: date, task name, pomodoros completed, duration

4. PROJECTS/CATEGORIES
- Create projects with name and color
- Assign tasks to projects
- Project view: see all tasks grouped by project
- Project statistics: total pomodoros, completion rate, time spent
- Default projects: "Work", "Personal", "Learning" (deletable)

5. DAILY PLANNER
- Daily view showing today's tasks ordered by priority
- "Plan My Day" flow: shows unfinished tasks, user drags them into today's plan with time estimates
- Daily goal: set target pomodoros for the day (default 8), progress ring on home screen
- End of day summary notification at configurable time (default 8pm): pomodoros done, tasks completed, streak status

Screens (7 total + overlays):

1. HOME SCREEN (default)
   - Top: greeting ("Good morning, [time-based]"), today's date, streak flame icon with count
   - Daily goal progress ring (large, center) with "4/8 pomodoros" text
   - Quick-start pomodoro button (large FAB)
   - Today's tasks list (scrollable, shows top 5 by priority, "See all" link)
   - Bottom nav: Home, Tasks, Timer, Stats, Settings

2. TASKS SCREEN
   - Tab row: "All", "Today", "Upcoming", "Done"
   - Each tab shows filtered task list with task cards:
     - Priority color bar on left edge
     - Title, project tag chip, due date if set
     - Pomodoro progress: filled/empty tomato icons (e.g., 3/5)
     - Subtask progress bar if has subtasks
   - FAB: create new task
   - Search bar at top (expandable)
   - Filter chips: by project, by priority
   - Sort dropdown

3. TASK DETAIL SCREEN
   - Full task info: title, description, priority selector, project selector, due date picker
   - Subtask checklist (add/edit/delete/reorder)
   - Pomodoro history for this task (list of completed sessions with timestamps)
   - "Start Pomodoro" button linking to this task
   - Edit/Delete actions in top bar
   - Time tracking summary: total focus time on this task

4. TIMER SCREEN
   - Large circular timer (takes 60% of screen height)
   - Phase indicator: "WORK", "SHORT BREAK", "LONG BREAK" with color
   - Linked task name below timer (tap to change)
   - Session counter: "Pomodoro 2 of 4" before long break
   - Controls: Start/Pause (large center button), Reset (left), Skip (right)
   - Today's completed pomodoros shown as small filled circles at bottom

5. STATISTICS SCREEN
   - Tab row: "Daily", "Weekly", "Monthly"
   - Daily: today's pomodoro bar chart by task, total focus time, tasks completed
   - Weekly: 7-day bar chart with pomodoro counts, average line, weekly totals
   - Monthly: GitHub-style calendar heatmap, monthly totals
   - Streak card: current streak with flame animation, longest streak
   - Productivity score card with trend
   - Export button (top-right): generates CSV and opens share sheet

6. SETTINGS SCREEN
   - Timer section: work duration slider, short break slider, long break slider, long break interval, auto-start toggle
   - Notifications section: enable/disable, daily summary time picker, sound selection
   - Appearance section: theme (light/dark/system), accent color picker (6 options)
   - Data section: export all data as JSON, import data, clear all data (with confirmation)
   - About section: version, licenses

7. CREATE/EDIT TASK SCREEN
   - Title text field (required, show error if empty on save)
   - Description text field (multiline, optional)
   - Priority selector (4 radio buttons with color indicators)
   - Project dropdown (with "Create new" option inline)
   - Due date picker (Material3 date picker)
   - Estimated pomodoros stepper (1-10)
   - Recurring toggle with frequency selector
   - Subtasks section: add subtask text fields dynamically
   - Save/Cancel buttons

Architecture:
- Multi-module: :app, :core:data, :core:domain, :core:ui, :feature:tasks, :feature:timer, :feature:stats, :feature:settings
- :core:domain — entities (Task, Pomodoro, Project, DailyStats), use cases, repository interfaces — pure Kotlin, zero Android dependencies
- :core:data — Room database (tasks, pomodoros, projects, daily_stats tables), DataStore for settings, repository implementations, mappers between entities and database models
- :core:ui — shared composables (PomodoroRing, TaskCard, PriorityIndicator), theme, design tokens
- :feature:* — screens, ViewModels, navigation
- :app — Hilt setup, navigation host, foreground service, notification channels, work manager for recurring tasks and daily summaries
- Room database schema:
  - tasks: id, title, description, priority (enum), project_id (FK), due_date, estimated_pomodoros, completed_pomodoros, state (enum), sort_order, is_recurring, recurrence_rule, created_at, updated_at
  - subtasks: id, task_id (FK), text, is_completed, sort_order
  - pomodoros: id, task_id (FK nullable), started_at, ended_at, duration_minutes, phase (enum: work/short_break/long_break), completed (boolean)
  - projects: id, name, color (hex string), created_at
  - daily_stats: date (PK), pomodoros_completed, focus_minutes, tasks_completed, productivity_score
- Database migrations: start with version 1, include a migration test that creates v1 and verifies schema
- Navigation: Compose Navigation with type-safe routes
- Foreground service: TimerService extends LifecycleService, posts ongoing notification, uses coroutine for countdown, communicates with ViewModel via shared Flow
- WorkManager: daily summary notification job, recurring task creation job
- Hilt: module per layer, @Singleton for database and repositories

Testing (exhaustive):
- Unit tests for EVERY use case in :core:domain (at least 15 use cases):
  - CreateTask, UpdateTask, DeleteTask, GetTasksByState, GetTasksByProject
  - StartPomodoro, CompletePomodoro, SkipPhase, GetNextPhase
  - CalculateDailyStats, CalculateWeeklyStats, GetStreak
  - CreateProject, GetProjectStats
  - SearchTasks, BulkUpdateTasks
- Unit tests for timer logic: countdown accuracy, phase transitions (work→short break→work→short break→work→short break→work→LONG break), auto-start behavior, pause/resume preserving remaining time
- Unit tests for recurring task logic: daily creates next day, weekly creates next week, monthly handles month-end edge cases (Jan 31 → Feb 28)
- Unit tests for productivity score calculation
- Unit tests for streak calculation (handles gaps, timezone boundaries)
- Unit tests for CSV export formatting
- Room database tests (@Room database test with in-memory database):
  - CRUD for all 5 tables
  - Foreign key constraints (delete project cascades or restricts)
  - Query tests for filtered task lists, statistics aggregation
  - Migration test
- ViewModel tests with fake repositories:
  - TaskListViewModel: load tasks, filter, sort, search, bulk operations
  - TimerViewModel: start, pause, resume, skip, complete, phase transitions
  - StatsViewModel: daily/weekly/monthly aggregation, streak, export
- UI tests (Compose):
  - Create task flow: fill form, save, verify appears in list
  - Start pomodoro: select task, start timer, verify timer counts down
  - Complete task: swipe right, verify moves to Done tab
  - Navigation: verify all 5 bottom nav destinations reachable

Build configuration:
- Min SDK 26, target SDK 34, compile SDK 34
- Kotlin 2.0+, Compose BOM latest, Hilt, Room, Navigation Compose, WorkManager, DataStore
- KSP for Room and Hilt annotation processing
- Debug and release APKs with generated keystore
- ProGuard/R8 rules for all libraries
- Adaptive app icon: tomato (red circle with green leaf) on white background, drawn as vector
- Build with: ./gradlew :app:assembleDebug :app:assembleRelease
- Run ALL tests across ALL modules: ./gradlew test connectedAndroidTest
- Fix ALL failures before generating final APKs
- Verify APKs with aapt dump badging
```

## What to Verify

- [ ] Droid skill activated (check for `.gemini/state/droid.json`)
- [ ] Model did not pause to ask "shall I continue?" between major phases
- [ ] Multi-module Gradle setup builds successfully
- [ ] Foreground service and WorkManager configured correctly
- [ ] Room database with all 5 tables and migrations
- [ ] All unit tests pass across all modules
- [ ] Both debug and release APKs generated
- [ ] Total session time logged
- [ ] Session survived at least one context compression (check session-notes if created)
