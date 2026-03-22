# 📱 Jarvis AI — Flutter Mobile App

A sleek, Iron Man-inspired mobile interface for your personal Jarvis AI system.

---

## 🎨 Design
- **Arc Reactor** animated centerpiece with real-time states
- **Iron Man / Arc Reactor** color palette — deep navy, cyan glow, gold accents
- Animated rotating rings change color based on state:
  - 🔵 **Blue** = Idle/Ready
  - 🔴 **Red** = Recording your voice
  - 🟡 **Gold** = Processing/Thinking

---

## 📁 Project Structure
```
lib/
├── main.dart                  # App entry point
├── theme/
│   └── jarvis_theme.dart      # Colors, fonts, theme
├── models/
│   └── chat_message.dart      # Message model + ChatProvider
├── services/
│   ├── api_service.dart       # HTTP calls to Python backend
│   └── audio_service.dart     # Mic recording
├── widgets/
│   ├── arc_reactor.dart       # Animated Arc Reactor + status
│   └── chat_bubble.dart       # Chat message bubbles
└── screens/
    ├── home_screen.dart        # Main screen
    └── settings_screen.dart    # Server config + setup guide
```

---

## 🚀 Setup Instructions

### Step 1 — Update your Python api.py
Add Flask/FastAPI endpoints to your existing `api.py`. 
Copy from `api_template.py` in this project.

Install dependencies:
```bash
pip install flask  # or fastapi uvicorn
```

Run with:
```bash
python api.py
```

Make sure it says: `Running on http://0.0.0.0:5000`

### Step 2 — Find your WSL IP
In WSL terminal:
```bash
hostname -I
# e.g., 172.20.10.5
```

Your phone URL will be: `http://172.20.10.5:5000`

### Step 3 — Run the Flutter App
```bash
cd jarvis_app
flutter pub get
flutter run
```

### Step 4 — Configure in App
1. Open the app → tap ⚙️ Settings (top right)
2. Enter your WSL IP URL: `http://172.20.10.5:5000`
3. Tap **Test Connection** — should show ✓ Connected!
4. Save and go back

---

## 🎙️ Using the App

| Button | Action |
|--------|--------|
| 🎤 Big mic button | Tap to start recording, tap again to send |
| ⌨️ TYPE button | Toggle text input keyboard |
| 🧠 MEMORY button | View Jarvis's stored memories |
| 🗑️ Delete icon | Clear chat history |
| ⚙️ Tune icon | Open settings |

---

## 📡 API Endpoints the App Expects

| Method | Endpoint | Purpose |
|--------|----------|---------|
| GET | `/ping` | Health check |
| POST | `/ask` | `{"message": "..."}` → `{"reply": "..."}` |
| POST | `/voice` | Multipart audio → `{"transcript":"...", "reply":"..."}` |
| GET | `/memory` | `{"memories": [{"content": "..."}]}` |

---

## 📦 Key Dependencies

```yaml
record: ^5.0.4          # Mic recording
http: ^1.1.0            # API calls  
flutter_animate: ^4.3.0 # Animations
google_fonts: ^6.1.0    # Rajdhani font
provider: ^6.1.1        # State management
permission_handler: ^11.1.0  # Mic permissions
```

---

## 🔧 Troubleshooting

**Can't connect?**
- Make sure api.py uses `host="0.0.0.0"` not `"localhost"`
- Phone and PC must be on same WiFi network
- Check Windows Firewall — allow port 5000
- WSL2: You may need to forward the port:
  ```powershell
  netsh interface portproxy add v4tov4 listenport=5000 listenaddress=0.0.0.0 connectport=5000 connectaddress=<WSL-IP>
  ```

**Mic not working?**
- Grant microphone permission when prompted
- Check Android Settings → Apps → Jarvis AI → Permissions

---

## 🎯 Future Enhancements
- [ ] WebSocket for real-time streaming responses
- [ ] Wake word detection ("Hey Jarvis")  
- [ ] TTS playback of Jarvis responses in-app
- [ ] Conversation export
- [ ] Widget / quick-access shortcut
