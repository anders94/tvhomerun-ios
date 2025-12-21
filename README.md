# TV HomeRun for iOS

A comprehensive SwiftUI-based TV management and streaming client for iOS that connects to a server running [tvhomerun-backend](https://github.com/anders94/tvhomerun-backend). Watch live TV, manage your DVR schedule, and browse recorded content—all from your iPhone or iPad.

## Features

### Live TV
- **Live Channel Streaming**: Watch live TV channels with HLS streaming and intelligent buffering
- **Channel Guide**: Browse available channels with real-time program information
- **Adaptive Playback**: Automatic buffer management to prevent stalls at the live edge

### DVR Management
- **Program Guide**: Comprehensive, searchable guide showing upcoming TV programs across all channels
- **Recording Scheduling**: Create, modify, and delete series recording rules
- **Visual Indicators**: Clear display of scheduled and active recordings in the guide
- **Series Management**: One-tap recording toggle for entire series

### Recorded Content
- **Content Library**: Grid-based browsing of recorded shows with thumbnails and metadata
- **Episode Management**: Detailed episode lists with progress tracking and swipe-to-delete
- **Advanced Playback**: Resume functionality, seek controls, and auto-play for subsequent episodes
- **Progress Tracking**: Automatic bookmark saving with visual watch indicators

### System Features
- **Server Configuration**: Persistent URL storage with automatic connectivity validation
- **Error Resilience**: Exponential backoff retry logic (1s, 2s, 4s intervals) with user notifications after 5 seconds
- **Touch-Optimized UI**: iOS-specific interface design optimized for both iPhone and iPad

## Requirements

- iOS 15.0+
- Xcode 14.0+
- Swift 5.7+
- A server running [tvhomerun-backend](https://github.com/anders94/tvhomerun-backend)

## Installation

1. Clone the repository: `git clone https://github.com/anders94/tvhomerun-ios.git
2. Double-click the `.xcodeproj` file to open in Xcode
3. Select your target device or simulator
4. Press ⌘+R to build and run

## Project Structure

```
TVHomeRun/
├── TVHomeRun/
│   ├── TVHomeRunApp.swift          # App entry point
│   ├── ContentView.swift           # Root view with connectivity check
│   ├── Info.plist                  # App configuration
│   ├── Models/
│   │   ├── Health.swift            # Health check data model
│   │   ├── Episode.swift           # Episode data model
│   │   ├── Show.swift              # Show data model
│   │   ├── Guide.swift             # Program guide data models
│   │   ├── RecordingRule.swift     # Recording rule data models
│   │   └── Channel.swift           # Live channel data models
│   ├── Services/
│   │   └── APIClient.swift         # API client with error handling
│   ├── Utilities/
│   │   └── UserSettings.swift      # UserDefaults wrapper
│   └── Views/
│       ├── ServerSetupView.swift         # Server URL configuration
│       ├── ShowsListView.swift           # Recorded shows grid view
│       ├── EpisodesListView.swift        # Episodes list view
│       ├── GuideView.swift               # Program guide view
│       ├── GuideDetailView.swift         # Program guide detail view
│       ├── LiveChannelsView.swift        # Live channel browser
│       ├── LiveVideoPlayerView.swift     # Live TV player view
│       ├── LiveVideoPlayerViewModel.swift # Live player state management
│       ├── VideoPlayerView.swift         # Recorded video player view
│       └── VideoPlayerViewModel.swift    # Recorded player state management
├── CHANGELOG.md                     # Development history
└── README.md                        # This file
```

## Architecture

The app follows the MVVM (Model-View-ViewModel) architecture pattern:

### Models Layer
- **Channel**: Represents live TV channels with guide numbers and metadata
- **Show**: Represents recorded TV shows with metadata
- **Episode**: Represents recorded episodes with playback tracking
- **Health**: Server health status and connectivity validation
- **Guide**: Program guide data (GuideResponse, GuideChannel, GuideProgram, GuideSeries)
- **RecordingRule**: Recording rules for series with configuration options

### Services Layer
- **APIClient**: Handles all network requests with exponential backoff retry logic
  - Automatically retries failed requests up to 3 times
  - Uses 1s, 2s, 4s backoff intervals
  - Shows error alerts after 5 seconds of failures
  - Manages live streaming sessions with heartbeat mechanism

### Views Layer

**Live TV**
- **LiveChannelsView**: Channel browser with current program information
- **LiveVideoPlayerView**: Full-screen live TV player with AVPlayer
- **LiveVideoPlayerViewModel**: Manages live stream buffering, heartbeat, and playback state

**DVR Management**
- **GuideView**: Searchable program guide with recording indicators across all channels
- **GuideDetailView**: Detailed program view with series recording toggle

**Recorded Content**
- **ShowsListView**: Grid display of recorded shows with thumbnails
- **EpisodesListView**: Episode list with progress tracking and swipe-to-delete
- **VideoPlayerView**: Full-screen player for recorded content with native iOS controls
- **VideoPlayerViewModel**: Manages playback state, progress tracking, and episode navigation

**Configuration**
- **ServerSetupView**: Server URL configuration with validation

### Utilities
- **UserSettings**: Persistent storage for server URL and setup state

## API Integration

The app communicates with the following endpoints:

**System**
- `GET /health` - Server connectivity verification

**Live TV**
- `GET /api/channels` - Retrieve available live TV channels
- `POST /api/start-watching` - Start live TV stream and obtain playlist URL
- `POST /api/heartbeat` - Maintain live streaming session
- `POST /api/stop-watching` - End live TV stream and cleanup session

**DVR Management**
- `GET /api/guide` - Retrieve program guide (optional forceRefresh parameter)
- `GET /api/recording-rules` - Retrieve all recording rules
- `POST /api/recording-rules` - Create new series recording rule
- `DELETE /api/recording-rules/:id` - Delete recording rule

**Recorded Content**
- `GET /api/shows` - Retrieve recorded shows
- `GET /api/shows/:id/episodes` - Retrieve episodes for a show
- `PUT /api/episodes/:id/progress` - Update playback progress
- `DELETE /api/episodes/:id` - Delete episode (optional rerecord parameter)

## Configuration

### HTTP Support

The app requires HTTP support for local network servers. This is configured in `Info.plist`:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

**Note**: This setting allows unencrypted HTTP connections. This is appropriate for local network servers but should not be used for production apps communicating over the internet.

## Key Differences from Apple TV Version

This iOS version shares the core functionality with the tvOS version while being optimized for mobile:

**Shared Capabilities**
- Live TV streaming with HLS support
- Complete DVR schedule management
- Recorded content library and playback
- Program guide with search and filtering
- Series recording rules

**iOS-Specific Adaptations**
- **UI Scaling**: Adjusted font sizes, spacing, and component sizes for smaller screens
- **Grid Layout**: 2-column grid instead of 4-column for mobile devices
- **Touch Navigation**: Standard iOS touch navigation instead of tvOS focus engine
- **Button Styles**: iOS-native button styles instead of tvOS card styles
- **Responsive Design**: Adaptive layouts optimized for both iPhone and iPad
- **Portability**: Watch live TV or manage recordings from anywhere on your network

## Usage

### Initial Setup
1. **First Launch**: Enter your server URL (e.g., `http://192.168.1.100:3000`)
2. **Connectivity Check**: The app validates the connection before proceeding

### Live TV
1. **Access Live TV**: Tap the "Live TV" icon in the navigation bar
2. **Browse Channels**: Scroll through available channels with current program information
3. **Watch Live**: Tap a channel to start live streaming
4. **Buffer Management**: The app maintains a 10-second buffer to prevent stalls
5. **Exit Stream**: Tap back to return to the channel list

### Managing Recordings
1. **Open Program Guide**: Tap the magnifying glass icon in the navigation bar
2. **Browse Programs**: View upcoming programs across all channels
3. **Search**: Use the search bar to find specific shows
4. **Schedule Recording**: Tap a program, then toggle "Record This Series"
5. **Visual Indicators**: Recording status is displayed with icons in the guide
6. **Modify Schedule**: Toggle off "Record This Series" to cancel future recordings
7. **Force Refresh**: Pull down on the guide to force a refresh of program data

### Watching Recorded Content
1. **Browse Library**: View recorded shows in the main grid view
2. **Select Show**: Tap a show to view its episodes
3. **Watch Episode**: Tap an episode to start playback
4. **Resume**: Episodes automatically resume from where you left off
5. **Auto-Play**: Next episode plays automatically when the current episode ends
6. **Progress Tracking**: Watch progress is automatically saved as you view

### Managing Episodes
1. **Delete Episode**: Swipe left on an episode and tap Delete
2. **Re-record Option**: When deleting, choose whether to allow re-recording
3. **Long-Press Menu**: Long-press an episode for additional options

## Development

### Building for Simulator

```bash
# List available simulators
xcrun simctl list devices

# Build and run
xcodebuild -scheme TVHomeRun -destination 'platform=iOS Simulator,name=iPhone 15' build
```

### Building for Device

1. Connect your iOS device
2. Select your device in Xcode
3. Ensure your development team is selected in Signing & Capabilities
4. Press ⌘+R to build and run

## Testing

For testing, you'll need a server running locally at a specified port (default: 3000) that implements the API endpoints. See [tvhomerun-backend](https://github.com/anders94/tvhomerun-backend) for the server implementation.

## Troubleshooting

### Cannot Connect to Server

- Ensure your iOS device and server are on the same network
- Verify the server URL is correct (include `http://` and port number)
- Check that your server is running and accessible
- Try accessing the server URL in Safari on your device

### Live TV Issues

**Stream Won't Start**
- Verify the backend has access to your HDHomeRun device
- Check that the channel is available and has a signal
- Ensure no other client is already watching (check backend logs)

**Playback Stalls or Buffers**
- The app uses a 10-second forward buffer by default
- If stalling persists, check your network connection quality
- Verify the backend transcoding process is running smoothly
- Monitor backend logs for encoding issues

**Stream Stops After Some Time**
- Check backend logs for heartbeat timeout messages
- Ensure the app remains in the foreground during playback
- Verify network stability between device and server

### Recorded Video Issues

**Video Won't Play**
- Verify the video URL is accessible from your device
- Check that the video format is supported by iOS (H.264, HEVC)
- Ensure your server is properly serving the video files

**Progress Not Saving**
- Check network connectivity during playback
- Verify the backend API is responding to progress updates
- Check for errors in the Xcode console

### Recording Schedule Issues

**Cannot Create Recording Rule**
- Ensure the program guide data is loaded
- Check that the series information is available
- Verify backend recording rule creation endpoint is working

**Recording Indicator Not Showing**
- Force refresh the guide by pulling down
- Check that recording rules are properly synced with backend

### General Issues

**App Crashes on Launch**
- Clean build folder (⌘+Shift+K)
- Delete derived data
- Rebuild the project

**UI Not Updating**
- Check console for API errors
- Verify server connectivity
- Try force-quitting and restarting the app

## Related Projects

- [tvhomerun-backend](https://github.com/anders94/tvhomerun-backend) - Server implementation
- [tvhomerun-tvos](https://github.com/anders94/tvhomerun-tvos) - Apple TV version

## License

MIT License - see LICENSE file for details

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
