# TV HomeRun for iOS

A SwiftUI-based streaming client for iOS that connects to a server running [tvhomerun-web](https://github.com/anders94/tvhomerun-web), enabling you to browse and watch video content on iPhone and iPad.

## Features

- **Server Configuration**: Persistent URL storage with validation
- **Content Browsing**: Grid-based show display with thumbnails and metadata
- **Episode Management**: Lists episodes with progress tracking and watch indicators
- **Advanced Playback**: Video player supporting resume functionality, seek controls, and auto-play for subsequent episodes
- **Error Resilience**: Exponential backoff retry logic (1s, 2s, 4s intervals) with user notifications after 5 seconds
- **Touch-Optimized UI**: iOS-specific interface design optimized for iPhone and iPad

## Requirements

- iOS 15.0+
- Xcode 14.0+
- Swift 5.7+
- A server running [tvhomerun-web](https://github.com/anders94/tvhomerun-web)

## Installation

1. Double-click the `.xcodeproj` file to open in Xcode
2. Select your target device or simulator
3. Press ⌘+R to build and run

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
│   │   └── Show.swift              # Show data model
│   ├── Services/
│   │   └── APIClient.swift         # API client with error handling
│   ├── Utilities/
│   │   └── UserSettings.swift      # UserDefaults wrapper
│   └── Views/
│       ├── ServerSetupView.swift   # Server URL configuration
│       ├── ShowsListView.swift     # Shows grid view
│       ├── EpisodesListView.swift  # Episodes list view
│       ├── VideoPlayerView.swift   # Video player view
│       └── VideoPlayerViewModel.swift # Player state management
└── README.md
```

## Architecture

The app follows the MVVM (Model-View-ViewModel) architecture pattern:

### Models Layer
- **Show**: Represents a TV show with metadata
- **Episode**: Represents an episode with playback tracking
- **Health**: Server health status

### Services Layer
- **APIClient**: Handles all network requests with exponential backoff retry logic
  - Automatically retries failed requests up to 3 times
  - Uses 1s, 2s, 4s backoff intervals
  - Shows error alerts after 5 seconds of failures

### Views Layer
- **ServerSetupView**: Server URL configuration with validation
- **ShowsListView**: Grid display of available shows
- **EpisodesListView**: List of episodes for a selected show
- **VideoPlayerView**: Full-screen video player with native iOS controls
- **VideoPlayerViewModel**: Manages playback state, progress tracking, and episode navigation

### Utilities
- **UserSettings**: Persistent storage for server URL and setup state

## API Integration

The app communicates with three primary endpoints:

- `GET /health` - Server connectivity verification
- `GET /api/shows` - Retrieve available shows
- `GET /api/shows/:id/episodes` - Retrieve episodes for a show
- `PUT /api/episodes/:id/progress` - Update playback progress

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

This iOS version is adapted from the tvOS version with the following changes:

- **UI Scaling**: Adjusted font sizes, spacing, and component sizes for smaller screens
- **Grid Layout**: 2-column grid instead of 4-column for mobile devices
- **Touch Navigation**: Standard iOS touch navigation instead of tvOS focus engine
- **Button Styles**: Plain button styles instead of tvOS card styles
- **Responsive Design**: Works on both iPhone and iPad with adaptive layouts

## Usage

1. **First Launch**: Enter your server URL (e.g., `http://192.168.1.100:3000`)
2. **Browse Shows**: Scroll through your available shows in the grid view
3. **Select Show**: Tap a show to view its episodes
4. **Watch Episode**: Tap an episode to start playback
5. **Resume**: Episodes automatically resume from where you left off
6. **Auto-Play**: Next episode plays automatically when current episode ends

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

For testing, you'll need a server running locally at a specified port (default: 3000) that implements the API endpoints. See [tvhomerun-web](https://github.com/anders94/tvhomerun-web) for the server implementation.

## Troubleshooting

### Cannot Connect to Server

- Ensure your iOS device and server are on the same network
- Verify the server URL is correct (include `http://` and port number)
- Check that your server is running and accessible
- Try accessing the server URL in Safari on your device

### Video Won't Play

- Verify the video URL is accessible from your device
- Check that the video format is supported by iOS (H.264, HEVC)
- Ensure your server is properly serving the video files

### App Crashes on Launch

- Clean build folder (⌘+Shift+K)
- Delete derived data
- Rebuild the project

## Related Projects

- [tvhomerun-web](https://github.com/anders94/tvhomerun-web) - Server implementation
- [tvhomerun-appletv](https://github.com/anders94/tvhomerun-appletv) - Apple TV version

## License

MIT License - see LICENSE file for details

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
