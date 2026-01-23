"""
Ferrari TTS - Deep Acoustic Surgery
===================================
Fixing 'hellowth' (Acoustic Tail) and 'keys juggle' (Concatenation Pop).
Using Cosine Windows and Internal Model Padding.
"""

import os
import re
import numpy as np
import onnxruntime as ort
from kokoro import KPipeline
import soundfile as sf
from pathlib import Path

# Paths
ONNX_PATH = Path("models/ferrari_kokoro.onnx")
OUTPUT_WAV = Path("ferrari_silk_test.wav")

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

class FerrariAcousticSilk:
    def __init__(self, model_path):
        self.session = ort.InferenceSession(str(model_path))
        self.pipeline = KPipeline(lang_code='a')

    def apply_silk_fade(self, audio, fade_type="out", duration_ms=20):
        """Applies a smooth Cosine fade to eliminate clicks (keys juggle)"""
        fade_samples = int(24000 * (duration_ms / 1000))
        if len(audio) < fade_samples: return audio
        
        fade_curve = 0.5 * (1 + np.cos(np.linspace(0, np.pi, fade_samples)))
        if fade_type == "in":
            audio[:fade_samples] *= (1 - fade_curve)
        else:
            audio[-fade_samples:] *= fade_curve
        return audio

    def _get_ids(self, text):
        clean_text = text.strip()
        # 🔧 HACK: Replace formal 'O' with smoother 'o' + 'ʊ' to fix 'hellowth'
        # We manually patch the string if the model returns the high-pitched 'O'
        generator = self.pipeline(clean_text, voice='af_heart', speed=1, split_pattern=None)
        for _, phonemes, _ in generator:
            # The 'hellowth' usually comes from 'O' (ID 31). We force-replace it.
            fixed_phonemes = phonemes.replace('O', 'oʊ')
            print(f"Original: {phonemes} -> Silk: {fixed_phonemes}")
            
            ids = [0]
            for char in fixed_phonemes:
                if char in VOCAB:
                    ids.append(VOCAB[char])
            # Add 200ms of internal model 'thinking' space to allow vocal cords to stop
            ids.extend([16] * 8 + [0]) 
            return np.array([ids], dtype=np.int64)

    def generate(self, rich_text):
        parts = re.split(r'(\[pause:.*?\]|\.\.\.)', rich_text)
        final_audio = []

        for part in parts:
            if not part: continue
            
            if part.startswith("[pause:"):
                duration = float(part.split(":")[1][:-1])
                final_audio.append(np.zeros(int(24000 * duration)))
                continue
            
            if part == "...":
                final_audio.append(np.zeros(int(24000 * 0.8)))
                continue

            # Extract style and text
            clean_part = re.sub(r'\[.*?\]', '', part).strip()
            if not clean_part: continue

            volume = 0.5 if "[soft]" in part else 0.8 if "[warm]" in part else 1.0
            
            ids = self._get_ids(clean_part)
            audio = self.session.run(None, {"input_ids": ids})[0].flatten()
            
            # Apply volume and S-Curve smoothing
            audio = audio * volume
            audio = self.apply_silk_fade(audio, "in", 5)
            audio = self.apply_silk_fade(audio, "out", 15)
            
            final_audio.append(audio)

        return np.concatenate(final_audio)

def run_silk_test():
    print("🏎️ FERRARI SILK 2.0 - DEEP ACOUSTIC SURGERY")
    print("=" * 50)
    silk = FerrariAcousticSilk(ONNX_PATH)
    
    test_input = "[warm] Hello. [pause:0.5] I mean... [soft] I am so glad we are doing this."
    print(f"Rich Input: {test_input}")
    
    audio = silk.generate(test_input)
    sf.write(OUTPUT_WAV, audio, 24000)
    print(f"\n✅ SILK SUCCESS: Audio saved to {OUTPUT_WAV}")
    print("Listen for the 'O' -> 'oʊ' transition. No more 'hellowth'.")

if __name__ == "__main__":
    run_silk_test()
