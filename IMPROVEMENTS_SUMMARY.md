# Samsung TV Image Deletion - Improvements Summary

## Changes Made

Your screenshot-frame addon now has improved image deletion reliability with these fixes:

### 1. **Better Retry Logic** ✅
- **Before**: If image selection failed, old images were never deleted
- **After**: Cached image ID is preserved on selection failure, automatically retried next cycle

### 2. **Enhanced Logging** ✅
Changed logging level for deletion operations from `debug` to `info` and `error`:
- Now shows exactly what's happening during deletion
- Clear indication of success, failure, or skip reasons
- Easier to troubleshoot in logs

### 3. **New Cleanup Function** ✅
Added `cleanup_stale_images_async()` that can be called independently to force delete old images:
- Reads the cached image ID from `/data/last-art-id.txt`
- Attempts to delete it from the TV
- Clears the cache file on success

### 4. **Manual Cleanup Endpoint** ✅
New HTTP POST endpoint for manual cleanup:

```bash
curl -X POST http://<your-home-assistant>:5000/cleanup
```

Response:
```json
{
  "success": true,
  "message": "Cleanup completed"
}
```

### 5. **Automatic Startup Cleanup** ✅
On add-on startup, attempts to clean up any orphaned images from previous failed runs

## What to Do Now

### Monitor Logs (if issues occur)
1. Enable debug logging: `DEBUG_LOGGING: true` in add-on configuration
2. Watch the logs for deletion attempts
3. Look for patterns in errors

### Manual Cleanup
If old images still exist on your TV:
```bash
curl -X POST http://homeassistant-ip:5000/cleanup
```

### View Documentation
See [TROUBLESHOOTING_IMAGE_DELETION.md](TROUBLESHOOTING_IMAGE_DELETION.md) for detailed troubleshooting guide

## Key Log Messages to Look For

**✅ Success:**
```
[TV UPLOAD] ✓ Previous art successfully deleted
```

**⚠️ Will Retry:**
```
[TV UPLOAD] ERROR: Failed to delete previous art (ID: XYZ789): Connection timeout
[TV UPLOAD] Selection failed - keeping cached ID for next deletion attempt: XYZ789
```

**ℹ️ No Action Needed:**
```
[TV UPLOAD] New image ID matches cached ID, no deletion needed
[TV UPLOAD] No previous cached image ID; nothing to delete
```

## Implementation Details

### Files Modified
- `screenshot-frame/main.py` - Core improvements

### New Features
1. Retry logic for deletion on selection failure
2. `cleanup_stale_images_async()` function
3. `/cleanup` HTTP endpoint
4. Automatic cleanup on startup
5. Better error reporting and logging

### Backward Compatible
✅ All changes are backward compatible - no configuration changes needed!

## Next Steps (Optional)

For advanced users:
1. Monitor `/status` endpoint to track sync success
2. Set up Home Assistant automations to alert on failures
3. Check TV storage periodically: Art Mode → Settings → Storage

For issues:
1. Check [TROUBLESHOOTING_IMAGE_DELETION.md](TROUBLESHOOTING_IMAGE_DELETION.md)
2. Run manual cleanup via endpoint
3. Enable debug logging if problems persist
