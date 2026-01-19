//
//  LegalDocumentView.swift
//  thelongevityapp
//
//  Reusable component for displaying legal documents with calm, premium styling
//

import SwiftUI

struct LegalDocumentView: View {
    let title: String
    let content: String
    let lastUpdated: String?
    var kvkkSection: String? = nil
    var onScrollToKVKK: (() -> Void)? = nil
    
    @Environment(\.dismiss) private var dismiss
    @State private var scrollOffset: CGFloat = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text(title)
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundColor(.white)
                            
                            if let lastUpdated = lastUpdated {
                                Text("Last updated: \(lastUpdated)")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                        .padding(.bottom, 8)
                        
                        // Main Content
                        MarkdownText(content: replaceEmailAddresses(in: content))
                        
                        // KVKK Section (if provided)
                        if let kvkkSection = kvkkSection {
                            VStack(alignment: .leading, spacing: 16) {
                                Divider()
                                    .background(Color.white.opacity(0.2))
                                    .padding(.vertical, 8)
                                
                                Text("KVKK Aydınlatma Metni (Türkçe)")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                MarkdownText(content: replaceEmailAddresses(in: kvkkSection))
                            }
                            .padding(.top, 8)
                            .id("kvkk-section")
                        }
                    }
                    .padding(24)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color(red: 0.2, green: 0.5, blue: 0.35))
                }
            }
            .preferredColorScheme(.dark)
        }
    }
    
    // Replace all email addresses in document content with support@thelongevityapp.ai
    private func replaceEmailAddresses(in text: String) -> String {
        // Email regex pattern: matches standard email addresses
        let emailPattern = #"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}"#
        let regex = try! NSRegularExpression(pattern: emailPattern, options: [])
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "support@thelongevityapp.ai")
    }
}

// MARK: - Markdown Text Renderer
struct MarkdownText: View {
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(parseMarkdown(content), id: \.id) { element in
                element.view
            }
        }
    }
    
    private func parseMarkdown(_ text: String) -> [MarkdownElement] {
        var elements: [MarkdownElement] = []
        let lines = text.components(separatedBy: .newlines)
        var currentParagraph: [String] = []
        var elementId = 0
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Check for headings
            if trimmed.hasPrefix("#### ") {
                if !currentParagraph.isEmpty {
                    elements.append(MarkdownElement(id: elementId, view: AnyView(paragraphView(from: currentParagraph))))
                    elementId += 1
                    currentParagraph = []
                }
                let headingText = String(trimmed.dropFirst(5))
                elements.append(MarkdownElement(id: elementId, view: AnyView(headingView(text: headingText, level: 4))))
                elementId += 1
            } else if trimmed.hasPrefix("### ") {
                if !currentParagraph.isEmpty {
                    elements.append(MarkdownElement(id: elementId, view: AnyView(paragraphView(from: currentParagraph))))
                    elementId += 1
                    currentParagraph = []
                }
                let headingText = String(trimmed.dropFirst(4))
                elements.append(MarkdownElement(id: elementId, view: AnyView(headingView(text: headingText, level: 3))))
                elementId += 1
            } else if trimmed.hasPrefix("## ") {
                if !currentParagraph.isEmpty {
                    elements.append(MarkdownElement(id: elementId, view: AnyView(paragraphView(from: currentParagraph))))
                    elementId += 1
                    currentParagraph = []
                }
                let headingText = String(trimmed.dropFirst(3))
                elements.append(MarkdownElement(id: elementId, view: AnyView(headingView(text: headingText, level: 2))))
                elementId += 1
            } else if trimmed.hasPrefix("# ") {
                if !currentParagraph.isEmpty {
                    elements.append(MarkdownElement(id: elementId, view: AnyView(paragraphView(from: currentParagraph))))
                    elementId += 1
                    currentParagraph = []
                }
                let headingText = String(trimmed.dropFirst(2))
                elements.append(MarkdownElement(id: elementId, view: AnyView(headingView(text: headingText, level: 1))))
                elementId += 1
            } else if trimmed.isEmpty {
                if !currentParagraph.isEmpty {
                    elements.append(MarkdownElement(id: elementId, view: AnyView(paragraphView(from: currentParagraph))))
                    elementId += 1
                    currentParagraph = []
                }
            } else {
                currentParagraph.append(trimmed)
            }
        }
        
        // Add remaining paragraph
        if !currentParagraph.isEmpty {
            elements.append(MarkdownElement(id: elementId, view: AnyView(paragraphView(from: currentParagraph))))
        }
        
        return elements
    }
    
    private func headingView(text: String, level: Int) -> some View {
        let fontSize: CGFloat
        let fontWeight: Font.Weight
        let padding: CGFloat
        
        switch level {
        case 1:
            fontSize = 28
            fontWeight = .bold
            padding = 8
        case 2:
            fontSize = 24
            fontWeight = .semibold
            padding = 6
        case 3:
            fontSize = 20
            fontWeight = .semibold
            padding = 4
        case 4:
            fontSize = 18
            fontWeight = .medium
            padding = 2
        default:
            fontSize = 16
            fontWeight = .medium
            padding = 0
        }
        
        // Headings should not have bold parsing - they're already styled
        return Text(text)
            .font(.system(size: fontSize, weight: fontWeight))
            .foregroundColor(.white)
            .padding(.top, padding)
            .padding(.bottom, padding / 2)
    }
    
    private func paragraphView(from lines: [String]) -> some View {
        // Join lines with spaces, but preserve intentional line breaks
        let joinedText = lines.filter { !$0.isEmpty }.joined(separator: " ")
        return Text(parseBold(joinedText))
            .font(.system(size: 15, weight: .regular))
            .foregroundColor(.white.opacity(0.85))
            .lineSpacing(6)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    private func parseBold(_ text: String) -> AttributedString {
        var result = text
        var boldRanges: [(start: Int, length: Int)] = []
        
        // Find all **text** patterns and record their positions
        var searchStart = result.startIndex
        var removedChars = 0
        
        while let boldStart = result.range(of: "**", range: searchStart..<result.endIndex) {
            let afterBoldStart = boldStart.upperBound
            if let boldEnd = result.range(of: "**", range: afterBoldStart..<result.endIndex) {
                let startPos = result.distance(from: result.startIndex, to: boldStart.lowerBound) - removedChars
                let length = result.distance(from: boldStart.upperBound, to: boldEnd.lowerBound)
                boldRanges.append((start: startPos, length: length))
                
                // Remove the ** markers
                result.removeSubrange(boldEnd)
                result.removeSubrange(boldStart)
                removedChars += 4
                searchStart = boldStart.lowerBound
            } else {
                break
            }
        }
        
        // Create attributed string
        var attributedString = AttributedString(result)
        
        // Apply bold styling
        for range in boldRanges.reversed() {
            if range.start >= 0 && range.start + range.length <= result.count {
                let startIndex = attributedString.index(attributedString.startIndex, offsetByCharacters: range.start)
                let endIndex = attributedString.index(startIndex, offsetByCharacters: range.length)
                
                if endIndex <= attributedString.endIndex {
                    let textRange = startIndex..<endIndex
                    attributedString[textRange].font = .system(size: 15, weight: .semibold)
                    attributedString[textRange].foregroundColor = .white
                }
            }
        }
        
        return attributedString
    }
}

struct MarkdownElement {
    let id: Int
    let view: AnyView
}

// MARK: - Loading State
struct LegalDocumentLoadingView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .tint(Color(red: 0.2, green: 0.5, blue: 0.35))
                
                Text("Loading document...")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }
}

// MARK: - Error State
struct LegalDocumentErrorView: View {
    let error: String
    let onRetry: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 48))
                    .foregroundColor(.white.opacity(0.6))
                
                Text("Unable to load document")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(error)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                Button {
                    onRetry()
                } label: {
                    Text("Try Again")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            Capsule()
                                .fill(Color(red: 0.2, green: 0.5, blue: 0.35))
                        )
                }
                .padding(.horizontal, 32)
                .padding(.top, 8)
            }
        }
    }
}

