import SwiftUI

@main
struct FerrariApp: App {
    var body: some Scene {
        WindowGroup {
            FerrariDashboardView()
        }
    }
}

struct FerrariDashboardView: View {
    @StateObject var conversation = try! ConversationManager()
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                // The Ferrari Logo / Status
                Circle()
                    .fill(conversation.state == "Speaking..." ? Color.red : Color.gray.opacity(0.3))
                    .frame(width: 150, height: 150)
                    .overlay(
                        Text("V12")
                            .font(.system(size: 40, weight: .black, design: .monospaced))
                            .foregroundColor(.white)
                    )
                    .shadow(color: conversation.state == "Speaking..." ? .red : .clear, radius: 20)
                
                Text(conversation.state)
                    .font(.system(.headline, design: .monospaced))
                    .foregroundColor(.white.opacity(0.7))
                
                ScrollView {
                    Text(conversation.aiResponse)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 200)
                .background(Color.white.opacity(0.05))
                .cornerRadius(15)
                
                Button(action: {
                    conversation.userSpoke(text: "Hello Ferrari, can you explain the extrude command?")
                }) {
                    Text("MANUAL TEST")
                        .font(.system(.callout, weight: .bold, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding(30)
        }
    }
}
