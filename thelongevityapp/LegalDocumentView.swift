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
                        Text(content)
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.white.opacity(0.85))
                            .lineSpacing(6)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        // KVKK Section (if provided)
                        if let kvkkSection = kvkkSection {
                            VStack(alignment: .leading, spacing: 16) {
                                Divider()
                                    .background(Color.white.opacity(0.2))
                                    .padding(.vertical, 8)
                                
                                Text("KVKK Aydınlatma Metni (Türkçe)")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Text(kvkkSection)
                                    .font(.system(size: 15, weight: .regular))
                                    .foregroundColor(.white.opacity(0.85))
                                    .lineSpacing(6)
                                    .fixedSize(horizontal: false, vertical: true)
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
                    .foregroundColor(Color.primaryGreen)
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}

// MARK: - Loading State
struct LegalDocumentLoadingView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .tint(Color.primaryGreen)
                
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
                                .fill(Color.primaryGreen)
                        )
                }
                .padding(.horizontal, 32)
                .padding(.top, 8)
            }
        }
    }
}

