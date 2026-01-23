"""
Ferrari TTS - Quick Kokoro Test
================================
Generate a sample audio to verify Kokoro is working.
"""

import time
from pathlib import Path

# Output directory
OUTPUT_DIR = Path(__file__).parent.parent / "output"
OUTPUT_DIR.mkdir(exist_ok=True)

print("🏎️  FERRARI TTS - Kokoro Test")
print("=" * 50)

# Test sentence
TEST_SENTENCE = "Hello! I'm your personal assistant. How can I help you today?"

print(f"Sentence: {TEST_SENTENCE}")
print("Loading Kokoro model (first run downloads ~1GB)...")

start_load = time.perf_counter()

from kokoro import KPipeline

# Initialize with American English voice
pipeline = KPipeline(lang_code='a')  # 'a' = American English

load_time = time.perf_counter() - start_load
print(f"✅ Model loaded in {load_time:.2f} seconds")

# Generate audio
print("\nGenerating audio...")
start_gen = time.perf_counter()

# Generate returns a generator, we collect all audio chunks
generator = pipeline(TEST_SENTENCE, voice='af_heart')  # 'af_heart' is a female voice

# Collect audio
import soundfile as sf
all_audio = []
sample_rate = 24000

for i, (gs, ps, audio) in enumerate(generator):
    all_audio.append(audio)
    print(f"  Chunk {i+1}: {len(audio)/sample_rate:.2f}s of audio")

# Concatenate and save
import numpy as np
final_audio = np.concatenate(all_audio)
output_path = OUTPUT_DIR / "kokoro_test.wav"
sf.write(str(output_path), final_audio, sample_rate)

gen_time = time.perf_counter() - start_gen
audio_duration = len(final_audio) / sample_rate
rtf = gen_time / audio_duration

print(f"\n{'=' * 50}")
print(f"✅ SUCCESS!")
print(f"   Audio Duration: {audio_duration:.2f} seconds")
print(f"   Generation Time: {gen_time:.2f} seconds")
print(f"   RTF (Real-Time Factor): {rtf:.3f}")
print(f"   (RTF < 1 means faster than real-time)")
print(f"\n   Saved to: {output_path}")
print(f"\n🎧 Listen to the output file to verify quality!")
