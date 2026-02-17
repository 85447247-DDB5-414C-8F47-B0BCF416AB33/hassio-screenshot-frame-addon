# Image Deletion Improvements - Summary

## Problem Identified

Images were not being deleted from the Samsung TV because **deletion was tied to successful image selection**. When the TV was busy or not in Art Mode, the selection would fail, and therefore the deletion would never happen—causing image accumulation.

## Solution Implemented

### 1. **Decouple Deletion from Selection** (Key Fix)
- Deletion now happens **regardless** of whether image selection succeeds
- Image may not display immediately (if TV not in Art Mode), but will be cleaned up
- Prevents accumulation when TV is busy/not in Art Mode

### 2. **Retry Mechanism for Failed Deletions**
- Failed deletions are automatically retried on subsequent sync cycles
- Up to 5 retry attempts (configurable: `TV_DELETION_RETRY_MAX`)
- Retry state persisted in `/data/tv-deletion-retry.json`
- Each attempt logs clearly: `(attempt 1/5)`, `(attempt 2/5)`, etc.

### 3. **Better Art Mode Detection**
- Code now checks if TV is in Art Mode before selecting
- Provides clear warnings if TV is not in Art Mode
- Image still uploads and caches—just not displayed until TV enters Art Mode

### 4. **Enhanced Logging**
New log messages make troubleshooting clear:

```
[TV UPLOAD] TV art mode status: off
[TV UPLOAD] WARNING: Failed to select uploaded image: Device not in art mode
[TV UPLOAD] Image will be available in TV gallery, but not currently displayed
[TV UPLOAD] Attempting to delete previous art entry: ABC123 (attempt 1/5)
[TV UPLOAD] ERROR: Failed to delete previous art: Connection timeout
[TV UPLOAD] Will retry deletion on next sync cycle (attempts remaining: 4)
```

### 5. **Persistent Image Caching**
- New image IDs are always cached, even if selection fails
- Previous images are retried for deletion on next cycle
- No loss of image references when TV is temporarily busy

## Key Code Changes

```python
# NEW: Delete images REGARDLESS of selection success
deletion_successful = False
if last_id and last_id != content_id:
    if _should_retry_deletion(last_id):
        try:
            retry_count = _increment_deletion_retry(last_id)
            logger.info(f'Attempting to delete... (attempt {retry_count}/{TV_DELETION_RETRY_MAX})')
            tv.delete(last_id)
            _clear_deletion_retry(last_id)  # Success: clear retry counter
            deletion_successful = True
        except Exception as e:
            logger.error(f'Failed to delete: {e}')
            logger.warning(f'Will retry... (attempts remaining: {TV_DELETION_RETRY_MAX - retries})')
    else:
        logger.error(f'Max retry attempts exceeded for ID: {last_id}')
```

## Configuration

Add to your add-on config.yaml:

```yaml
TV_DELETION_RETRY_MAX: 5  # Max retry attempts (default: 5)
DEBUG_LOGGING: true       # Enable detailed logging
```

## Monitoring

Enable `DEBUG_LOGGING: true` and watch the logs to see:
- When images are being deleted
- Retry attempts and remaining attempts
- Why selections might be failing
- Overall sync status

## Result

✅ Images will now be properly deleted from the TV even if:
- TV is not in Art Mode during sync
- TV is temporarily busy
- Network connection is momentarily interrupted

Previous deletion failures will be automatically retried on the next sync cycle.
