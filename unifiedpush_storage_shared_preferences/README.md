# UnifiedPush Storage using Shared Preferences

This provides storage for UnifiedPush registrations using shared preferences.

**The data is not encrypted** and the keys used to decrypt push notifications are stores in cleartext in the user home directory.

This implementation is basic, and may not be enough optimized if your application relies on hundreds of different registrations.

**The storage is only used for Linux applications**.
