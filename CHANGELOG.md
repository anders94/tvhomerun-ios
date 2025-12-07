# Changelog

All notable changes to TV HomeRun for iOS will be documented in this file.

## [Unreleased]

### Added - 2025-12-06

#### Program Guide Feature
- **Program Guide View** (`TVHomeRun/Views/GuideView.swift`)
  - Added searchable program guide accessible via magnifying glass icon in main shows view
  - Displays upcoming TV programs grouped by series with episode counts
  - Real-time search filtering by show title
  - Shows 80x120px series thumbnails with red recording indicator dot
  - Loading states with progress indicator and empty states
  - Clean modal interface with X button for dismissal (replaced Close button and reload icon)

- **Guide Detail View** (`TVHomeRun/Views/GuideDetailView.swift`)
  - Detailed view of upcoming episodes for a selected series
  - Recording toggle switch that appears instantly in correct state (no loading spinner)
  - Shows all upcoming episodes sorted chronologically with episode titles, numbers, air times, and synopses
  - 60x90px episode thumbnails
  - Toggle creates/deletes recording rules on backend

- **Guide Models** (`TVHomeRun/Models/Guide.swift`)
  - `GuideResponse`: Top-level response containing channels
  - `GuideChannel`: Channel information with guide programs
  - `GuideProgram`: Individual program with metadata (series ID, title, episode info, times, synopsis, image)
  - `GuideSeries`: Grouped programs by series for display
  - Program IDs include channel identifier to prevent duplicate ID conflicts

- **Recording Rule Models** (`TVHomeRun/Models/RecordingRule.swift`)
  - `RecordingRule`: Series recording rule with configuration options
  - `RecordingRulesResponse`: API response containing recording rules
  - `CreateRecordingRuleRequest`: Request payload for creating new rules
  - `RecordingRuleResponse`: API response for rule creation

#### Episode Deletion Feature
- **Swipe-to-Delete** (`TVHomeRun/Views/EpisodesListView.swift`)
  - Implemented swipe-left gesture to reveal delete button
  - Alert-based confirmation dialog (replaced confirmationDialog for better visibility)
  - Context menu (long-press) as alternative deletion method
  - Hard-coded to prevent re-recording (rerecord: false)
  - Converted from ScrollView+LazyVStack to List to support swipeActions

#### API Client Enhancements
- **New Endpoints** (`TVHomeRun/Services/APIClient.swift`)
  - `DELETE /api/episodes/:id` - Delete episode with optional rerecord parameter
  - `GET /api/guide` - Fetch program guide with optional force refresh
  - `GET /api/recording-rules` - Fetch all recording rules
  - `POST /api/recording-rules` - Create new recording rule
  - `DELETE /api/recording-rules/:id` - Delete recording rule

- **Improved Error Handling**
  - Empty response handling for DELETE requests (handles both empty data and "{}" responses)
  - Increased timeout from 30s to 60s for guide endpoint
  - Fixed @MainActor usage to individual properties/methods instead of entire class

### Fixed - 2025-12-06

- **Data Model Fixes** (`TVHomeRun/Models/Episode.swift`)
  - Made `seasonNumber` and `episodeNum` optional (`Int?`) to handle null values from backend
  - Prevents crashes when programs lack season/episode information (e.g., "2025 Masters Tournament")

- **JSON Parsing Fixes**
  - Fixed guide endpoint CodingKey from "Guide" to "guide" (lowercase)
  - Fixed recording rules endpoint CodingKey from "recordingRules" to "rules"
  - Changed `RecordingRule.channelOnly` from `Int?` to `String?` to match backend format

- **Duplicate ID Warning**
  - Added `channelId` field to `GuideProgram` model
  - Populates channel ID when loading guide data
  - Prevents ForEach duplicate ID errors when same program airs on multiple channels

- **Swift Concurrency**
  - Removed `@MainActor` from entire `APIClient` class
  - Applied `@MainActor` only to `@Published` properties and specific methods
  - Eliminates "unsafeForcedSync called from Swift Concurrent context" warnings

- **UI/UX Improvements**
  - Recording toggle no longer animates on initial load (uses `withAnimation(nil)`)
  - Guide modal uses cleaner X icon instead of Close button + reload icon
  - Cancel button now visible in episode deletion confirmation (alert vs confirmationDialog)

### Technical Notes - 2025-12-06

#### Architecture Decisions
- **Guide Loading**: Fetches guide data and recording rules in parallel using `async let` for performance
- **Channel Association**: Programs include channel ID for unique identification across multiple airings
- **Recording Status**: Passed from parent view to detail view to eliminate loading spinner
- **ID Generation**: Composite IDs include seriesId + startTime + endTime + channelId + episodeTitle + episodeNumber

#### Known Limitations
- Swipe-to-delete has minor list scrolling behavior (SwiftUI framework limitation)
- Haptic feedback warnings in simulator (expected behavior, works on physical devices)
- Auto-layout constraint warnings for toolbar buttons (cosmetic, doesn't affect functionality)

## [Previous Versions]

See git history for changes prior to 2025-12-06.
