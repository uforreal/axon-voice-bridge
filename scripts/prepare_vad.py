"""
Ferrari TTS - Phase 2.2: The Bouncer (Silero VAD)
================================================
Downloads the official Silero VAD ONNX model.
"""

import requests
from pathlib import Path

# Paths
MODELS_DIR = Path("ferrari_tts") / "models"
MODELS_DIR.mkdir(exist_ok=True, parents=True)

VAD_URL = "https://github.com/snakers4/silero-vad/raw/master/src/silero_vad/data/silero_vad.onnx"
VAD_PATH = MODELS_DIR / "silero_vad.onnx"

print("🚀 FERRARI TTS - Downloading Official Bouncer (Silero VAD)")
print("=" * 50)

try:
    print(f"Downloading from: {VAD_URL}")
    response = requests.get(VAD_URL)
    response.raise_for_status()
    
    with open(VAD_PATH, "wb") as f:
        f.write(response.content)
        
    print(f"✅ THE BOUNCER IS READY: {VAD_PATH}")
    print("Size: {:.2f} MB".format(VAD_PATH.stat().st_size / (1024 * 1024)))

except Exception as e:
    print(f"❌ Download failed: {e}")
