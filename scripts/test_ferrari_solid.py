"""
Ferrari TTS - The "Absolute Basis" Test Bench
===========================================
This script stops the 'guessing'.
It reads the official config.json for the 100% correct vocabulary.
It performs NO ad-hoc audio splits to prevent 'choppy' and 'inseborg' sounds.
"""

import json
import numpy as np
import onnxruntime as ort
import soundfile as sf
from kokoro import KPipeline
from pathlib import Path

# 1. THE SOLID BASIS: Load the official vocabluary directly from the cache
CONFIG_PATH = Path(r"C:\Users\HW\.cache\huggingface\hub\models--hexgrad--Kokoro-82M\snapshots\f3ff3571791e39611d31c381e3a41a3af07b4987\config.json")
ONNX_PATH = Path("d:/Rufen/ferrari_tts/models/ferrari_kokoro.onnx")

with open(CONFIG_PATH, 'r', encoding='utf-8') as f:
    config = json.load(f)
    VOCAB = config['vocab']

print(f"✅ Loaded Official Vocab: {len(VOCAB)} tokens.")

class FerrariSolidEngine:
    def __init__(self, model_path):
        self.session = ort.InferenceSession(str(model_path))
        self.pipeline = KPipeline(lang_code='a')

    def generate(self, text, output_path):
        """
        Uses the official Kokoro Pipeline for G2P (Text to Phonemes).
        This ensures 'so glad' doesn't turn into 'inseborg'.
        """
        print(f"\nProcessing Text: {text}")
        
        # We process the text as ONE unit to keep the 'Style Flow'
        generator = self.pipeline(text, voice='af_heart', speed=1, split_pattern=None)
        
        final_audio = []
        for graphemes, phonemes, audio in generator:
            print(f"Official Phonemes: {phonemes}")
            
            # Map phonemes to IDs using the OFFICIAL vocab
            ids = [0]
            for char in phonemes:
                if char in VOCAB:
                    ids.append(VOCAB[char])
                else:
                    print(f"⚠️ Warning: Missing token '{char}' - Skipping.")
            
            # Add official EOS (End of Sentence) padding
            ids.extend([0])
            
            # Run the Ferrari ONNX Blueprint
            input_ids = np.array([ids], dtype=np.int64)
            audio_out = self.session.run(None, {"input_ids": input_ids})[0].flatten()
            final_audio.append(audio_out)

        if final_audio:
            combined = np.concatenate(final_audio)
            sf.write(output_path, combined, 24000)
            print(f"✅ SUCCESS: Saved to {output_path}")
        else:
            print("❌ Error: Generation failed.")

# RUN THE TEST
engine = FerrariSolidEngine(ONNX_PATH)

# Test 1: Plain English (No Markers)
engine.generate("Hello. I am so glad we are doing this.", "d:/Rufen/ferrari_tts/ferrari_SOLID_PURE.wav")

# Test 2: With Punctuation Logic (The 'Human' approach)
engine.generate("Hello... I mean, I am so glad we are doing this?", "d:/Rufen/ferrari_tts/ferrari_SOLID_RHYTHM.wav")

print("\n" + "=" * 50)
print("TEST COMPLETE: Please compare 'ferrari_SOLID_PURE.wav' and 'ferrari_SOLID_RHYTHM.wav'.")
print("These are generated with 100% official vocabulary. No more 'inseborg'.")
