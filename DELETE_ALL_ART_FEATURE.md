# Delete All Art Feature

## Overview

A new **"Delete All Art"** button has been added to the Screenshot Frame add-on, allowing you to quickly clear all images from your Samsung TV's art gallery.

## How to Use

### Via Web Dashboard

1. Open your browser and navigate to:
   ```
   http://homeassistant-ip:5000/
   ```

2. You'll see the control dashboard with three buttons:
   - **Refresh Status** - Check current sync status
   - **Cleanup Stale Images** - Delete orphaned images from failed syncs
   - **Delete All Art** ⚠️ - Remove ALL images from TV

3. Click "Delete All Art" and confirm the deletion (twice for safety)

4. The dashboard shows:
   - Number of images successfully deleted
   - Number of images that failed to delete
   - Status updates in real-time

### Via API (curl)

```bash
# Delete all art from TV
curl -X POST http://homeassistant-ip:5000/delete-all

# Response example:
{
  "success": true,
  "deleted": 47,
  "failed": 0,
  "message": "Successfully deleted 47 art entries"
}
```

### Via Home Assistant Automation

```yaml
automation:
  - alias: "Clear Samsung Frame Art"
    trigger:
      time: "03:00:00"  # Daily at 3 AM
    action:
      service: shell_command.clear_frame_art

shell_command:
  clear_frame_art: 'curl -X POST http://homeassistant-ip:5000/delete-all'
```

## What It Does

1. **Connects to your TV** using the configured TV IP and port
2. **Retrieves the art list** from the TV
3. **Deletes each image** one by one with error handling
4. **Clears cached IDs** after successful deletion
5. **Logs detailed results** (check add-on logs if issues occur)

## API Response Format

```json
{
  "success": true/false,
  "deleted": <number>,
  "failed": <number>,
  "message": "<status message>"
}
```

| Field | Type | Meaning |
|-------|------|---------|
| `success` | boolean | True if operation completed (some/all deleted) |
| `deleted` | number | Count of successfully deleted images |
| `failed` | number | Count of images that failed to delete |
| `message` | string | Human-readable status/error message |

## Important Notes

⚠️ **WARNING**: This action:
- **Permanently deletes** all art from your TV
- **Cannot be undone** (unless you have backups)
- **Includes pre-installed Samsung images** (if present)
- **Clears the add-on's cached image IDs**

## Behavior in Different Scenarios

### TV is offline
- Returns error immediately
- No deletion occurs

### Some images can't be deleted
- Continues deleting others
- Reports count in `failed` field
- Returns `success: true` if at least one was deleted

### Delete-all takes too long
- Operation timeout: ~5 minutes (configurable via `TV_UPLOAD_TIMEOUT`)
- Partial deletion may have occurred
- Check TV and logs for status

## Troubleshooting

### Button says "Operation timed out"
- TV may be slow to respond
- Network connectivity issue
- Increase `TV_UPLOAD_TIMEOUT` in add-on settings

### Some images failed to delete
- Check add-on logs for specific error messages
- Some system/preinstalled images may be protected
- Try again in a few moments

### "TV upload not configured"
- Set `use_local_tv: true` in add-on settings
- Configure `tv_ip` with your TV's IP address
- Restart the add-on

## Dashboard Features

The control panel at `http://homeassistant-ip:5000/` shows:

- **Last Sync Time** - When the last screenshot was synced
- **Sync Status** - Success/failure of last operation
- **Last Error** - Any error from previous operation
- **Real-time buttons** for common operations
- **Visual feedback** with loading indicators

## API Endpoints Reference

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/` | GET | Control dashboard (HTML) |
| `/status` | GET | Current sync status (JSON) |
| `/screenshot` | GET | Current screenshot image |
| `/cleanup` | POST | Clean up stale images |
| `/delete-all` | POST | **Delete ALL art** |

## Logs

When you use the delete-all feature, check the add-on logs for:

```
[TV DELETE-ALL] Found <N> total art entries on TV
[TV DELETE-ALL] Deleting: <content_id>
[TV DELETE-ALL] Deletion complete: <N> deleted, <M> failed
```

Debug logging helps track issues:
- Enable `debug_logging: true` in add-on settings
- Provides per-image deletion details
