# Scoped Storage Migration

**Date**: January 31, 2026  
**Version**: 1.0.0

## Overview

Flux has been migrated from using `MANAGE_EXTERNAL_STORAGE` permission to **Scoped Storage** to comply with Google Play Store policies and Android best practices.

## Why This Change?

### ❌ Previous Implementation (REMOVED)
- Used `MANAGE_EXTERNAL_STORAGE` permission
- Required special permission that Google Play Store restricts
- Only allowed for specific app categories (file managers, backup apps, etc.)
- Flux does NOT qualify for this permission

### ✅ New Implementation (Scoped Storage)
- Uses **app-specific external storage** (no permission needed)
- Complies with Android 10+ Scoped Storage requirements
- Follows Google Play Store policies
- More secure and privacy-friendly

## Technical Changes

### 1. AndroidManifest.xml

**Removed:**
```xml
<uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE"/>
```

**Added:**
```xml
<!-- Required for saving files on Android 9 and below -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
    android:maxSdkVersion="32"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
    android:maxSdkVersion="29"/>

<!-- Required for Android 13+ to read media files -->
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO"/>
<uses-permission android:name="android.permission.READ_MEDIA_AUDIO"/>
```

### 2. Permission Handling

**File**: `lib/src/core/providers/permission_provider.dart`

- **Android 10+ (API 29+)**: No runtime permission needed - uses Scoped Storage
- **Android 6-9 (API 23-28)**: Uses `READ/WRITE_EXTERNAL_STORAGE` permission
- **Android 5 and below**: No permission needed

### 3. File Storage Location

**File**: `lib/src/features/receive/data/file_storage_service.dart`

**Old Location** (Android 9 and below):
```
/storage/emulated/0/Download/
```

**New Location** (Android 10+):
```
/storage/emulated/0/Android/data/com.bun.studio.flux/files/Downloads/
```

**Benefits:**
- ✅ No permission required
- ✅ Files are automatically cleaned up when app is uninstalled
- ✅ Still accessible to users via file manager
- ✅ Can be moved to public Downloads if user chooses

## User Impact

### For Users on Android 10+ (API 29+)

**Before:**
1. App requested `MANAGE_EXTERNAL_STORAGE` permission
2. User had to go to Settings to grant permission
3. Files saved to public Downloads folder

**After:**
1. No permission dialog shown
2. Files saved to app-specific external storage
3. Files still accessible via file manager
4. Files automatically cleaned up on uninstall

### For Users on Android 6-9 (API 23-28)

**No change:**
- Still uses `READ/WRITE_EXTERNAL_STORAGE` permission
- Files saved to public Downloads folder

## File Access

### Received Files

Files received via Flux are saved to:
- **Android 10+**: `/Android/data/com.bun.studio.flux/files/Downloads/`
- **Android 9 and below**: `/Download/` (if permission granted)

Users can access these files via:
- Any file manager app
- Android's built-in Files app
- Can manually move files to public Downloads if desired

### Sending Files

Files are selected using **Storage Access Framework (SAF)**:
- Uses system file picker
- No permission needed
- User explicitly chooses which files to share
- Works on all Android versions

## Google Play Store Compliance

### ✅ Compliant

Flux now complies with Google Play Store policies:

1. **No MANAGE_EXTERNAL_STORAGE**: Removed restricted permission
2. **Scoped Storage**: Uses Android 10+ recommended approach
3. **Privacy-Friendly**: Only accesses files user explicitly selects
4. **Minimal Permissions**: Only requests necessary permissions

### Justification (if asked by Google)

> **Flux is a peer-to-peer file transfer application that:**
> 
> 1. **Receives files**: Saves to app-specific external storage using Scoped Storage (no permission needed on Android 10+)
> 2. **Sends files**: Uses Storage Access Framework (SAF) for user to select files (no permission needed)
> 3. **Does NOT need MANAGE_EXTERNAL_STORAGE**: App does not manage files across the entire device, only transfers user-selected files
> 
> All file operations comply with Android Scoped Storage best practices.

## Testing

### Test on Android 10+ (API 29+)

1. Install app
2. Verify no storage permission dialog shown
3. Receive a file
4. Check file saved to: `/Android/data/com.bun.studio.flux/files/Downloads/`
5. Verify file accessible via file manager
6. Uninstall app
7. Verify files are cleaned up

### Test on Android 6-9 (API 23-28)

1. Install app
2. Verify storage permission dialog shown
3. Grant permission
4. Receive a file
5. Check file saved to: `/Download/`
6. Verify file accessible via file manager

## Migration Notes

### For Existing Users

- Files previously saved to `/Download/` remain there
- New files will be saved to app-specific storage (Android 10+)
- Users can manually move old files if desired
- No data loss

### For Developers

- No code changes needed for file sending (already uses SAF)
- File receiving automatically uses correct storage location
- Permission handling is automatic based on Android version

## References

- [Android Scoped Storage](https://developer.android.com/training/data-storage#scoped-storage)
- [MANAGE_EXTERNAL_STORAGE Policy](https://support.google.com/googleplay/android-developer/answer/9956427)
- [Storage Access Framework](https://developer.android.com/guide/topics/providers/document-provider)

---

**Result**: Flux is now fully compliant with Google Play Store policies and ready for submission! 🎉

