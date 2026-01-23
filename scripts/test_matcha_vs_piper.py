"""
Ferrari TTS - Phase 1.1: Model Comparison
==========================================
This script tests both Matcha-TTS and Piper to compare:
1. Audio Quality (subjective listening)
2. Generation Speed (RTF - Real-Time Factor)
3. Model Size (memory footprint)

Run this script to generate sample audio from both engines.
"""

import time
import os
from pathlib import Path

# Output directory
OUTPUT_DIR = Path(__file__).parent.parent / "output"
OUTPUT_DIR.mkdir(exist_ok=True)

# Test sentences (English)
TEST_SENTENCES = [
    "Hello, I'm your personal assistant. How can I help you today?",
    "The quick brown fox jumps over the lazy dog.",
    "I understand how you feel. Let me think about that for a moment."
]

# =============================================================================
# PIPER TEST (VITS-based, ultra-fast)
# =============================================================================
def test_piper():
    """
    Test Piper TTS.
    Piper is a fast, local TTS based on VITS.
    Install: pip install piper-tts
    """
    print("\n" + "="*60)
    print("TESTING PIPER (VITS)")
    print("="*60)
    
    try:
        from piper import PiperVoice
        import wave
        
        # Download a voice model (we'll use 'en_US-lessac-medium')
        # First run will download the model automatically
        voice = PiperVoice.load("en_US-lessac-medium")
        
        for i, sentence in enumerate(TEST_SENTENCES):
            output_path = OUTPUT_DIR / f"piper_sample_{i+1}.wav"
            
            start_time = time.perf_counter()
            
            # Generate audio
            with wave.open(str(output_path), 'wb') as wav_file:
                voice.synthesize(sentence, wav_file)
            
            end_time = time.perf_counter()
            generation_time = end_time - start_time
            
            # Calculate RTF (Real-Time Factor)
            # RTF < 1 means faster than real-time
            audio_duration = os.path.getsize(output_path) / (22050 * 2)  # Approx
            rtf = generation_time / audio_duration if audio_duration > 0 else 0
            
            print(f"  Sample {i+1}: {generation_time:.3f}s (RTF: {rtf:.3f})")
            print(f"    → Saved to: {output_path}")
        
        print("\n✅ Piper test complete!")
        return True
        
    except ImportError:
        print("❌ Piper not installed. Run: pip install piper-tts")
        return False
    except Exception as e:
        print(f"❌ Piper error: {e}")
        return False


# =============================================================================
# MATCHA-TTS TEST (Flow Matching, high quality)
# =============================================================================
def test_matcha():
    """
    Test Matcha-TTS.
    Matcha is a high-quality TTS based on Flow Matching.
    Install: pip install matcha-tts
    """
    print("\n" + "="*60)
    print("TESTING MATCHA-TTS (Flow Matching)")
    print("="*60)
    
    try:
        import torch
        import soundfile as sf
        from matcha.cli import main as matcha_main
        
        # Note: Matcha-TTS may require specific setup
        # We'll use the command-line interface approach
        print("  Matcha-TTS requires manual setup.")
        print("  Clone from: https://github.com/shivammehta25/Matcha-TTS")
        print("  Then run their inference script.")
        
        return False
        
    except ImportError:
        print("❌ Matcha-TTS not installed.")
        print("   Clone: git clone https://github.com/shivammehta25/Matcha-TTS")
        print("   Then: pip install -e .")
        return False


# =============================================================================
# ALTERNATIVE: KOKORO (StyleTTS2-based, if available)
# =============================================================================
def test_kokoro():
    """
    Test Kokoro (StyleTTS2-based).
    High expressiveness but slower.
    """
    print("\n" + "="*60)
    print("TESTING KOKORO (StyleTTS2)")
    print("="*60)
    
    try:
        # Kokoro uses a specific package
        from kokoro import KokoroTTS
        
        tts = KokoroTTS()
        
        for i, sentence in enumerate(TEST_SENTENCES):
            output_path = OUTPUT_DIR / f"kokoro_sample_{i+1}.wav"
            
            start_time = time.perf_counter()
            audio = tts.generate(sentence)
            audio.save(str(output_path))
            end_time = time.perf_counter()
            
            print(f"  Sample {i+1}: {end_time - start_time:.3f}s")
            print(f"    → Saved to: {output_path}")
        
        print("\n✅ Kokoro test complete!")
        return True
        
    except ImportError:
        print("❌ Kokoro not installed.")
        print("   Check: https://github.com/hexgrad/kokoro")
        return False


# =============================================================================
# MAIN
# =============================================================================
if __name__ == "__main__":
    print("🏎️  FERRARI TTS - Model Comparison Test")
    print("="*60)
    print(f"Output directory: {OUTPUT_DIR}")
    
    # Test each engine
    results = {
        "Piper (VITS)": test_piper(),
        "Matcha-TTS": test_matcha(),
        "Kokoro (StyleTTS2)": test_kokoro()
    }
    
    # Summary
    print("\n" + "="*60)
    print("SUMMARY")
    print("="*60)
    for name, success in results.items():
        status = "✅ Working" if success else "❌ Not Available"
        print(f"  {name}: {status}")
    
    print("\n📋 Next Steps:")
    print("  1. Listen to the generated samples in the output folder")
    print("  2. Compare quality and speed")
    print("  3. Choose the base engine for distillation")
    print("  4. Run: python distill_voice.py")
