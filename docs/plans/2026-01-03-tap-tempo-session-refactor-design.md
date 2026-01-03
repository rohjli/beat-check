# Tap Tempo Session Refactor Design

Date: 2026-01-03
Status: Approved

## Context
The tap tempo feature currently mixes session state and rules inside the
presentation provider. This refactor introduces a pure-Dart session engine to
own tap timing rules, making state transitions testable and keeping UI logic
thin.

## Goals
- Move tap timing rules into a domain layer session engine.
- Keep the provider as a thin adapter for UI and timers.
- Preserve or improve current behavior, including auto-reset after inactivity.
- Improve testability of BPM logic and state transitions.

## Non-Goals
- UI redesign or visual changes.
- New features beyond behavior adjustments described below.

## Proposed Structure
New/updated files:
- lib/features/tap_tempo/domain/entities/tap_tempo_result.dart
- lib/features/tap_tempo/domain/entities/tap_tempo_state.dart
- lib/features/tap_tempo/domain/services/tap_tempo_session.dart
- lib/features/tap_tempo/domain/services/bpm_calculator.dart (existing helper)
- lib/features/tap_tempo/presentation/providers/tap_tempo_provider.dart (thin)

## Domain Model
TapTempoResult (immutable):
- state: TapTempoState (idle, collecting, stable, ignored)
- bpm: double? (null until intervals exist)
- tapCount: int
- feedback: String? (e.g., "Tap too fast")

TapTempoSession (pure Dart):
- Holds last tap timestamp and rolling interval list.
- Methods:
  - recordTapAt(DateTime now) -> TapTempoResult
  - reset() -> TapTempoResult
- Uses BpmCalculator for weighted averaging and outlier filtering.

## Behavior Changes
- Auto-reset after inactivity: provider starts/resets a Timer on each tap. If
  it fires (resetThresholdMs), it calls session.reset() and publishes idle
  state without requiring a new tap.
- Ignored input feedback: too-fast taps return state=ignored with feedback. The
  provider clears feedback after a short delay to return to stable/collecting.

## Data Flow
TapTempoScreen -> TapTempoProvider.recordTap() -> TapTempoSession.recordTapAt()
-> TapTempoResult -> Provider stores latest result and notifies listeners ->
TapTempoScreen renders by state.

## Testing Plan
- Unit tests for TapTempoSession:
  - first tap -> collecting
  - second tap -> stable with bpm
  - rolling window size enforced
  - outlier filtering behavior
  - clamp to min/max bpm
  - too-fast tap -> ignored feedback, bpm unchanged
  - long pause -> reset
- Provider tests:
  - inactivity timer triggers reset
  - ignored feedback clears after delay

