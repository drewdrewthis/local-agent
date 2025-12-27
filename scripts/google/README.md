# Google Integration Library

A comprehensive Bash library for Google API integrations with Gmail, Calendar, Drive, and more.

## 🚨 Important: Working Directory Requirements

**All scripts must be run from the project root directory** (where the `.env` file is located).

❌ **Wrong:**
```bash
cd scripts/google/bin/
./gmail-check
```

✅ **Correct:**
```bash
# From project root
./scripts/google/bin/gmail-check
# Or
cd /path/to/project/root
scripts/google/bin/gmail-check
```

## Features

- 🔐 **Automatic OAuth token management** with caching and refresh
- 📧 **Gmail operations**: read, send, archive, search
- 📅 **Calendar operations**: list, create, update, delete events
- 🔄 **Robust error handling** with retry logic
- 📊 **Comprehensive logging** with rotation
- 🛠️ **Modular design** for easy extension

## Quick Start

### Prerequisites

- `curl`, `jq`, `openssl` installed
- Google Cloud project with OAuth credentials
- `.env` file with tokens (see below)

### Environment Setup

Create a `.env` file in the project root:

```bash
GOOGLE_CLIENT_ID="your_client_id"
GOOGLE_CLIENT_SECRET="your_client_secret"
GOOGLE_REFRESH_TOKEN="your_refresh_token"
```

### Basic Usage

**Important:** All commands must be run from the project root directory.

```bash
# From project root directory:
./scripts/google/bin/gmail-check --count-only

# Check unread email count
./scripts/google/bin/gmail-check --count-only

# List recent emails
./scripts/google/bin/gmail-check

# Archive all inbox emails
./scripts/google/bin/gmail-archive --all

# List upcoming calendar events
./scripts/google/bin/calendar-events

# Create a calendar event
./scripts/google/bin/calendar-events --create "Meeting" 2025-12-10 2025-12-10

# Check token status
./scripts/google/bin/token-refresh --status

# Update Google Sheets
./scripts/google/bin/sheets-update populate
```

## Library Structure

```
scripts/google/
├── lib/           # Core library files
│   ├── auth.sh    # OAuth token management
│   ├── api.sh     # Common API utilities
│   ├── gmail.sh   # Gmail operations
│   ├── calendar.sh # Calendar operations
│   └── utils.sh   # Logging and utilities
├── bin/           # Executable scripts
│   ├── gmail-check
│   ├── gmail-archive
│   ├── calendar-events
│   └── token-refresh
├── config/        # Configuration files
│   └── scopes.conf
└── logs/          # Log files
```

## API Reference

### Gmail Functions

```bash
gmail_get_profile              # Get user profile
gmail_list_messages [query] [max]  # List messages
gmail_get_message <id> [format]    # Get message details
gmail_archive_message <id>         # Archive single message
gmail_archive_messages <ids...>    # Archive multiple messages
gmail_send_message <to> <subject> <body>  # Send email
gmail_search <query>               # Search messages
gmail_get_unread_count             # Get unread count
```

### Calendar Functions

```bash
calendar_list_calendars           # List all calendars
calendar_list_events [calendar_id] [max]  # List events
calendar_create_event <cal_id> <summary> <start> <end>  # Create event
calendar_update_event <cal_id> <event_id> <updates>     # Update event
calendar_delete_event <cal_id> <event_id>               # Delete event
calendar_get_event <cal_id> <event_id>                  # Get event details
```

### Auth Functions

```bash
ensure_valid_token [force]        # Get valid access token
refresh_access_token             # Force token refresh
validate_token <token>           # Test token validity
```

## Configuration

### Environment Variables

- `GOOGLE_CLIENT_ID`: OAuth client ID
- `GOOGLE_CLIENT_SECRET`: OAuth client secret
- `GOOGLE_REFRESH_TOKEN`: Long-lived refresh token
- `DEBUG=true`: Enable debug logging
- `LOG_TO_FILE=false`: Disable file logging

### Scopes

Defined in `config/scopes.conf`:

- `GMAIL_READONLY`: Read Gmail messages
- `GMAIL_SEND`: Send emails
- `GMAIL_MODIFY`: Full Gmail access (read/write/archive)
- `CALENDAR`: Full calendar access
- `DRIVE`: Full Drive access

## Error Handling

The library includes comprehensive error handling:

- **Automatic retries** for transient failures
- **Token refresh** on 401 errors
- **Rate limiting** detection and backoff
- **Detailed logging** for troubleshooting
- **Graceful degradation** when services are unavailable

## Logging

Logs are written to `logs/google_integration.log` with automatic rotation at 10MB.

```bash
# Enable debug logging
DEBUG=true ./scripts/google/bin/gmail-check

# View recent logs
tail -f logs/google_integration.log
```

## Extending the Library

### Adding New APIs

1. Create a new library file in `lib/`
2. Source the common dependencies
3. Follow the established patterns
4. Add executable scripts in `bin/`

### Example: Adding Drive API

```bash
# lib/drive.sh
source "$SCRIPT_DIR/api.sh"

drive_list_files() {
    api_call "GET" "https://www.googleapis.com/drive/v3/files"
}
```

## Troubleshooting

### Common Issues

1. **Token errors**: Run `token-refresh --status` to check token validity
2. **Permission errors**: Verify OAuth scopes in Google Cloud Console
3. **API limits**: Check Google API quotas and usage
4. **Network issues**: Library handles retries automatically

### Debug Mode

Enable detailed logging:

```bash
DEBUG=true ./scripts/google/bin/[script-name]
```

### Troubleshooting

#### ".env file not found" Error

If you see this error, you're not running the script from the project root:

```bash
ERROR: .env file not found in current directory.
Please run this script from the project root directory (where .env is located).
```

**Solution:** Navigate to your project root and run the script:

```bash
cd /path/to/your/project  # Where .env file is located
./scripts/google/bin/sheets-update populate
```

#### Token Errors

If you get authentication errors:

```bash
./scripts/google/bin/token-refresh --status  # Check token status
./scripts/google/bin/token-refresh --force   # Force token refresh
```

## Security Notes

- Refresh tokens are stored securely in `.env`
- Access tokens are cached temporarily in `/tmp/`
- All API calls use HTTPS
- Sensitive data is not logged

## Contributing

When adding new features:

1. Follow existing code patterns
2. Add comprehensive error handling
3. Update this README
4. Test with both success and failure scenarios
5. Add logging for debugging

---

**Built with ❤️ for reliable Google API integrations**