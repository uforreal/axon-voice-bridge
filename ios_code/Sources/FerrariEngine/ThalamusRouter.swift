import Foundation

/**
 # ThalamusRouter.swift
 
 The 'Central Switchboard' of the Ferrari.
 It decides whether to use Local Manuals, Web Search, or System Tools (Clock/Calc).
 */
class ThalamusRouter {
    
    enum Tool {
        case localManual(topic: String)
        case webSearch(query: String)
        case systemClock(action: String)
        case calculator(equation: String)
        case conversation // Just talk normally
    }
    
    /**
     Analyzing the intent of the user.
     Gemma/Gemini performs this 'Thinking' step.
     */
    func routeIntent(text: String) -> Tool {
        let input = text.lowercased()
        
        // 1. Check for Clock/Time
        if input.contains("time") || input.contains("tokyo") || input.contains("timer") {
            return .systemClock(action: "get_time")
        }
        
        // 2. Check for Math (Calculator)
        if input.contains("+") || input.contains("*") || input.contains("divided") || input.contains("calculate") {
            return .calculator(equation: text)
        }
        
        // 3. Check for Specialist Manuals (SolidWorks, etc)
        if input.contains("solidworks") || input.contains("extrude") || input.contains("sketch") {
            return .localManual(topic: "SolidWorks")
        }
        
        // 4. Default to Web/Conversation
        if input.contains("who won") || input.contains("world cup") {
            return .webSearch(query: text)
        }
        
        return .conversation
    }
    
    /**
     The 'App Hands': Actually performing the iOS system tasks.
     */
    func executeSystemTool(tool: Tool, completion: @escaping (String) -> Void) {
        switch tool {
        case .systemClock(let action):
            // On iOS, this would call 'AppIntents' to read the system time
            let now = Date()
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            completion("It's currently \(formatter.string(from: now)).")
            
        case .calculator(let equation):
            // Use NSExpression to perform safe math on the CPU
            let cleanEquation = equation.replacingOccurrences(of: "calculate", with: "")
                                        .replacingOccurrences(of: "times", with: "*")
            let expression = NSExpression(format: cleanEquation)
            if let result = expression.expressionValue(with: nil, context: nil) as? NSNumber {
                completion("The answer is \(result).")
            } else {
                completion("I'm having trouble with that math.")
            }
            
        default:
            break
        }
    }
}
