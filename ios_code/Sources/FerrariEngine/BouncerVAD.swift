import Foundation
import AVFoundation
import onnxruntime_objc

/**
 # BouncerVAD.swift
 The battery saver.
 
 Monitors the microphone at a very low sample rate (16kHz). 
 It only triggers the heavy Ferrari Engine if it is 99% sure a human is speaking.
 */
class BouncerVAD {
    private var session: ORTSession?
    private let env: ORTEnv
    
    // Threshold for speech detection (adjustable)
    var sensitivity: Float = 0.5 
    
    init() throws {
        self.env = try ORTEnv(loggingLevel: .warning)
        
        guard let modelPath = Bundle.main.path(forResource: "silero_vad", ofType: "onnx") else {
            throw NSError(domain: "Bouncer", code: 404, userInfo: [NSLocalizedDescriptionKey: "VAD blueprint missing!"])
        }
        
        let options = try ORTSessionOptions()
        // VAD stays on the CPU/ANE because it's so small, doesn't need much power.
        try options.appendCoreMLExecutionProvider(with: .all)
        
        self.session = try ORTSession(env: env, modelPath: modelPath, sessionOptions: options)
    }
    
    /**
     Process a chunk of microphone audio.
     Returns true if human speech is detected.
     */
    func isHumanSpeaking(_ pcmData: [Float]) -> Bool {
        guard let session = self.session else { return false }
        
        do {
            let shape: [NSNumber] = [1, NSNumber(value: pcmData.count)]
            let data = Data(bytes: pcmData, count: pcmData.count * MemoryLayout<Float>.size)
            let tensor = try ORTValue(tensorData: data, elementType: .float32, shape: shape)
            
            let srTensor = try ORTValue(tensorData: Data([0, 0, 125, 70]), // 16000 as float32 bytes
                                      elementType: .float32, shape: [1])
            
            let outputs = try session.run(withInputs: ["input": tensor, "sr": srTensor],
                                         outputNames: ["output"],
                                         runOptions: nil)
            
            guard let outputValue = outputs["output"] else { return false }
            let outputData = try outputValue.tensorData() as Data
            let probability = outputData.withUnsafeBytes { $0.load(as: Float.self) }
            
            return probability > sensitivity
            
        } catch {
            print("Bouncer Error: \(error)")
            return false
        }
    }
}
