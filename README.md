# OneStateLogin - Fullscreen Login dylib

## Features
- **Fullscreen login** - Covers entire screen
- **API verification** - Checks server for valid login
- **Device ID binding** - Binds to specific device
- **Disappears only on success** - Cannot be bypassed

## How to Build

### GitHub Actions (Automatic)
1. Fork this repository
2. Push to main branch
3. Download dylib from Releases

### Local Build (Mac)
```bash
export THEOS=~/theos
make clean
make
```

## How to Use

### 1. Configure API
Edit `OneStateLogin/LoginManager.mm`:
```cpp
#define API_URL "https://your-api-server.com/api/login"
```

### 2. Build
```bash
./build.sh
```

### 3. Sign & Inject
- Sign with your certificate (Esign, TrollStore)
- Inject into OneState app

## API Format

### Request:
```json
POST /api/login
{
  "username": "user",
  "password": "pass",
  "device_id": "UUID-HERE"
}
```

### Response:
```json
{
  "success": true,
  "token": "jwt-token",
  "expiry": "2024-12-31"
}
```

## Default Login
- Username: `admin`
- Password: `123456`

## License
MIT - For educational purposes only.
