# Flutter Week View — Implementation Plan

Goal: migrate the Qt `WeekView` + `EventSidebar` + `PlanFooter` screens into a Flutter
`feature_week_view` package that plugs into the existing Strangler Fig infrastructure
(`go_router`, `design_system`, `core` providers, Riverpod).

No third-party calendar packages. The layout is straightforward Flutter
(`Column`/`Row`/`ListView`) and the stacking algorithm is a clean Dart port of
`CalendarUtils::buildWeekGrid`.

---

## What is being replicated

| Qt component | Flutter equivalent |
|---|---|
| `WeekView.qml` — 7-col × unit-band grid | `WeekGrid` widget (custom `Column`/`Row`) |
| `CalendarUtils::buildWeekGrid` — stacking | `buildWeekGrid()` pure Dart function |
| `WeekPlanCell.qml` — filled / empty chip | `PlanCell` widget |
| `EventSidebar.qml` — list + edit form | `PlanSidebar` widget (slide-in drawer) |
| `PlanFooter.qml` — hours summary bar | `HoursFooter` widget |
| Unit filter state | Riverpod `unitFilterProvider` |
| Week navigation (prev / next) | `weekProvider` + toolbar arrows |

---

## Phase 1 — Dart data layer

**What:** add the providers and pure-Dart logic that the grid depends on.
No UI in this phase.

**Deliverables:**

1. **`units_provider.dart`** in `flutter/packages/core/lib/src/providers/`
   - `unitsProvider`: `FutureProvider<List<Unit>>` calling `GetUnits` RPC once,
     caching with `keepAlive`.
   - `Unit` model: `{int id, String name}` (already in proto as `Unit` message —
     map from `GetUnitsResponse`).

2. **`routes_provider.dart`** in `flutter/packages/core/lib/src/providers/`
   - `routesProvider`: same pattern for `GetRoutes`.
   - `Route` model: `{int id, String name}`.

3. **`week_grid.dart`** in `flutter/packages/core/lib/src/`
   - `buildWeekGrid(List<Unit> units, List<Plan> plans, DateTime weekStart)` —
     pure Dart port of `CalendarUtils::buildWeekGrid` from `calendarutils.cpp`.
   - Returns `List<WeekRow>` where `WeekRow` is a sealed class:
     ```dart
     sealed class WeekRow {}
     class HeaderRow extends WeekRow { final int unitId; final String unitName; }
     class PlanRow   extends WeekRow { final int unitId; final int slotIndex;
                                       final List<Plan?> dayPlans; /* length 7 */ }
     ```
   - Unit tests: empty plans, single unit single plan, overlapping plans on same day,
     multi-unit stacking.

4. **`week_provider.dart`** in `flutter/packages/core/lib/src/providers/`
   - `selectedWeekProvider`: `StateProvider<DateTime>` (Monday of displayed week).
   - `unitFilterProvider`: `StateProvider<Set<int>>` (empty = show all).
   - `weekPlansProvider`: `Provider<List<Plan>>` derived from `plansProvider` +
     `selectedWeekProvider` — filters to the current [weekStart, weekStart+6] range.
   - `weekGridProvider`: `Provider<List<WeekRow>>` derived from `weekPlansProvider` +
     `unitsProvider` + `unitFilterProvider` + `selectedWeekProvider`.

Export all new symbols from `core.dart`.

---

## Phase 2 — Week grid widget

**What:** the visual grid — header row + scrollable unit-band body. No edit form yet;
tapping a filled cell does nothing (wired in Phase 3).

**Package:** create `flutter/packages/feature_week_view/` via
`flutter create --template=package flutter/packages/feature_week_view`.

**Deliverables:**

1. **`WeekDayHeader`** — fixed row of 7 day columns.
   - Short day name (Mon…Sun) + date number.
   - "Today" column: date number in a filled primary-colour circle (matches Qt).
   - Left rail: week number in muted text.
   - Does not scroll.

2. **`PlanCell`** — single slot cell (52 × colWidth).
   - Empty state: right + bottom hairline borders, no fill.
   - Filled state: rounded primary-colour chip with unit name (bold) + time range
     (`HH:MM – HH:MM`) below; white text; clipped.
   - `onTap(Plan)` callback (only fired when filled).

3. **`WeekGrid`** — the scrollable body.
   - `ListView` of `WeekRow` entries produced by `buildWeekGrid`.
   - `HeaderRow` → 26 px tinted band with bold unit name.
   - `PlanRow` → `Row` of 7 `PlanCell` widgets (height 52 px).
   - Accepts `onPlanTap(Plan)` callback; passes it down to `PlanCell`.

4. **`WeekView`** — composes `WeekDayHeader` + `WeekGrid` inside a `Column`.
   - `ConsumerWidget`: watches `weekGridProvider`.
   - Handles loading / error / empty states via `design_system` primitives.
   - `onPlanTap(Plan)` bubbled up to the screen.

---

## Phase 3 — Edit / add sidebar

**What:** the plan edit form — equivalent to `EventSidebar.qml`'s edit panel.

**Deliverables:**

1. **`PlanFormState`** — Riverpod `StateNotifier` (or `Notifier`) holding the transient
   form state: `selectedUnitId`, `startDate`, `endDate`, `selectedRouteIds`.
   - `planFormProvider`: scoped to the week screen with `overrideWithValue`.

2. **`PlanForm`** — form widget (scrollable `Column`):
   - Unit dropdown (`DropdownButtonFormField`) from `unitsProvider`.
   - Start / End date+time pickers (`showDatePicker` + `showTimePicker`).
   - Route checklist from `routesProvider`.
   - Validate: end ≥ start; show inline error below end field.
   - Save: calls `CreatePlan` or `UpdatePlan` RPC via `calendarServiceProvider`.
     On success, `ref.invalidate(plansProvider)` to refresh the live list.
   - Cancel: pops the sidebar.

3. **`PlanSidebar`** — wraps `PlanForm` in `AppSidebar` from `design_system`.
   - Two modes: **add** (fab/+ button tap) and **edit** (plan chip tap from `WeekGrid`).
   - Slide-in from the right; overlays the grid on narrow screens.

4. **`HoursFooter`** — bottom bar showing planned hours per visible unit + grand total.
   - Watches `weekPlansProvider` + `unitsProvider` + `unitFilterProvider`.
   - Computes `(endTimeSecs − startTimeSecs) / 3600` per unit; sums total.
   - Two-row layout: unit names (small bold) above, hours below.

---

## Phase 4 — Week screen + navigation wiring

**What:** assemble the pieces into a routable screen and hook it into the Strangler Fig
navigation.

**Deliverables:**

1. **`WeekScreen`** — top-level `ConsumerStatefulWidget`:
   - `AppScaffold` with title `"Week WW"` (ISO week number from `selectedWeekProvider`).
   - Toolbar actions: `←` / `→` buttons updating `selectedWeekProvider`.
   - Body: `WeekView` (fills remaining height).
   - Bottom: `HoursFooter`.
   - FAB: opens `PlanSidebar` in add mode.
   - `WeekView.onPlanTap` → opens `PlanSidebar` in edit mode.

2. **Router wiring** — in `flutter/app/lib/router.dart`:
   ```dart
   GoRoute(path: '/week', builder: (_, __) => const WeekScreen()),
   ```

3. **Qt side** — in `NavigationBridge.cpp`, add `"/week"` to `kFlutterRoutes` (or call
   `navBridge->setFlutterRoutes` with the updated list in `eventcalendar.cpp`).

4. **Shadow period** — Qt `WeekView` remains visible; `WeekScreen` is reachable via a
   toolbar button labelled "Week (Flutter)". Both show the same data. Remove the Qt
   version after one sprint of validation.

---

## Phase 5 — Unit filter sidebar

**What:** port `UnitFilterSidebar.qml` so the Flutter week view respects the same filter
as the rest of the app.

**Deliverables:**

1. **`UnitFilterSidebar`** — drawer listing all units as `CheckboxListTile` widgets.
   - Reads `unitsProvider`; writes `unitFilterProvider`.
   - "Clear" button resets filter to empty (= show all), matching Qt behaviour.

2. Wire into `WeekScreen` as a `Drawer` or `EndDrawer`; add a filter icon to the
   `AppScaffold` actions.

---

## Execution order

| Phase | Depends on | Effort |
|---|---|---|
| 1 — Data layer | existing `core` providers | Small |
| 2 — Grid widget | Phase 1 | Medium |
| 3 — Edit sidebar | Phase 1 | Medium |
| 4 — Screen + routing | Phases 2 + 3 | Small |
| 5 — Unit filter | Phase 4 | Small |

Recommended order: **1 → 2 → 3 → 4 → 5** (linear; each phase builds on the last).

---

## Key implementation notes

### `buildWeekGrid` algorithm (Phase 1)

Port directly from `calendarutils.cpp`. Logic:

1. For each unit (in order), find all plans in the week whose `unitId` matches.
2. For each of the 7 days, sort that day's plans by start time.
3. `slotCount` = max plans on any single day for this unit (minimum 1).
4. Emit one `HeaderRow` then `slotCount` × `PlanRow`s.
5. Each `PlanRow.dayPlans[d]` = the plan at slot index `slotIndex` for day `d`, or `null`.

### `Plan` date fields (Phase 1)

The existing Dart `Plan` stores `startDate`/`endDate` as `String` (ISO date from proto,
e.g. `"2026-04-07"`), plus `startTimeSecs`/`endTimeSecs` as integers.  
The grid needs a `DateTime` per plan. Add a helper to `Plan`:

```dart
DateTime get startDateTime {
  final d = DateTime.parse(startDate);
  return d.add(Duration(seconds: startTimeSecs));
}
DateTime get endDateTime {
  final d = DateTime.parse(endDate);
  return d.add(Duration(seconds: endTimeSecs));
}
```

### gRPC write RPCs (Phase 3)

`CreatePlan` and `UpdatePlan` are in the proto `CalendarService` but not yet called from
Flutter. Add them as methods on a new `planMutationsProvider` (a simple `Provider`
wrapping the stub) rather than calling the stub directly from the form widget.

### No `DeletePlan` in Phase 3

The Qt sidebar has delete buttons. Omit delete from the initial Flutter form to keep
scope small; add it as a follow-up once the basic CRUD flow is validated.
