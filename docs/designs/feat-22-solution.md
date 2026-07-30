---
title: "Feature #22 — Reference Frame Solution Walkthrough"
feature: "#22"
type: "solution-walkthrough"
platform: "flutter"
created: "2026-07-30"
issue_id: "22"
---

# Feature #22: Reference Frame — Solution Walkthrough

> **Parent Epic:** #26 — Geographic Location Module
> **Schema:** `ietf-geo-location:geo-location/reference-frame` (RFC 9179 §2.1)

## 1. Overview

The `reference-frame` container defines the frame of reference in which all location coordinate values are interpreted. It specifies the astronomical body (default "earth"), an optional alternate reference system (feature-gated behind `alternate-systems`), and composes the `geodetic-system` sub-container (Feature #23).

## 2. What Was Built

### 2.1 Domain Layer

| Component | File | Purpose |
|-----------|------|---------|
| `ReferenceFrame` | `lib/domain/reference_frame.dart` | Domain model with `astronomicalBody` (default "earth") and `alternateSystem`. Includes `fromMap`, `toMap`, `copyWith`. Auto-normalizes uppercase to lowercase in `fromMap`. |
| `validateAstronomicalBody()` | `lib/domain/validation.dart` | Validates IAU body name against ASCII printable pattern `[ -@\[-\^_-~]*`. Rejects control characters. |
| `normalizeAstronomicalBody()` | `lib/domain/validation.dart` | Converts astronomical body name to lowercase per RFC 9179 recommendation. |
| `featureFlag` on `FieldDescriptor` | `lib/domain/type_descriptor.dart` | New `String?` field enabling conditional field rendering (YANG `if-feature` equivalent). |
| `suggestions` on `FieldDescriptor` | `lib/domain/type_descriptor.dart` | New `List<String>?` field enabling autocomplete dropdowns on text fields. |

### 2.2 UI Layer

| Component | File | Purpose |
|-----------|------|---------|
| `enabledFeatures` on `PropertyGrid` | `lib/features/properties/property_grid.dart` | `Set<String>` controlling which feature-gated fields are rendered. When a field's `featureFlag` is not in this set, the field is hidden. |
| Autocomplete rendering | `lib/features/properties/property_grid.dart` | When `FieldDescriptor.suggestions` is present, renders `Autocomplete<String>` widget with free-text support for IAU body names. |

### 2.3 Tests

| File | Count | Coverage |
|------|-------|----------|
| `test/domain/reference_frame_test.dart` | 9 | Construct, serialize, default, copyWith |
| `test/domain/validation_test.dart` | +13 | Body validation + normalization |
| `test/domain/type_descriptor_test.dart` | +14 | featureFlag, suggestions |
| `test/property_grid_test.dart` | +6 | Feature gating, autocomplete |
| `integration_test/reference_frame_test.dart` | 29 | CRUD, validation, roundtrip, all acceptance criteria |

## 3. Code Realization Table

| Feature Element | Implementation File | Dart Symbol |
|----------------|---------------------|-------------|
| reference-frame container | `lib/domain/reference_frame.dart` | `class ReferenceFrame` |
| astronomical-body leaf | `lib/domain/reference_frame.dart` | `ReferenceFrame.astronomicalBody` (String, default "earth") |
| alternate-system leaf | `lib/domain/reference_frame.dart` | `ReferenceFrame.alternateSystem` (String?) |
| Body pattern validation | `lib/domain/validation.dart` | `validateAstronomicalBody(String?)` |
| Lowercase normalization | `lib/domain/validation.dart` | `normalizeAstronomicalBody(String?)` |
| Feature flag gating | `lib/domain/type_descriptor.dart` | `FieldDescriptor.featureFlag` |
| Feature flag rendering | `lib/features/properties/property_grid.dart` | `PropertyGrid.enabledFeatures` |
| IAU body autocomplete | `lib/features/properties/property_grid.dart` | `_buildAutocompleteField()` |

## 4. Acceptance Criteria Mapping

| Scenario | Status | Evidence |
|----------|--------|----------|
| Default "earth" when body unset | ✅ | `reference_frame_test.dart` — fromMap empty defaults to "earth" |
| Non-Earth body (mars) | ✅ | `reference_frame_test.dart` — CRUD with "mars" |
| Enable alternate system | ✅ | `reference_frame_test.dart` — CRUD with "virtual-reality-grid-7" |
| Alternate absent when disabled | ✅ | `reference_frame_test.dart` — null alternateSystem |
| Invalid body pattern | ✅ | `reference_frame_test.dart` — control char "\x00" rejected |
| Uppercase auto-conversion | ✅ | `reference_frame_test.dart` — "EARTH"→"earth", "MARS"→"mars" |

## 5. Verification Evidence

- **Unit/widget tests**: `00:10 +101: All tests passed!`
- **Integration tests**: 29/29 passed (CRUD + validation + roundtrip)
- **`flutter analyze`** (new files): `No issues found!`

## 6. Commit History

| Commit | Description |
|--------|-------------|
| `3c9bccd` | feat: add ReferenceFrame domain model |
| `f9ca890` | feat: add astronomical body pattern validation and lowercase normalization |
| `9c4ca30` | feat: add feature flag mechanism to FieldDescriptor and PropertyGrid |
| `87f003b` | feat: add suggestions field to FieldDescriptor and Autocomplete rendering |
| `636f052` | test: add integration tests for reference-frame CRUD |
