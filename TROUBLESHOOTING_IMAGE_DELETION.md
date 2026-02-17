# Troubleshooting Image Deletion Issues on Samsung TV

## Problem Summary

The add-on was sometimes failing to delete old images from the Samsung TV, causing image accumulation over time. This could happen for several reasons:

1. **Image selection fails** → Old image never deleted (deletion only happens after new image is successfully selected)
2. **Deletion call fails** → Exception caught and logged as warning, but not retried
3. **Cached ID becomes stale** → Old image ID stored locally, but TV may have already cleaned it up or it's no longer valid

## Root Cause Analysis

The original code had these issues:

```python
# Delete old art only after new art is successfully selected
if selection_successful and last_id and last_id != content_id:
    try:
        logger.debug(f'[TV UPLOAD] Deleting previous art entry: {last_id}')
        tv.delete(last_id)
        logger.debug('[TV UPLOAD] ✓ Previous art deleted')
    except Exception as e:
        logger.warning(f'[TV UPLOAD] Warning: Failed to delete previous art: {e}')
```

**Issues:**
- ❌ Only logs a warning if deletion fails—no retry mechanism
- ❌ If image selection fails, deletion is skipped entirely
- ❌ No way to clean up orphaned images

## Solutions Implemented

### 1. **Decouple Deletion from Selection Success** ✓ FIXED
- **OLD**: Deletion only happens if image selection succeeds
- **NEW**: Deletion happens regardless of selection outcome
  - Image may not display (if TV not in art mode), but cleanup still occurs
  - This prevents image accumulation when TV is busy/not in art mode

### 2. **Exponential Retry Mechanism** ✓ FIXED
- **NEW**: Failed deletions are automatically retried on subsequent sync cycles
- Up to 5 retry attempts (configurable via `TV_DELETION_RETRY_MAX` env var)
- Retry state persisted in `/data/tv-deletion-retry.json`
- Helpful when TV is temporarily unavailable or busy

### 3. **Better Art Mode Handling** ✓ FIXED
- TV art mode status is now checked before selection
- Code no longer silently fails when TV is not in art mode
- Image is still uploaded and cached—just not immediately displayed
- Will be displayed when TV returns to art mode

### 4. **Enhanced Logging and Diagnostics** ✓ NEW
New log messages show exactly what's happening:

```
[TV UPLOAD] TV art mode status: off (type: str)
[TV UPLOAD] WARNING: Failed to select uploaded image: Device not in art mode
[TV UPLOAD] Image will be available in TV gallery, but not currently displayed
[TV UPLOAD] Attempting to delete previous art entry: ABC123 (attempt 1/5)
[TV UPLOAD] Will retry deletion on next sync cycle (attempts remaining: 4)
```

### 5. **Persistence of New Images During Retries** ✓ FIXED
- New image ID is always cached, even if selection fails
- Previous images are retried for deletion on next cycle
- Prevents loss of image references when TV is temporarily busy

## Configuration Options

### Deletion Retry Configuration

You can customize the retry behavior by setting environment variables:

```yaml
# Maximum number of deletion retry attempts (default: 5)
TV_DELETION_RETRY_MAX: 5
```

Retry state is persisted in `/data/tv-deletion-retry.json`

## How to Troubleshoot

### Step 1: Enable Debug Logging

Set `DEBUG_LOGGING=true` in your add-on configuration to see detailed logs:

```yaml
DEBUG_LOGGING: true
```

Then watch the logs:

```bash
# In Home Assistant, go to: Settings > Add-ons > Screenshot to Samsung Frame > Logs
# Or via CLI: ssh to your Home Assistant instance and check /config/logs/
```

### Step 2: Look for Deletion Error Patterns

Common error messages and solutions:

| Error | Meaning | Solution |
|-------|---------|----------|
| `Failed to select uploaded image` | New image upload failed | Check TV connection, verify it's in Art Mode |
| `Failed to delete previous art: Connection timeout` | TV not responding to delete | Restart TV, check network connectivity |
| `Selection failed; skipping deletion` | Image uploaded but not selected | Will retry on next cycle |

### Step 3: Manual Cleanup

If images are still accumulating, manually trigger cleanup:

```bash
# Using curl
curl -X POST http://homeassistant-ip:5000/cleanup

# Using Home Assistant's Developer Tools > Services
# Entity: POST /cleanup
```

Check the logs afterward for the result.

### Step 4: Check Cached Image ID

The add-on stores the last successfully selected image ID in:

```
/data/last-art-id.txt
```

This ID is used for cleanup on the next cycle. If images aren't being deleted:

1. SSH into your Home Assistant instance
2. Check the file:
   ```bash
   cat /config/screenshot-frame/last-art-id.txt
   ```
3. If the file exists, that ID should be deleted on the next upload cycle
4. If deletion is still failing, check TV error logs

## Configuration Options (for Advanced Troubleshooting)

```yaml
# In add-on configuration
INTERVAL_SECONDS: 300          # How often to upload (default: 300s/5min)
TV_UPLOAD_TIMEOUT: 60          # Timeout for TV operations (default: 60s)
TV_SHOW_AFTER_UPLOAD: true     # Auto-display images after upload
DEBUG_LOGGING: true             # Verbose logging (when troubleshooting)
```

## Recommended Settings

For reliable image management:

```yaml
INTERVAL_SECONDS: 300          # 5 minutes between updates
TV_UPLOAD_TIMEOUT: 60          # Reasonable timeout
TV_SHOW_AFTER_UPLOAD: true     # Auto-select new image
DEBUG_LOGGING: false            # Disable after testing (reduces log noise)
```

## What the Logs Tell You

### Successful cycle:
```
[TV UPLOAD] Uploading new art entry
[TV UPLOAD] Upload returned id: ABC123
[TV UPLOAD] ✓ Selected uploaded image on TV (show=True)
[TV UPLOAD] Attempting to delete previous art entry: XYZ789
[TV UPLOAD] ✓ Previous art successfully deleted
[TV UPLOAD] ✓ Cached art ID ABC123
```

### Failed deletion (will retry):
```
[TV UPLOAD] Attempting to delete previous art entry: XYZ789
[TV UPLOAD] ERROR: Failed to delete previous art (ID: XYZ789): Connection timeout
[TV UPLOAD] Selection failed; skipping deletion of previous art (ID: XYZ789)
```

### No deletion needed:
```
[TV UPLOAD] New image ID matches cached ID (ABC123), no deletion needed
[TV UPLOAD] No previous cached image ID; nothing to delete
```

## API Endpoints

The add-on now exposes these endpoints (default port 5000):

```bash
# Check sync status
curl http://homeassistant-ip:5000/status

# Get current screenshot
curl http://homeassistant-ip:5000/screenshot > current.jpg

# Manually trigger cleanup
curl -X POST http://homeassistant-ip:5000/cleanup
```

## Long-term Monitoring

Set up Home Assistant automations to check the status endpoint periodically:

```yaml
automation:
  - alias: "Check Screenshot Frame Status"
    trigger:
      platform: time_pattern
      hours: "/1"  # Every hour
    action:
      service: rest.reload_resource_template
      data:
        resource: "http://homeassistant-ip:5000/status"
```

Or monitor for failed syncs:

```yaml
binary_sensor:
  - platform: rest
    resource: "http://homeassistant-ip:5000/status"
    name: "Screenshot Frame Sync Success"
    json_attributes:
      - last_sync
      - error
```

## If Issues Persist

1. **Check TV Storage**: Some Samsung TVs have limited storage. Clear old images directly from the TV:
   - Art Mode > Settings > Storage/Gallery Management

2. **Verify Network**: Ensure TV and Home Assistant are on stable network:
   ```bash
   ping <TV_IP>
   ```

3. **TV Logs**: Check if TV has any network or storage errors (varies by model)

4. **Request Help**: When reporting issues, include:
   - Full debug logs from at least one complete sync cycle
   - Output of `/cleanup` endpoint
   - Your TV model
   - Network setup (wired vs WiFi, any firewalls)

## Technical Details

### How Deletion Works Now

1. **Upload cycle**: New image uploaded, assigned ID (e.g., "ABC123")
2. **Selection**: New image selected on TV
3. **Cleanup**: If selection successful and we have a previous ID, delete it
4. **Caching**: New ID saved to `/data/last-art-id.txt`

### Retry Logic

- If deletion fails → ID kept in cache → Retried on next cycle
- If selection fails → ID not updated → Retried on next cycle
- If selection succeeds but deletion fails → New ID cached anyway (can always retry cleanup endpoint)

### Cache File Format

```
/data/last-art-id.txt
```

Contains a single line with the image ID:
```
ABC123-DEF456-GHI789
```

This is deleted by cleanup after successful deletion.
