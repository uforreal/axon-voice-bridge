import Foundation
import onnxruntime_objc

/**
 # FerrariEngine.swift (Solid Edition)
 
 This engine is optimized for the 'Solid Basis' we proved on PC.
 It uses Int64 IDs and is mapped to the Apple Neural Engine.
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
        // Force CoreML for power efficiency
        try options.appendCoreMLExecutionProvider(with: .all)
        try options.setSessionGraphOptimizationLevel(.all)
        
        self.session = try ORTSession(env: env, modelPath: modelPath, sessionOptions: options)
        print("🏎️ Ferrari Engine ignited on ANE.")
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
                let inputData = Data(bytes: phonemeIds, count: phonemeIds.count * MemoryLayout<Int64>.size)
                let inputTensor = try ORTValue(tensorData: inputData, elementType: .int64, shape: inputShape)
                
                // Run Inference (Speed already baked into the ONNX graph)
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
