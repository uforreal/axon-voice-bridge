import Foundation
import onnxruntime_objc

/**
 # FerrariEngine.swift (Solid Edition)
 
 This engine is optimized for the 'Solid Basis' we proved on PC.
 It uses Int64 IDs and runs on CPU (CoreML can be enabled manually if needed).
 */
class FerrariEngine {
    private var session: ORTSession?
    private let env: ORTEnv
    private let brainQueue = DispatchQueue(label: "com.ferrari.brain", qos: .userInitiated)
    
    init() throws {
        self.env = try ORTEnv(loggingLevel: .warning)
        try setupSession()
    }
    
    private func setupSession() throws {
        guard let modelPath = Bundle.main.path(forResource: "ferrari_kokoro", ofType: "onnx") else {
            throw NSError(domain: "Ferrari", code: 404, userInfo: [NSLocalizedDescriptionKey: "Engine blueprint missing!"])
        }
        
        let options = try ORTSessionOptions()
        // Use default execution providers (CPU) - CoreML can be added later with proper configuration
        
        self.session = try ORTSession(env: env, modelPath: modelPath, sessionOptions: options)
        print("🏎️ Ferrari Engine ignited.")
    }
    
    /**
     Synthesize text into audio using Int64 IDs.
     */
    func speak64(_ phonemeIds: [Int64], onBufferReady: @escaping ([Float]) -> Void) {
        brainQueue.async {
            guard let session = self.session else { return }
            
            do {
                // Prepare input_ids (Int64)
                let inputShape: [NSNumber] = [1, NSNumber(value: phonemeIds.count)]
                let inputData = NSMutableData(bytes: phonemeIds, length: phonemeIds.count * MemoryLayout<Int64>.size)
                let inputTensor = try ORTValue(tensorData: inputData, elementType: .int64, shape: inputShape)
                
                // Run Inference
                let outputs = try session.run(withInputs: ["input_ids": inputTensor],
                                             outputNames: ["audio"],
                                             runOptions: nil)
                
                guard let outputTensor = outputs["audio"] else { return }
                let audioData = try outputTensor.tensorData() as Data
                
                let floatArray = audioData.withUnsafeBytes {
                    Array(UnsafeBufferPointer(start: $0.baseAddress!.assumingMemoryBound(to: Float.self),
                                              count: audioData.count / MemoryLayout<Float>.size))
                }
                
                onBufferReady(floatArray)
                
            } catch {
                print("❌ Engine Stall: \(error)")
            }
        }
    }
}
