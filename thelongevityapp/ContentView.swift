//
//  ContentView.swift
//  thelongevityapp
//
//  Created by Gizem Demir on 4.12.2025.
//

import SwiftUI

// Organic/Neural Network Pattern View
struct OrganicGlowPattern: View {
    var body: some View {
        ZStack {
            // Multiple layered circles for organic glow
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.15, green: 0.35, blue: 0.25).opacity(0.3),
                            Color(red: 0.1, green: 0.25, blue: 0.18).opacity(0.2),
                            Color.clear
                        ]),
                        center: .center,
                        startRadius: 30,
                        endRadius: 180
                    )
                )
                .frame(width: 360, height: 360)
                .blur(radius: 50)
            
            // Neural network-like organic pattern using multiple paths
            ZStack {
                // Central glow point
                Circle()
                    .fill(Color(red: 0.2, green: 0.5, blue: 0.35).opacity(0.4))
                    .frame(width: 60, height: 60)
                    .blur(radius: 30)
                
                // Organic branching paths
                OrganicPath()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.3, green: 0.6, blue: 0.45).opacity(0.6),
                                Color(red: 0.15, green: 0.4, blue: 0.3).opacity(0.3),
                                Color.clear
                            ]),
                            startPoint: .center,
                            endPoint: .leading
                        ),
                        lineWidth: 2
                    )
                    .blur(radius: 1)
                
                OrganicPath2()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.25, green: 0.55, blue: 0.4).opacity(0.5),
                                Color(red: 0.1, green: 0.35, blue: 0.25).opacity(0.2),
                                Color.clear
                            ]),
                            startPoint: .center,
                            endPoint: .trailing
                        ),
                        lineWidth: 2
                    )
                    .blur(radius: 1)
            }
            .frame(width: 300, height: 300)
            .blur(radius: 8)
        }
    }
}

// Custom organic path shape
struct OrganicPath: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        
        // Create organic branching pattern
        path.move(to: center)
        path.addCurve(
            to: CGPoint(x: center.x + 60, y: center.y - 40),
            control1: CGPoint(x: center.x + 20, y: center.y - 10),
            control2: CGPoint(x: center.x + 40, y: center.y - 30)
        )
        
        path.move(to: center)
        path.addCurve(
            to: CGPoint(x: center.x - 70, y: center.y - 30),
            control1: CGPoint(x: center.x - 25, y: center.y - 5),
            control2: CGPoint(x: center.x - 50, y: center.y - 20)
        )
        
        path.move(to: center)
        path.addCurve(
            to: CGPoint(x: center.x + 40, y: center.y + 70),
            control1: CGPoint(x: center.x + 15, y: center.y + 25),
            control2: CGPoint(x: center.x + 30, y: center.y + 50)
        )
        
        path.move(to: center)
        path.addCurve(
            to: CGPoint(x: center.x - 50, y: center.y + 60),
            control1: CGPoint(x: center.x - 20, y: center.y + 20),
            control2: CGPoint(x: center.x - 35, y: center.y + 40)
        )
        
        // Additional smaller branches
        path.move(to: CGPoint(x: center.x + 40, y: center.y - 20))
        path.addLine(to: CGPoint(x: center.x + 90, y: center.y - 60))
        
        path.move(to: CGPoint(x: center.x - 45, y: center.y - 15))
        path.addLine(to: CGPoint(x: center.x - 100, y: center.y - 45))
        
        return path
    }
}

// Second organic path for layered effect
struct OrganicPath2: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        
        // Create another set of organic branches
        path.move(to: center)
        path.addCurve(
            to: CGPoint(x: center.x + 50, y: center.y + 50),
            control1: CGPoint(x: center.x + 18, y: center.y + 15),
            control2: CGPoint(x: center.x + 35, y: center.y + 35)
        )
        
        path.move(to: center)
        path.addCurve(
            to: CGPoint(x: center.x - 60, y: center.y + 55),
            control1: CGPoint(x: center.x - 22, y: center.y + 18),
            control2: CGPoint(x: center.x - 42, y: center.y + 38)
        )
        
        path.move(to: center)
        path.addCurve(
            to: CGPoint(x: center.x + 55, y: center.y - 50),
            control1: CGPoint(x: center.x + 20, y: center.y - 15),
            control2: CGPoint(x: center.x + 38, y: center.y - 35)
        )
        
        path.move(to: center)
        path.addCurve(
            to: CGPoint(x: center.x - 45, y: center.y - 55),
            control1: CGPoint(x: center.x - 16, y: center.y - 18),
            control2: CGPoint(x: center.x - 32, y: center.y - 38)
        )
        
        return path
    }
}

// ContentView.swift
struct ContentView: View {
    @State private var userMessage: String = ""
    @State private var aiAnswer: String = "Ask Longevity AI something to get started."
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        ZStack {
            // Full screen dark gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    Color(red: 0.04, green: 0.12, blue: 0.08)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 40)
                    
                    // Centered glowing organic pattern behind main text
                    ZStack {
                        // Organic/Neural network glow pattern
                        OrganicGlowPattern()
                            .opacity(0.8)
                        
                        // Main title text
                        VStack(spacing: 12) {
                            Text("Longevity AI is ready.")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .shadow(color: Color(red: 0.2, green: 0.5, blue: 0.35).opacity(0.6), radius: 12, x: 0, y: 0)
                            
                            Text("Let's optimize your healthspan.")
                                .font(.system(size: 22, weight: .medium, design: .rounded))
                                .foregroundColor(Color(red: 0.75, green: 0.9, blue: 0.8))
                                .shadow(color: Color(red: 0.2, green: 0.5, blue: 0.35).opacity(0.5), radius: 10, x: 0, y: 0)
                        }
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 30)
                    
                    // Three pill-shaped buttons stacked vertically
                    VStack(spacing: 16) {
                        Button(action: {
                            // Action for Start Daily Check-In
                        }) {
                            Text("Start Daily Check-In")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    RoundedRectangle(cornerRadius: 28)
                                        .fill(Color.white.opacity(0.12))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 28)
                                                .stroke(Color.white.opacity(0.25), lineWidth: 1)
                                        )
                                )
                                .shadow(color: Color(red: 0.15, green: 0.4, blue: 0.3).opacity(0.4), radius: 12, x: 0, y: 6)
                        }
                        
                        Button(action: {
                            // Action for Analyze Habits
                        }) {
                            Text("Analyze Habits")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    RoundedRectangle(cornerRadius: 28)
                                        .fill(Color.white.opacity(0.12))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 28)
                                                .stroke(Color.white.opacity(0.25), lineWidth: 1)
                                        )
                                )
                                .shadow(color: Color(red: 0.15, green: 0.4, blue: 0.3).opacity(0.4), radius: 12, x: 0, y: 6)
                        }
                        
                        Button(action: {
                            // Action for Suggest Improvements
                        }) {
                            Text("Suggest Improvements")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    RoundedRectangle(cornerRadius: 28)
                                        .fill(Color.white.opacity(0.12))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 28)
                                                .stroke(Color.white.opacity(0.25), lineWidth: 1)
                                        )
                                )
                                .shadow(color: Color(red: 0.15, green: 0.4, blue: 0.3).opacity(0.4), radius: 12, x: 0, y: 6)
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 20)
                    .padding(.bottom, 30)
                    
                    // Longevity AI response container
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Longevity AI response")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.8))
                            .padding(.horizontal, 4)
                        
                        ZStack(alignment: .topLeading) {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white.opacity(0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                                )
                            
                            if isLoading {
                                HStack {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0.7, green: 0.9, blue: 0.8)))
                                    Text("Thinking...")
                                        .font(.system(size: 16, weight: .regular, design: .rounded))
                                        .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.8))
                                }
                                .padding(20)
                            } else {
                                ScrollView {
                                    Text(.init(processMarkdown(aiAnswer)))
                                        .font(.system(size: 16, weight: .regular, design: .rounded))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(20)
                                }
                                .frame(maxHeight: 200)
                            }
                        }
                        .frame(minHeight: 100)
                        
                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundColor(.red)
                                .padding(.horizontal, 4)
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 20)
                    
                    // Text input field with Send button at the bottom
                    HStack(spacing: 12) {
                        TextField("Why am I low on energy today?", text: $userMessage)
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 28)
                                    .fill(Color.white.opacity(0.08))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 28)
                                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                                    )
                            )
                        
                        Button(action: {
                            sendMessageToLongevityAI()
                        }) {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 52, height: 52)
                                .background(
                                    Circle()
                                        .fill(Color(red: 0.2, green: 0.5, blue: 0.35))
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                        )
                                )
                                .shadow(color: Color(red: 0.15, green: 0.4, blue: 0.3).opacity(0.4), radius: 8, x: 0, y: 4)
                        }
                        .disabled(isLoading || userMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .opacity(isLoading || userMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0)
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 50)
                }
            }
        }
    }
    
    func sendMessageToLongevityAI() {
        guard !userMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        // ... (existing code for sending message) ...
        let baseURL: URL = {
            #if DEBUG
            // Use 127.0.0.1 instead of localhost for iOS Simulator compatibility
            return URL(string: "http://127.0.0.1:4000")!
            #else
            return URL(string: "https://api.yourproductiondomain.com")!
            #endif
        }()
        let url = baseURL.appendingPathComponent("api").appendingPathComponent("chat")
        
        isLoading = true
        errorMessage = nil
        
        let body: [String: Any] = [
            "userId": "gizem-ios",
            "message": userMessage
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
            }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    self.errorMessage = "No data from server."
                }
                return
            }
            
            do {
                let decoded = try JSONDecoder().decode(ChatResponse.self, from: data)
                DispatchQueue.main.async {
                    self.aiAnswer = decoded.answer
                    self.userMessage = ""
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to decode response."
                }
            }
        }.resume()
    }
    
    private func processMarkdown(_ text: String) -> String {
        let lines = text.components(separatedBy: .newlines)
        let cleanedLines = lines.map { line -> String in
            var l = line.trimmingCharacters(in: .whitespaces)
            if l.hasPrefix("### ") {
                l = "**" + l.replacingOccurrences(of: "### ", with: "") + "**"
            } else if l.hasPrefix("## ") {
                l = "**" + l.replacingOccurrences(of: "## ", with: "") + "**"
            } else if l.hasPrefix("# ") {
                l = "**" + l.replacingOccurrences(of: "# ", with: "") + "**"
            }
            return l
        }
        return cleanedLines.joined(separator: "\n")
    }
}

#Preview {
    ContentView()
}
