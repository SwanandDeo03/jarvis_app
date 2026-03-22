"""
=======================================================
  JARVIS AI — Mobile API Server (api.py)
  Add these endpoints to your existing api.py to
  support the Flutter mobile app.
=======================================================
"""

from flask import Flask, request, jsonify
import os
import tempfile

# If you're using FastAPI, scroll down for that version too.

app = Flask(__name__)

# ── Import your existing Jarvis modules ──────────────
from brain.brain import think
from memory.memory import save_memory, load_memories

# ────────────────────────────────────────────────────
# ENDPOINT 1: Health check (used by app to check connectivity)
# ────────────────────────────────────────────────────
@app.route('/ping', methods=['GET'])
def ping():
    return jsonify({'status': 'ok', 'message': 'Jarvis online'}), 200


# ────────────────────────────────────────────────────
# ENDPOINT 2: Text query
# Body: { "message": "what is the weather today" }
# ────────────────────────────────────────────────────
@app.route('/ask', methods=['POST'])
def ask():
    data = request.get_json()
    message = data.get('message', '').strip()
    if not message:
        return jsonify({'error': 'No message provided'}), 400

    # Use your existing brain module
    reply = think(message)

    return jsonify({
        'reply': reply,
        'you': message,
    }), 200


# ────────────────────────────────────────────────────
# ENDPOINT 3: Voice input (audio file → transcript + reply)
# Multipart form: audio file at key "audio"
# ────────────────────────────────────────────────────
@app.route('/voice', methods=['POST'])
def voice():
    if 'audio' not in request.files:
        return jsonify({'error': 'No audio file provided'}), 400

    audio_file = request.files['audio']

    # Save to temp file
    with tempfile.NamedTemporaryFile(suffix='.wav', delete=False) as tmp:
        audio_path = tmp.name
        audio_file.save(audio_path)

    try:
        # Transcribe with Whisper (your existing setup)
        import whisper
        model = whisper.load_model("base")
        result = model.transcribe(audio_path, language='en')
        transcript = result['text'].strip()

        # Get reply from brain
        reply = think(transcript)

        return jsonify({
            'transcript': transcript,
            'reply': reply,
            'you': transcript,
        }), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500
    finally:
        os.unlink(audio_path)


# ────────────────────────────────────────────────────
# ENDPOINT 4: Fetch memories
# ────────────────────────────────────────────────────
@app.route('/memory', methods=['GET'])
def memory():
    try:
        memories = load_memories()  # Your existing function
        # memories should be a list of dicts with 'content' key
        if isinstance(memories, list):
            formatted = [{'content': str(m)} for m in memories]
        else:
            formatted = [{'content': str(memories)}]
        return jsonify({'memories': formatted}), 200
    except Exception as e:
        return jsonify({'memories': [], 'error': str(e)}), 200


# ────────────────────────────────────────────────────
# RUN — listen on all interfaces so phone can reach it
# ────────────────────────────────────────────────────
if __name__ == '__main__':
    print("🤖 Jarvis Mobile API starting...")
    print("📱 Connect your phone to the same WiFi")
    print(f"🌐 Find your WSL IP: run 'hostname -I' in WSL")
    app.run(host='0.0.0.0', port=5000, debug=False)


# ══════════════════════════════════════════════════════
# FastAPI version (if you prefer FastAPI over Flask)
# ══════════════════════════════════════════════════════
"""
from fastapi import FastAPI, File, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import uvicorn, tempfile, os, whisper
from brain.brain import think

app = FastAPI()
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

class TextQuery(BaseModel):
    message: str

@app.get("/ping")
def ping():
    return {"status": "ok"}

@app.post("/ask")
def ask(query: TextQuery):
    reply = think(query.message)
    return {"reply": reply, "you": query.message}

@app.post("/voice")
async def voice(audio: UploadFile = File(...)):
    with tempfile.NamedTemporaryFile(suffix='.wav', delete=False) as tmp:
        tmp.write(await audio.read())
        path = tmp.name
    try:
        model = whisper.load_model("base")
        transcript = model.transcribe(path, language='en')['text'].strip()
        reply = think(transcript)
        return {"transcript": transcript, "reply": reply}
    finally:
        os.unlink(path)

@app.get("/memory")
def memory():
    from memory.memory import load_memories
    return {"memories": [{"content": str(m)} for m in load_memories()]}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=5000)
"""
