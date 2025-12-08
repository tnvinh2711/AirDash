# Tasks: Device Discovery Logic

**Input**: Design documents from `/specs/004-device-discovery/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: Included as requested in feature specification ("Unit Test DiscoveryController by mocking DiscoveryRepository")

**Organization**: Tasks are grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2)
- Include exact file paths in descriptions

## Path Conventions

- **Flutter project**: `lib/src/core/`, `lib/src/features/`, `test/` at repository root
- Feature path: `lib/src/features/discovery/`

---

## Phase 1: Setup (Dependencies & Platform Configuration)

**Purpose**: Install dependencies and configure platform-specific settings

- [x] T001 Install bonsoir dependency via `fvm flutter pub add bonsoir`
- [x] T002 Install device_info_plus dependency via `fvm flutter pub add device_info_plus`
- [x] T003 [P] Configure iOS Bonjour services in `ios/Runner/Info.plist` (add NSBonjourServices and NSLocalNetworkUsageDescription)
- [x] T004 [P] Configure macOS network entitlements in `macos/Runner/DebugProfile.entitlements`
- [x] T005 [P] Configure macOS network entitlements in `macos/Runner/Release.entitlements`
- [x] T006 Run `fvm flutter pub get` to verify dependencies resolve

---

## Phase 2: Foundational (Domain Models)

**Purpose**: Create shared domain models that ALL user stories depend on

**⚠️ CRITICAL**: User story implementation cannot begin until these models exist

- [x] T007 [P] Create DeviceType enum in `lib/src/features/discovery/domain/device_type.dart`
- [x] T008 [P] Create Device model (Freezed) in `lib/src/features/discovery/domain/device.dart`
- [x] T009 [P] Create LocalDeviceInfo model (Freezed) in `lib/src/features/discovery/domain/local_device_info.dart`
- [x] T010 Create DiscoveryState model (Freezed) in `lib/src/features/discovery/domain/discovery_state.dart`
- [x] T011 Run build_runner to generate Freezed code: `fvm flutter pub run build_runner build --delete-conflicting-outputs`
- [x] T012 Run `fvm flutter analyze` to verify zero lint errors

**Checkpoint**: Domain models ready - user story implementation can begin

---

## Phase 3: User Story 1 - Discover Other Devices on LAN (Priority: P1) 🎯 MVP

**Goal**: Users can see all AirDash/FLUX devices on their local network within 5 seconds

**Independent Test**: Launch app on two devices on same network, verify each appears in the other's discovery list with correct info (alias, IP)

### Implementation for User Story 1

- [x] T013 [US1] Create DiscoveryRepository in `lib/src/features/discovery/data/discovery_repository.dart` with startScan, stopScan methods
- [x] T014 [US1] Create discoveryRepositoryProvider in `lib/src/features/discovery/data/discovery_repository.dart`
- [x] T015 [US1] Implement startScan() using BonsoirDiscovery with event stream handling
- [x] T016 [US1] Implement stopScan() to properly dispose BonsoirDiscovery instance
- [x] T017 [US1] Implement device parsing from BonsoirService to Device model (extract TXT record attributes)
- [x] T018 [US1] Create DiscoveryController (AsyncNotifier) in `lib/src/features/discovery/application/discovery_controller.dart`
- [x] T019 [US1] Implement startScan() in DiscoveryController with state updates (isScanning, devices list)
- [x] T020 [US1] Implement stopScan() in DiscoveryController with cleanup
- [x] T021 [US1] Implement device list updates on ServiceFound, ServiceResolved, ServiceLost events
- [x] T022 [US1] Run build_runner to generate Riverpod code
- [x] T023 [US1] Run `fvm flutter analyze` to verify zero lint errors

**Checkpoint**: Discovery scan works - devices appear in list within 5 seconds

---

## Phase 4: User Story 2 - Broadcast Own Presence (Priority: P1)

**Goal**: Device automatically broadcasts presence so other devices can discover it

**Independent Test**: Run app on Device A, use mDNS browser tool to verify Device A's service visible with correct metadata

### Implementation for User Story 2

- [x] T024 [US2] Create DeviceInfoProvider in `lib/src/core/providers/device_info_provider.dart`
- [x] T025 [US2] Implement getDeviceType() using device_info_plus platform detection
- [x] T026 [US2] Implement getOperatingSystem() using device_info_plus
- [x] T027 [US2] Implement getAlias() with settings fallback to hostname
- [x] T028 [US2] Implement getPort() with settings fallback to default port
- [x] T029 [US2] Implement getLocalDeviceInfo() convenience method
- [x] T030 [US2] Add startBroadcast, stopBroadcast methods to DiscoveryRepository in `lib/src/features/discovery/data/discovery_repository.dart`
- [x] T031 [US2] Implement startBroadcast() using BonsoirBroadcast with TXT record attributes
- [x] T032 [US2] Implement stopBroadcast() to properly dispose BonsoirBroadcast instance
- [x] T033 [US2] Store ownServiceInstanceName after broadcast starts for self-filtering
- [x] T034 [US2] Add startBroadcast() to DiscoveryController with state update (isBroadcasting)
- [x] T035 [US2] Add stopBroadcast() to DiscoveryController with state update
- [x] T036 [US2] Run build_runner to regenerate Riverpod code
- [x] T037 [US2] Run `fvm flutter analyze` to verify zero lint errors

**Checkpoint**: Broadcasting works - device visible to mDNS browsers with correct TXT records

---

## Phase 5: User Story 3 - Manual Refresh Discovery (Priority: P2)

**Goal**: Users can manually refresh device list to force rescan and clear stale entries

**Independent Test**: Trigger refresh action, verify scan restarts, list updates, stale entries cleared

### Implementation for User Story 3

- [x] T038 [US3] Add refresh() method to DiscoveryController in `lib/src/features/discovery/application/discovery_controller.dart`
- [x] T039 [US3] Implement refresh() to stop current scan, clear devices, restart scan
- [x] T040 [US3] Implement staleness timer (10-second interval) to prune devices older than 30 seconds
- [x] T041 [US3] Start staleness timer when scanning begins, stop when scanning ends
- [x] T042 [US3] Run `fvm flutter analyze` to verify zero lint errors

**Checkpoint**: Manual refresh clears stale devices and restarts discovery

---

## Phase 6: User Story 4 - Filter Own Device from List (Priority: P2)

**Goal**: User's own device never appears in discovery list

**Independent Test**: Verify device scanning and broadcasting simultaneously, own device not in list

### Implementation for User Story 4

- [x] T043 [US4] Add self-filtering logic to device event handler in DiscoveryController
- [x] T044 [US4] Compare discovered service instance name against ownServiceInstanceName
- [x] T045 [US4] Skip adding device to list if service instance name matches own broadcast
- [x] T046 [US4] Run `fvm flutter analyze` to verify zero lint errors

**Checkpoint**: Own device filtered - never appears in discovery list

---

## Phase 7: Unit Tests

**Purpose**: Unit test DiscoveryController by mocking DiscoveryRepository (as specified)

- [x] T047 [P] Install mocktail dev dependency via `fvm flutter pub add --dev mocktail`
- [x] T048 Create test file `test/features/discovery/application/discovery_controller_test.dart`
- [x] T049 Create MockDiscoveryRepository using mocktail
- [x] T050 Test: startScan() updates isScanning state to true
- [x] T051 Test: stopScan() updates isScanning state to false and clears devices
- [x] T052 Test: startBroadcast() updates isBroadcasting state to true
- [x] T053 Test: stopBroadcast() updates isBroadcasting state to false
- [x] T054 Test: Device added to list on ServiceFound+ServiceResolved events
- [x] T055 Test: Device removed from list on ServiceLost event
- [x] T056 Test: Own device filtered from list by service instance name
- [x] T057 Test: refresh() clears devices and restarts scan
- [x] T058 Test: Error state set when repository throws exception
- [x] T059 Run all tests via `fvm flutter test test/features/discovery/`

---

## Phase 8: Polish & Validation

**Purpose**: Final validation and quality checks

- [x] T060 Run `fvm flutter analyze` to verify zero lint errors across all files
- [x] T061 Run `dart format lib/src/features/discovery/ test/features/discovery/` for consistent formatting
- [ ] T062 Validate quickstart.md instructions by following setup steps manually
- [ ] T063 Manual test: Launch app on two devices on same network, verify mutual discovery

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-6)**: All depend on Foundational phase completion
  - US1 (Discover) → US2 (Broadcast) can proceed in parallel initially
  - US4 (Self-filter) depends on US2 (needs ownServiceInstanceName from broadcast)
  - US3 (Refresh) can proceed after US1
- **Unit Tests (Phase 7)**: Depends on all user stories complete
- **Polish (Phase 8)**: Depends on tests passing

### User Story Dependencies

- **US1 (P1)**: Can start after Foundational - No dependencies on other stories
- **US2 (P1)**: Can start after Foundational - Parallel with US1
- **US3 (P2)**: Can start after US1 (uses startScan/stopScan)
- **US4 (P2)**: Depends on US2 (needs ownServiceInstanceName from broadcast)

### Parallel Opportunities

```
Phase 1 (Setup):     T003 || T004 || T005  (platform configs)
Phase 2 (Models):    T007 || T008 || T009  (domain models)
Phase 3-4 (US1+US2): Can run US1 and US2 in parallel initially
Phase 7 (Tests):     T047 (mocktail install) independent
```

---

## Parallel Example: Foundational Phase

```bash
# Launch all domain models in parallel:
Task T007: "Create DeviceType enum in lib/src/features/discovery/domain/device_type.dart"
Task T008: "Create Device model in lib/src/features/discovery/domain/device.dart"
Task T009: "Create LocalDeviceInfo model in lib/src/features/discovery/domain/local_device_info.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T006)
2. Complete Phase 2: Foundational (T007-T012)
3. Complete Phase 3: User Story 1 - Discover (T013-T023)
4. **STOP and VALIDATE**: Test discovery on two devices
5. Deploy/demo if discovery working

### Incremental Delivery

1. Setup + Foundational → Models ready
2. Add US1 (Discover) → Test discovery → Partial MVP
3. Add US2 (Broadcast) → Test broadcast → Full MVP (mutual discovery)
4. Add US3 (Refresh) → Test refresh → Enhanced UX
5. Add US4 (Self-filter) → Test filtering → Polished UX
6. Add Unit Tests → Verify all scenarios → Production ready

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story
- Each user story independently testable after completion
- Run build_runner after Freezed/Riverpod changes
- Commit after each phase completion
- Stop at any checkpoint to validate story independently

