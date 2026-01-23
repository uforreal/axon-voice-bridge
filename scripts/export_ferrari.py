"""
Ferrari TTS - Phase 2: CoreML Conversion (Final Ferrari Path V4)
================================================================
Bypassing onnx-simplifier if it fails.
"""

import os
import torch
import numpy as np
from kokoro.model import KModel
from pathlib import Path
import coremltools as ct
import onnx

# Paths
MODELS_DIR = Path("models")
MODELS_DIR.mkdir(exist_ok=True)

CACHE_DIR = Path.home() / ".cache/huggingface/hub/models--hexgrad--Kokoro-82M/snapshots"
SNAPSHOT_DIR = list(CACHE_DIR.iterdir())[0]
MODEL_PATH = SNAPSHOT_DIR / "kokoro-v1_0.pth"
CONFIG_PATH = SNAPSHOT_DIR / "config.json"
VOICE_PATH = SNAPSHOT_DIR / "voices/af_heart.pt"

print(f"Loading Model...")
model = KModel(config=str(CONFIG_PATH), model=str(MODEL_PATH), disable_complex=True)
model.eval()

print(f"Loading Voice Pack...")
voice_pack = torch.load(VOICE_PATH, map_location='cpu')

class FerrariModel(torch.nn.Module):
    def __init__(self, kmodel, voice_pack):
        super().__init__()
        self.kmodel = kmodel
        self.register_buffer("ref_s", voice_pack[50])
        
    def forward(self, input_ids, speed=torch.tensor([1.0])):
        audio, _ = self.kmodel.forward_with_tokens(input_ids, self.ref_s, speed.item())
        return audio

ferrari = FerrariModel(model, voice_pack)
ferrari.eval()

dummy_ids = torch.tensor([[0, 50, 47, 54, 54, 57, 0]], dtype=torch.long)
dummy_speed = torch.tensor([1.0], dtype=torch.float32)

ONNX_PATH = MODELS_DIR / "ferrari_kokoro.onnx"
print("\nExporting to ONNX...")

if not ONNX_PATH.exists():
    with torch.no_grad():
        torch.onnx.export(
            ferrari,
            (dummy_ids, dummy_speed),
            str(ONNX_PATH),
            input_names=["input_ids", "speed"],
            output_names=["audio"],
            dynamic_axes={
                "input_ids": {1: "seq"},
                "audio": {0: "samples"}
            },
            opset_version=15,
            do_constant_folding=True
        )

if ONNX_PATH.exists():
    print(f"✅ ONNX exists at {ONNX_PATH}")
    
    # We skip simplification as it was causing topological sort errors
    
    print("\nConverting to CoreML (Native ONNX path)...")
    input_shape = ct.Shape(shape=(1, ct.RangeDim(3, 512)))
    
    try:
        ml_model = ct.convert(
            str(ONNX_PATH),
            inputs=[
                ct.TensorType(name="input_ids", shape=input_shape, dtype=np.int32),
                ct.TensorType(name="speed", shape=(1,), dtype=np.float32)
            ],
            outputs=[ct.TensorType(name="audio", dtype=np.float32)],
            minimum_deployment_target=ct.target.iOS16,
            compute_units=ct.ComputeUnit.ALL,
            convert_to="mlprogram"
        )
        
        ML_PKG = MODELS_DIR / "FerrariVoice.mlpackage"
        ml_model.save(str(ML_PKG))
        print(f"🚀 FERRARI ENGINE READY: {ML_PKG}")
    except Exception as e:
        print(f"❌ CoreML conversion failed: {e}")
        print("\nDON'T WORRY: The Ferrari can still run via ONNX Runtime on iOS.")
        print(f"Your high-quality voice blueprint is saved at: {ONNX_PATH}")
else:
    print("❌ Export failed.")
