"""
Ferrari TTS - Comparison Bench (Original vs. Integrated Logic)
============================================================
This script fixes the 'choppy' audio issues by integrating the 
original model's natural flow with our custom logic markers.
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

class FerrariIntegratedCortex:
    def __init__(self, model_path):
        self.session = ort.InferenceSession(str(model_path))
        self.pipeline = KPipeline(lang_code='a')

    def _get_ids(self, text):
        # We trim spaces to prevent the phonemizer from hallucinating 'breaths' or 'clicks'
        clean_text = text.strip()
        generator = self.pipeline(clean_text, voice='af_heart', speed=1, split_pattern=None)
        for _, phonemes, _ in generator:
            print(f"DEBUG Phonemes for '{clean_text}': {phonemes}")
            # We add FOUR [space] tokens (16) and a 0-token (EOS) 
            # This 'tricks' the model into generating actual silence at the end
            ids = [0]
            for char in phonemes:
                if char in VOCAB:
                    ids.append(VOCAB[char])
            ids.extend([16, 16, 16, 16, 0]) 
            id_array = np.array([ids], dtype=np.int64)
            print(f"DEBUG IDs with padding: {ids}")
            return id_array

    def generate_original(self, plain_text):
        ids = self._get_ids(plain_text)
        return self.session.run(None, {"input_ids": ids})[0]

    def generate_ferrari(self, rich_text):
        """
        Processes 'Meaning Blocks' instead of 'Words' 
        to keep the natural flow (Original Logic) while layering 
        our custom Logic.
        """
        # 1. Clean markers for the 'Flow' generation
        clean_text = re.sub(r'\[.*?\]', '', rich_text).replace('...', '...')
        
        # 2. Identify where our 'Hard' logic (pauses) should go
        # We split ONLY on hard duration markers [pause:X]
        parts = re.split(r'(\[pause:.*?\])', rich_text)
        
        final_audio = []
        current_volume = 1.0

        for part in parts:
            if not part: continue
            
            # Hard Logic: Pauses (Silent gaps)
            if part.startswith("[pause:"):
                duration = float(part.split(":")[1][:-1])
                # We add a tiny fade-out/in to prevent the 'choppy' click
                silence = np.zeros(int(24000 * duration))
                final_audio.append(silence)
                continue

            # Speech Logic (The Flow)
            # Track any soft/warm markers within this block
            if "[soft]" in part: current_volume = 0.5
            if "[warm]" in part: current_volume = 0.8
            
            clean_part = re.sub(r'\[.*?\]', '', part)
            if clean_part.strip():
                ids = self._get_ids(clean_part)
                audio = self.session.run(None, {"input_ids": ids})[0]
                
                # Apply V-JEPA Volume Smoothing
                audio = audio * current_volume
                
                # --- FERRARI ACOUSTIC SILK: FADE OUT ---
                # We apply a 10ms fade-out to the end of the segment 
                # to prevent the 'th' artifact (cutting the vocal vibration abruptly)
                fade_len = int(24000 * 0.010) # 10ms
                if len(audio) > fade_len:
                    fade_curve = np.linspace(1.0, 0.0, fade_len)
                    audio[-fade_len:] *= fade_curve
                
                final_audio.append(audio)

        return np.concatenate(final_audio)

def run_comparison():
    print("🏎️ FERRARI COMPARISON BENCH: ORIGINAL vs. INTEGRATED")
    print("=" * 60)
    
    cortex = FerrariIntegratedCortex(ONNX_PATH)
    
    raw_text = "Hello. I mean, I am so glad we are doing this. It feels real, doesn't it?"
    rich_text = "[warm] Hello. [pause:0.5] I mean... [soft] I am so glad we are doing this. [pause:0.3] It feels... real, doesn't it?"
    
    print("1. Generating Original (Dry) Audio...")
    orig_audio = cortex.generate_original(raw_text)
    sf.write("ferrari_comparison_ORIGINAL.wav", orig_audio, 24000)
    
    print("2. Generating Integrated Ferrari (Warmth + Logic) Audio...")
    ferrari_audio = cortex.generate_ferrari(rich_text)
    sf.write("ferrari_comparison_INTEGRATED.wav", ferrari_audio, 24000)
    
    print("\n" + "=" * 60)
    print("✅ COMPARISON COMPLETE")
    print("File 1: ferrari_comparison_ORIGINAL.wav (Pure Model Flow)")
    print("File 2: ferrari_comparison_INTEGRATED.wav (Model Flow + Custom Pause/Volume)")
    print("\nListen to the difference in the 'I mean...' transition.")

if __name__ == "__main__":
    run_comparison()
