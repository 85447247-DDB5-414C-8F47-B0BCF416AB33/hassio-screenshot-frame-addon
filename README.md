# Screenshot Frame - Home Assistant Add-on

Render Home Assistant dashboards (or any URL) with pyppeteer and send screenshots directly to Samsung Frame TV via WebSocket API.

## Features

- **pyppeteer Rendering**: Headless Chromium captures any URL as PNG with configurable resolution and zoom
- **Direct TV Upload**: Async WebSocket connection to Samsung Frame TV for instant art mode updates
- **Flexible Authentication**: Support for bearer tokens, basic auth, or custom headers for image providers
- **Replace Last**: Optionally replace the previous uploaded image instead of creating new art entries
- **HTTP API**: Access rendered images via HTTP endpoints

## Configuration

### Image Provider

| Option | Description | Default |
|--------|-------------|---------|
| `target_url` | URL to screenshot (HTML page or image) | `http://homeassistant.local:5000/` |
| `target_auth_type` | Authentication type: `none`, `bearer`, `basic`, `headers` | `none` |
| `target_token` | Bearer token value | `""` |
| `target_token_header` | Header name for token | `Authorization` |
| `target_token_prefix` | Token prefix (e.g., "Bearer") | `Bearer` |
| `target_username` | Username for basic auth | `""` |
| `target_password` | Password for basic auth | `""` |
| `target_headers` | JSON map of custom headers | `""` |

| Option | Description | Default |
|--------|-------------|---------|
| `screenshot_width` | Screenshot width in pixels | `1920` |
| `screenshot_height` | Screenshot height in pixels | `1080` |
| `screenshot_zoom` | Zoom percentage (10-500%) | `100` |
| `screenshot_wait` | Seconds to wait after DOM load for dynamic content (0 = no wait) | `2.0` |
| `screenshot_skip_navigation` | Skip page reload after first load (for auto-refreshing pages like DakBoard) | `false` |
| `interval_seconds` | Seconds between screenshot updates | `300` |
| `http_port` | HTTP server port | `8200` |

### Samsung TV Settings

| Option | Description | Default |
|--------|-------------|---------|
| `use_local_tv` | Enable direct TV upload | `true` |
| `tv_ip` | Samsung Frame TV IP address | `""` |
| `tv_port` | TV WebSocket port | `8002` |
| `tv_matte` | Matte style: `modern`, `warm`, `cold`, `none` | `""` |
| `tv_show_after_upload` | Show image immediately after upload | `true` |
| `tv_replace_last` | Replace previous image instead of creating new entry | `false` |

## Usage

1. Add this repository to Home Assistant:
   ```
   https://github.com/dangerusty/hassio-screenshot-frame-addon
   ```

2. Install the "Screenshot Frame Addon" add-on

3. Configure your Samsung Frame TV IP address and image provider URL

4. Start the add-on

5. (Optional) Access the HTTP API:
  - `http://[host]:8200/art.jpg` - View current screenshot

## Authentication Examples

### Home Assistant Dashboard with Bearer Token

```json
{
  "target_url": "http://homeassistant.local:8123/lovelace/dashboard",
  "target_auth_type": "bearer",
  "target_token": "your_long_lived_access_token"
}
```

### External Service with Basic Auth

```json
{
  "target_url": "https://example.com/dashboard",
  "target_auth_type": "basic",
  "target_username": "user",
  "target_password": "pass"
}
```

### Custom Headers (JSON)

```json
{
  "target_url": "https://api.example.com/image",
  "target_auth_type": "headers",
  "target_headers": "{\"X-API-Key\": \"your-key\", \"X-Custom\": \"value\"}"
}
```

## How It Works

1. Addon periodically fetches from `target_url`
2. If HTML is detected, pyppeteer renders it with a **persistent Chromium browser** at the configured resolution and zoom
3. Resulting image is uploaded to Samsung Frame TV via async WebSocket connection
4. Browser instance stays running between screenshots for faster subsequent renders (~5-10s vs ~90s)

## Performance Tips

For fast refresh rates (60 seconds or less):

- **`screenshot_wait`**: Lower values (0.5-1.5s) render faster but may miss slow-loading content. Higher values (2-5s) ensure content loads but take longer.
- **`screenshot_skip_navigation`**: Enable this for auto-refreshing pages like DakBoard. The page loads once and subsequent screenshots just capture the already-loaded (and auto-refreshed) page. This is much faster (~1-2s per screenshot after initial load).
- **`interval_seconds`**: With persistent browser, 60-second intervals are achievable. First screenshot takes ~60s to launch browser, subsequent ones take ~5-10s (or ~1-2s with skip_navigation enabled).
- **DakBoard**: Simple screens render faster than complex ones with many widgets/images. Enable `screenshot_skip_navigation: true` since DakBoard auto-refreshes its own content.
4. TV displays the image in art mode (if `tv_show_after_upload` is true)
5. Optional: Replace the previous image to avoid filling up TV storage

## Requirements

- Samsung Frame TV (2017 or newer)
- TV must be on the same network as Home Assistant
- TV art mode must be supported and enabled

## Troubleshooting

### TV Not Connecting

- Verify TV IP address and port (usually 8002 for newer models, 8001 for older)
- Ensure TV is powered on and connected to network
- Check Home Assistant logs for connection errors

### pyppeteer Rendering Issues

- Increase `screenshot_zoom` if content appears too small
- Adjust `screenshot_width` and `screenshot_height` for your TV's native resolution
- Check provider URL is accessible from the add-on container

### Authentication Failures

- For Home Assistant dashboards, create a long-lived access token
- Verify auth credentials in add-on logs
- Test provider URL manually with curl/browser

## Credits

- Based on [hass-lovelace-kindle-screensaver](https://github.com/sibbl/hass-lovelace-kindle-screensaver)
- Uses [samsung-tv-ws-api](https://github.com/xchwarze/samsung-tv-ws-api) for TV communication

## License

MIT
