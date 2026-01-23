"""
Ferrari TTS - PC Test Bench
==========================
This script simulates the iPhone Ferrari Engine on your PC.
It uses the ONNX blueprint we forged and the Kokoro phonemizer.
"""

import os
import torch
import numpy as np
import onnxruntime as ort
from kokoro import KPipeline
import soundfile as sf
from pathlib import Path

# Paths
MODELS_DIR = Path("models")
ONNX_PATH = MODELS_DIR / "ferrari_kokoro.onnx"
OUTPUT_WAV = Path("ferrari_test_output.wav")

# 1. Phoneme Map (Copy-pasted from our Swift Tokenizer for consistency)
VOCAB = {
    ";": 1, ":": 2, ",": 3, ".": 4, "!": 5, "?": 6, "—": 9, "…": 10, "\"": 11,
    "(": 12, ")": 13, "“": 14, "”": 15, " ": 16, "\u0303": 17, "ʣ": 18, 
    "ʥ": 19, "ʦ": 20, "ʨ": 21, "ᵝ": 22, "\uAB67": 23, "A": 24, "I": 25, 
    "O": 31, "Q": 33, "S": 35, "T": 36, "W": 39, "Y": 41, "ᵊ": 42, "a": 43, 
    "b": 44, "c": 45, "d": 46, "e": 47, "f": 48, "h": 50, "i": 51, "j": 52, 
    "k": 53, "l": 54, "m": 55, "n": 56, "o": 57, "p": 58, "q": 59, "r": 60, 
    "s": 61, "t": 62, "u": 63, "v": 64, "w": 65, "x": 66, "y": 67, "z": 68, 
    "ɑ": 69, "ɐ": 70, "ɒ": 71, "æ": 72, "β": 75, "ɔ": 76, "ɕ": 77, "ç": 78, 
    "ɖ": 80, "ð": 81, "ʤ": 82, "ə": 83, "ɚ": 85, "ɛ": 86, "ɜ": 87, "ɟ": 90, 
    "ɡ": 92, "ɥ": 99, "ɨ": 101, "ɪ": 102, "ʝ": 103, "ɯ": 110, "ɰ": 111, 
    "ŋ": 112, "ɳ": 113, "ɲ": 114, "ɴ": 115, "ø": 116, "ɸ": 118, "θ": 119, 
    "œ": 120, "ɹ": 123, "ɾ": 125, "ɻ": 126, "ʁ": 128, "ɽ": 129, "ʂ": 130, 
    "ʃ": 131, "ʈ": 132, "ʧ": 133, "ʊ": 135, "ʋ": 136, "ʌ": 138, "ɣ": 139, 
    "ɤ": 140, "χ": 142, "ʎ": 143, "ʒ": 147, "ʔ": 148, "ˈ": 156, "ˌ": 157, 
    "ː": 158, "ʰ": 162, "ʲ": 164, "↓": 169, "→": 171, "↗": 172, "↘": 173, "ᵻ": 177
}

def text_to_ids(text, pipeline):
    """Simulates the Swift Tokenizer flow"""
    # Use Kokoro's pipeline to get phonemes
    generator = pipeline(text, voice='af_heart', speed=1, split_pattern=None)
    for graphemes, phonemes, audio in generator:
        print(f"Phonemes: {phonemes}")
        ids = [0]
        for char in phonemes:
            if char in VOCAB:
                ids.append(VOCAB[char])
        ids.append(0)
        return np.array([ids], dtype=np.int64)

def run_test():
    print("🏎️ FERRARI TEST BENCH STARTING...")
    
    if not ONNX_PATH.exists():
        print(f"❌ Error: {ONNX_PATH} not found. Run export_ferrari.py first.")
        return

    # 1. Setup
    pipeline = KPipeline(lang_code='a') # American English
    session = ort.InferenceSession(str(ONNX_PATH))
    
    # 2. Input
    test_text = "I am the Ferrari engine. I am running locally on your hardware."
    print(f"Testing Text: {test_text}")
    
    input_ids = text_to_ids(test_text, pipeline)
    speed = np.array([1.0], dtype=np.float32)
    
    # 3. Inference
    print("Running ONNX Inference...")
    outputs = session.run(None, {
        "input_ids": input_ids
    })
    
    audio = outputs[0]
    
    # 4. Save
    sf.write(OUTPUT_WAV, audio, 24000)
    print(f"✅ SUCCESS: Audio saved to {OUTPUT_WAV}")
    print("You can now listen to the Ferrari blueprint on your PC.")

if __name__ == "__main__":
    run_test()
