"""
Ferrari TTS - Phase 2: CoreML Conversion (Split Model V3)
=========================================================
Simplifying the graph even further to bypass Torch 2.10 exporter bugs.
"""

import torch
import numpy as np
from kokoro.model import KModel
from pathlib import Path
import coremltools as ct
import onnx
from onnxsim import simplify

MODELS_DIR = Path("models")
MODELS_DIR.mkdir(exist_ok=True)

CACHE_DIR = Path.home() / ".cache/huggingface/hub/models--hexgrad--Kokoro-82M/snapshots"
SNAPSHOT_DIR = next(CACHE_DIR.iterdir())
MODEL_PATH = SNAPSHOT_DIR / "kokoro-v1_0.pth"
CONFIG_PATH = SNAPSHOT_DIR / "config.json"
VOICE_PATH = SNAPSHOT_DIR / "voices/af_heart.pt"

model = KModel(config=str(CONFIG_PATH), model=str(MODEL_PATH))
model.eval()
voice_pack = torch.load(VOICE_PATH, map_location='cpu')

class FerrariEncoder(torch.nn.Module):
    def __init__(self, kmodel):
        super().__init__()
        self.kmodel = kmodel
        
    def forward(self, input_ids, speed, ref_s):
        # Inputs:
        # input_ids: (1, L)
        # speed: (1,)
        # ref_s: (1, 256)
        
        # We use fixed length for input_lengths to avoid SymInt
        # In CoreML, we can pass this as an input too
        input_len = input_ids.shape[1]
        input_lengths = torch.tensor([input_len], dtype=torch.long)
        text_mask = torch.zeros_like(input_ids, dtype=torch.bool)
        
        bert_dur = self.kmodel.bert(input_ids, attention_mask=(~text_mask).int())
        d_en = self.kmodel.bert_encoder(bert_dur).transpose(-1, -2)
        
        s = ref_s[:, 128:]
        d = self.kmodel.predictor.text_encoder(d_en, s, input_lengths, text_mask)
        
        x, _ = self.kmodel.predictor.lstm(d)
        duration = self.kmodel.predictor.duration_proj(x)
        duration = torch.sigmoid(duration).sum(axis=-1) / speed
        
        t_en = self.kmodel.text_encoder(input_ids, input_lengths, text_mask)
        return d, t_en, duration

encoder = FerrariEncoder(model)
dummy_ids = torch.tensor([[0, 50, 47, 54, 54, 57, 0]], dtype=torch.long)
dummy_speed = torch.tensor([1.0], dtype=torch.float32)
dummy_ref_s = voice_pack[50].unsqueeze(0)

print("Exporting Encoder...")
# Use the old export path explicitly if possible
# Or just fix the inputs
torch.onnx.export(
    encoder, (dummy_ids, dummy_speed, dummy_ref_s), str(MODELS_DIR / "encoder.onnx"),
    input_names=["input_ids", "speed", "ref_s"],
    output_names=["d", "t_en", "duration"],
    dynamic_axes={"input_ids": {1: "seq"}, "d": {2: "seq"}, "t_en": {1: "seq"}, "duration": {1: "seq"}},
    opset_version=15
)
print("SUCCESS: Encoder exported to ONNX.")
