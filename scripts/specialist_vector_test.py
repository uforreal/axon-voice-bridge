"""
Ferrari TTS - Specialist Vector Explorer
========================================
This script demonstrates 'Local Vector Search'.
1. It takes a 'Specialist Basis' (e.g., SolidWorks Manual text).
2. It converts it into 'Machine-Friendly' Math (Embeddings).
3. It performs a 'Semantic Search' to find the answer.
"""

import numpy as np
from sentence_transformers import SentenceTransformer
import json

class FerrariSpecialist:
    def __init__(self):
        # This is a small 30MB model that turns text into 'Math Neighbors'
        # On iPhone, we use a CoreML version of this.
        print("🔧 Loading Vector Mapping Engine...")
        self.encoder = SentenceTransformer('all-MiniLM-L6-v2') 
        self.knowledge_base = []
        self.vectors = None

    def learn_manual(self, text_content):
        """Processes the manual into machine-friendly vectors"""
        print("📖 Reading Manual and Converting to Math...")
        # Split manual into 'Logical Principles'
        self.knowledge_base = text_content.split('\n')
        # This is the 'Machine Format'. It's just a matrix of numbers.
        self.vectors = self.encoder.encode(self.knowledge_base)
        print(f"✅ Specialist DNA Created. Matrix Shape: {self.vectors.shape}")

    def ask(self, user_query):
        """The 'Local Vector Search' logic"""
        print(f"\nSearching for: '{user_query}'...")
        # 1. Turn the query into math
        query_vector = self.encoder.encode([user_query])
        
        # 2. 'Mathematical Proximity' (Find the closest logic in the manual)
        # Instead of searching words, we calculate the 'Distance' between ideas
        scores = np.dot(self.vectors, query_vector.T).flatten()
        best_index = np.argmax(scores)
        
        return self.knowledge_base[best_index]

# --- THE TEST ---
manual_txt = """
To extrude a sketch in SolidWorks, you must first select a closed profile.
The shortcut for the Extrude boss command is the 'E' key on your keyboard.
If the extrusion fails, check for open contours or overlapping lines in your sketch.
Mate constraints are used to align parts in an assembly, ensuring zero-degree freedom.
"""

specialist = FerrariSpecialist()
specialist.learn_manual(manual_txt)

# Test the independence
answer = specialist.ask("What do I do if my extrusion doesn't work?")
print(f"🤖 Specialist Answer: {answer}")

answer2 = specialist.ask("How do I put parts together?")
print(f"🤖 Specialist Answer: {answer2}")

print("\n" + "=" * 50)
print("This logic is 100% OFFLINE. It doesn't need Gemini.")
print("The 'Answer' is then fed into our 'Solid' Vocal Engine.")
