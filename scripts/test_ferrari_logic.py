"""
Ferrari TTS - Logic Test Bench (Cortex Mode)
===========================================
This script tests the 'Logic' of the Ferrari (Thalamus Codec).
It processes text with markers like [pause], [soft], and [gentle]
to simulate the complex human delivery we want on the iPhone.
"""

import os
import re
import torch
import numpy as np
import onnxruntime as ort
from kokoro import KPipeline
import soundfile as sf
from pathlib import Path

# Paths
MODELS_DIR = Path("models")
ONNX_PATH = MODELS_DIR / "ferrari_kokoro.onnx"
OUTPUT_WAV = Path("ferrari_logic_output.wav")

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

class FerrariCortex:
    def __init__(self, model_path):
        self.session = ort.InferenceSession(str(model_path))
        self.pipeline = KPipeline(lang_code='a')

    def _get_ids(self, text):
        generator = self.pipeline(text, voice='af_heart', speed=1, split_pattern=None)
        for _, phonemes, _ in generator:
            ids = [0]
            for char in phonemes:
                if char in VOCAB:
                    ids.append(VOCAB[char])
            ids.append(0)
            return np.array([ids], dtype=np.int64)

    def process_logic(self, rich_text):
        """
        Parses markers like [pause:0.5], [soft], etc.
        Returns the final combined audio.
        """
        # Split text into segments based on markers
        # Example: "[breath] Hello [pause:0.5] world..."
        segments = re.split(r'(\[.*?\]|\.\.\.)', rich_text)
        
        final_audio = []
        current_volume = 1.0
        current_speed = 1.0

        for seg in segments:
            if not seg: continue

            # Logic: Pauses
            if seg.startswith("[pause:"):
                duration = float(seg.split(":")[1][:-1])
                final_audio.append(np.zeros(int(24000 * duration)))
                continue
            
            if seg == "...":
                final_audio.append(np.zeros(int(24000 * 0.8))) # Thalamus Long Pause
                continue

            # Logic: Style Markers
            if seg == "[soft]":
                current_volume = 0.5
                continue
            if seg == "[warm]":
                current_volume = 0.8 
                continue
            if seg == "[gentle]":
                current_speed = 0.8
                continue
            if seg.startswith("["): # Other tags we ignore for now
                continue

            # Actual Speech
            ids = self._get_ids(seg)
            if ids is not None:
                audio = self.session.run(None, {"input_ids": ids})[0]
                # Apply Logic: Volume
                audio = audio * current_volume
                final_audio.append(audio)
        
        return np.concatenate(final_audio) if final_audio else np.array([])

def run_test():
    print("🏎️ FERRARI CORTEX TEST BENCH (Logic Check)")
    print("=" * 50)
    
    cortex = FerrariCortex(ONNX_PATH)
    
    # This simulates a response Gemini would send to the Ferrari engine
    test_input = "[warm] Hello. [pause:0.5] I mean... [soft] I am so glad we are doing this. [pause:0.3] It feels... [gentle] real, doesn't it?"
    
    print(f"Rich Input: {test_input}")
    print("\nRunning Logic Processor...")
    
    combined_audio = cortex.process_logic(test_input)
    
    if len(combined_audio) > 0:
        sf.write(OUTPUT_WAV, combined_audio, 24000)
        print(f"\n✅ SUCCESS: Logic-Processed Audio saved to {OUTPUT_WAV}")
    else:
        print("❌ Error: No audio generated.")

if __name__ == "__main__":
    run_test()
