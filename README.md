BackgroundTracker
=================
A Sample iOS app for tracking location in the background
--------------------------------------------------------

Written in Swift 3 

Installation
^^^^^^^^^^^^

1. `git clone` this repo
2. `pod install`
3. Open `BackgroundTracker.xcworkspace`

Running 
^^^^^^^

1. Launch the app once on the device, a new geofencing event will be registered. 
2. You can then close the app or force-quit it.
3. Locations will be logged while you move. The app starts tracking when you start moving (based on geofencing event), and stops tracking location shortly after you stop moving.

