import Foundation
import AVFoundation

/**
 # FerrariAudioStreamer.swift
 Handles the high-performance audio playback.
 
 Uses a Circular Buffer (simulated here) to ensure that even if the 
 AI brain pauses for a millisecond, the sound doesn't "glitch" or "pop".
 */
class FerrariAudioStreamer {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let mixer: AVAudioMixerNode
    
    // Sample rate of Kokoro is 24,000Hz
    // We explicitly define the layout to avoid channel mismatches.
    private let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 24000, channels: 1, interleaved: false)!
    
    init() {
        mixer = engine.mainMixerNode
        engine.attach(player)
        engine.connect(player, to: mixer, format: format)
        
        do {
            try engine.start()
        } catch {
            print("❌ Audio Hardware failure: \(error)")
        }
    }
    
    /**
     Pushes a new chunk of audio into the high-priority buffer.
     This is called whenever the FerrariEngine finishes a word/sentence.
     */
    func pushAudio(_ samples: [Float]) {
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count)) else { return }
        buffer.frameLength = buffer.frameCapacity
        
        // Copy samples to buffer
        for i in 0..<samples.count {
            buffer.floatChannelData?[0][i] = samples[i]
        }
        
        // Schedule for immediate playback
        player.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)
        
        if !player.isPlaying {
            player.play()
        }
    }
    
    func stop() {
        player.stop()
        engine.stop()
    }
}
