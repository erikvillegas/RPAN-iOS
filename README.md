# RPAN Companion (iOS)

### Compiling source code
You'll need a Mac and Xcode 11 to run the code. All dependencies except two should already be included in this repo, so all you should have to do is open RPAN.xcworkspace and click the play button to run the app in the simulator! The first excluded dependency is  `GoogleService-Info.plist` that contains API keys that connect to Firestore. The second is `reddift_config.json` which contains the client ID for accessing the Reddit API. If you'd like to run a clone of the app pointed to a different server, you'll have to create these yourself. Otherwise message me to use the ones I use!

### Home screen
This screen relies on the same API the browser uses to show the top broadcast: https://strapi.reddit.com/broadcasts. This maps to the [Broadcast](https://github.com/erikvillegas/RPAN-iOS/blob/master/RPAN/Models/Broadcast.swift) model, and is used on the home screen to populate all the broadcasts. The networking code for this can be found in [RedditAPI.swift](https://github.com/erikvillegas/RPAN-iOS/blob/master/RPAN/Networking/RedditAPI.swift).

![Alt text](https://github.com/erikvillegas/RPAN-iOS/blob/master/Screenshots/Home.png?raw=true "Home")

### Settings screen
This screen lets the user:
1. Manage all users they have favorited on the home screen. See "Notifications screen".
2. Connect their Reddit account so they can import followers into favorites. See "Reddit integration".

![Alt text](https://github.com/erikvillegas/RPAN-iOS/blob/master/Screenshots/Settings.png?raw=true "Settings")

![Alt text](https://github.com/erikvillegas/RPAN-iOS/blob/master/Screenshots/SettingsLoggedOut.png?raw=true "SettingsLoggedOut")

### Notifications screen
This screen lets the user update their notification settings for the selected favorited broadcaster. The options include:
1. Turning on/off notifications for the broadcaster.
2. Disabling notifications when the broadcaster streams from specific RPAN subreddits.
3. Enabling cooldown to avoid excessive notifications from the broadcaster's streams.
4. Unfavorite the user.

![Alt text](https://github.com/erikvillegas/RPAN-iOS/blob/master/Screenshots/Notifications.png?raw=true "Notifications")

### Subreddit blacklist screen
All subreddits are enabled by default unless otherwise disabled by the user. Users can disable specific ones here!

![Alt text](https://github.com/erikvillegas/RPAN-iOS/blob/master/Screenshots/SubredditBlacklist.png?raw=true "Subreddit Blacklist")

### Reddit Integration
I created a Reddit "app" [here](https://old.reddit.com/prefs/apps/) that allows the iOS app to get an authorized access token for a user that grants access to their data. The code that initiates the login flow is in [LoginService.swift](https://github.com/erikvillegas/RPAN-iOS/blob/master/RPAN/Services/LoginService.swift). Scopes currently used are "identity", "mysubreddits", and "read".

The app uses [reddift](https://github.com/sonsongithub/reddift), a Swift wrapper for the Reddit API. The code that uses the access token for fetching user profile data is in [SettingsService.swift](https://github.com/erikvillegas/RPAN-iOS/blob/master/RPAN/Services/SettingsService.swift). 

During an import, the app fetches all subreddits a user is subscribed to, and only looks for the ones that are associated to a user. This is how Reddit handles followers for some reason. If a user chooses to stay logged in the app will, on every app launch, check for new followers that were added since the last app launch. If found, it will automatically convert them to a favorite in the app and enable notifications for them.

### Firestore Integration
The app uses a Firestore database for managing favorites. Every time a user favorites someone, or when a bulk import of followers is completed, a new [UserSubscription](https://github.com/erikvillegas/RPAN-iOS/blob/master/RPAN/Models/UserSubscription.swift) is created and persisted on disk locally, and the same data is sent to the server under the "subscriptions" key. Any change to notification settings for a broadcaster is immediately mirrored in Firestore. This data is utilized by the notification server to understand whether a notification should be emitted. The code for this can also be found in [SettingsService.swift](https://github.com/erikvillegas/RPAN-iOS/blob/master/RPAN/Services/SettingsService.swift).

The app also uses Firestore to persist the list of official RPAN subreddits since I couldn't find a way to do this through a Reddit API.

Lastly, Firestore is used to persist users that use the app, logged in or logged out. The global notification setting (found on the Settings screen) is stored here.

### Notification Server
I host a server in Digital Ocean for managing notifications. It invokes the /broadcasts API to check for new streams, and if found, inspects the Firestore database for users subscribing to the broadcaster. It then inspects the specific settings to determine if a notification should be emitted. If so, it uses [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging) for sending the push notification to the registered device. The user must have granted the app permission to send push notifications before the server can send them.

