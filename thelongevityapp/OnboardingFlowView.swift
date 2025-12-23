//
//  OnboardingFlowView.swift
//  thelongevityapp
//
//  Created on 17.12.2025.
//

import SwiftUI

struct OnboardingFlowView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel: ChatViewModel
    @State private var chatMessage: String = ""
    
    init() {
        // Create temporary appState for viewModel initialization
        // Will be updated in onAppear to use environment object
        let userId = AuthManager.shared.uid ?? ""
        let tempState = AppState(userId: userId)
        _viewModel = StateObject(wrappedValue: ChatViewModel(appState: tempState))
    }
    
    var body: some View {
        let isDailyMode = viewModel.mode == .daily
        let isEmptyDaily = viewModel.messages.isEmpty && viewModel.mode == .daily
        
        return VStack(spacing: 0) {
            // Daily check-in pinned card (only in daily mode - shouldn't show during onboarding)
            if isDailyMode {
                DailyCheckInPinnedCard(viewModel: viewModel, appState: appState)
            }
            
            // Messages area
            if isEmptyDaily {
                // Hero message for daily mode
                VStack {
                    Spacer()
                    VStack(spacing: 12) {
                        Text("Longevity AI is ready.")
                            .font(.system(size: 20, weight: .medium))
                        Text("Let's optimize your healthspan.")
                            .font(.system(size: 20, weight: .medium))
                    }
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                messagesScrollView
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            // Input bar (show in daily mode, but disabled when check-in is active)
            if viewModel.mode == .daily {
                InputBarView(
                    chatMessage: $chatMessage,
                    onSend: {
                        if !chatMessage.isEmpty && viewModel.chatInputEnabled {
                            viewModel.sendFreeTextMessage(chatMessage)
                            chatMessage = ""
                        }
                    }
                )
                .disabled(!viewModel.chatInputEnabled)
                .opacity(viewModel.chatInputEnabled ? 1.0 : 0.4)
            } else if viewModel.mode == .onboarding {
                // No input bar in onboarding mode
                EmptyView()
            }
        }
        .background(
            BackgroundView()
                .ignoresSafeArea()
        )
        .onAppear {
            // Update viewModel's appState reference to use environment object
            viewModel.appState = appState
            
            // Start onboarding if not completed
            if !appState.hasCompletedOnboarding && viewModel.messages.isEmpty {
                viewModel.startOnboarding()
            }
        }
        .onChange(of: appState.hasCompletedOnboarding) {
            if appState.hasCompletedOnboarding && viewModel.mode == .onboarding {
                // Switch to daily mode after onboarding
                viewModel.mode = .daily
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private var messagesScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(viewModel.messages) { message in
                        messageView(message: message)
                            .id(message.id)
                    }
                    
                    onboardingQuestionOptions
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                // Add extra bottom space when input is disabled to avoid overlap
                .padding(.bottom, viewModel.chatInputEnabled ? 0 : 80)
            }
                    .disabled(viewModel.isChatDisabled)
                    .onChange(of: viewModel.messages.count) {
                        if let last = viewModel.messages.last {
                            withAnimation {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
        }
    }
    
    private func messageView(message: ChatMessage) -> some View {
        VStack(spacing: 8) {
            ChatBubbleView(message: message)
            
            if shouldShowRetryButton(for: message) {
                retryButtonView
            }
        }
    }
    
    private func shouldShowRetryButton(for message: ChatMessage) -> Bool {
        guard !message.isUser,
              message.id == viewModel.messages.last?.id,
              case .failed(let errorMsg) = viewModel.submitState,
              message.text.contains(errorMsg) else {
            return false
        }
        return true
    }
    
    private var retryButtonView: some View {
        HStack(spacing: 12) {
            Button(action: {
                viewModel.retryLastSubmission()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12))
                    Text("Retry")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Color.green.opacity(0.2))
                        .overlay(
                            Capsule()
                                .stroke(Color.green.opacity(0.4), lineWidth: 1)
                        )
                )
            }
            
            if viewModel.mode == .onboarding && viewModel.currentOnboardingQuestionIndex > 0 {
                Button(action: {
                    viewModel.goBackToLastQuestion()
                }) {
                    Text("Edit answers")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                }
            }
        }
        .padding(.top, 4)
    }
    
    @ViewBuilder
    private var onboardingQuestionOptions: some View {
        if viewModel.mode == .onboarding,
           let question = viewModel.currentOnboardingQuestion,
           !viewModel.isSubmitting {
            VStack(spacing: 12) {
                ForEach(question.options) { option in
                    OptionButton(
                        title: option.title,
                        isSelected: false,
                        action: {
                            viewModel.selectOnboardingOption(option)
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
    }
    
}

