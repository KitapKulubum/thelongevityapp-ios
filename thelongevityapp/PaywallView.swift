//
//  PaywallView.swift
//  thelongevityapp
//
//  Premium paywall screen - hard gate for subscription
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var storeManager = StoreManager.shared
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var languageManager = LanguageManager.shared
    
    @State private var selectedPlan: SubscriptionPlan = .monthly
    @State private var isPurchasing: Bool = false
    @State private var purchaseError: String?
    @State private var showError: Bool = false
    @State private var showLogoutAlert: Bool = false
    @State private var showTerms: Bool = false
    @State private var showPrivacy: Bool = false
    
    enum SubscriptionPlan: String, CaseIterable {
        case monthly = "membership_monthly"
        case yearly = "membership_yearly"
        
        var displayName: String {
            switch self {
            case .monthly: return "Monthly"
            case .yearly: return "Yearly"
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color.black,
                    Color(red: 0.05, green: 0.16, blue: 0.12)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    // Test Bypass Button (DEBUG only)
                    #if DEBUG
                    Button {
                        Task {
                            await activateTestBypass()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "wrench.and.screwdriver")
                            Text("Test Bypass")
                        }
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.1))
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                    }
                    .padding(.top, 20)
                    #endif
                    
                    // Header
                    VStack(spacing: 12) {
                        Text(languageManager.localized("Longevity Premium"))
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("Unlock biological age tracking and insights.")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .padding(.top, 20)
                    
                    // Benefits List
                    VStack(alignment: .leading, spacing: 16) {
                        paywallBenefitRow(text: "Biological age tracking")
                        paywallBenefitRow(text: "Weekly & monthly insights")
                        paywallBenefitRow(text: "AI-powered interpretations")
                    }
                    .padding(.horizontal, 32)
                    .padding(.vertical, 24)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 24)
                    
                    // Plan Options
                    VStack(spacing: 16) {
                        ForEach(SubscriptionPlan.allCases, id: \.self) { plan in
                            PaywallPlanCard(
                                plan: plan,
                                isSelected: selectedPlan == plan,
                                price: storeManager.getPrice(for: plan.rawValue),
                                isLoading: storeManager.isLoadingProducts
                            ) {
                                selectedPlan = plan
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Primary CTA Button
                    Button {
                        purchaseSelectedPlan()
                    } label: {
                        HStack {
                            if isPurchasing {
                                ProgressView()
                                    .tint(.black)
                                    .scaleEffect(0.8)
                            } else {
                                Text(languageManager.localized("Continue"))
                                    .font(.system(size: 17, weight: .semibold))
                            }
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            Capsule()
                                .fill(Color.primaryGreen)
                        )
                    }
                    .disabled(isPurchasing || storeManager.isLoadingProducts)
                    .padding(.horizontal, 24)
                    
                    // Secondary Actions
                    VStack(spacing: 16) {
                        // Restore Purchases
                        Button {
                            restorePurchases()
                        } label: {
                            Text(languageManager.localized("Restore purchases"))
                                .font(.system(size: 15, weight: .regular))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        // Logout
                        Button {
                            showLogoutAlert = true
                        } label: {
                            Text(languageManager.localized("Log out"))
                                .font(.system(size: 15, weight: .regular))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    .padding(.top, 8)
                    
                    // Footer
                    VStack(spacing: 8) {
                        Text("Subscriptions are managed securely through your Apple ID.")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.white.opacity(0.4))
                            .multilineTextAlignment(.center)
                        
                        HStack(spacing: 16) {
                            Button {
                                showTerms = true
                            } label: {
                                Text(languageManager.localized("Terms of Service"))
                                    .font(.system(size: 11, weight: .regular))
                                    .foregroundColor(.white.opacity(0.3))
                            }
                            
                            Text("·")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.3))
                            
                            Button {
                                showPrivacy = true
                            } label: {
                                Text(languageManager.localized("Privacy Policy"))
                                    .font(.system(size: 11, weight: .regular))
                                    .foregroundColor(.white.opacity(0.3))
                            }
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            storeManager.loadProducts()
        }
        .alert("Purchase Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(purchaseError ?? "Unable to complete purchase. Please try again later.")
        }
        .alert("Log out?", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Log out", role: .destructive) {
                Task {
                    do {
                        try authManager.signOut()
                    } catch {
                        print("[PaywallView] Failed to sign out: \(error)")
                    }
                }
            }
        } message: {
            Text("You will need to sign in again to access your account.")
        }
        .sheet(isPresented: $showTerms) {
            TermsOfServiceView()
        }
        .sheet(isPresented: $showPrivacy) {
            PrivacyPolicyView()
        }
    }
    
    private func paywallBenefitRow(text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.primaryGreen)
                .frame(width: 20)
            
            Text(text)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.white.opacity(0.8))
        }
    }
    
    private func purchaseSelectedPlan() {
        guard let product = storeManager.getProduct(for: selectedPlan.rawValue) else {
            purchaseError = "Product not available. Please try again later."
            showError = true
            return
        }
        
        isPurchasing = true
        purchaseError = nil
        
        Task {
            do {
                // Purchase via StoreKit
                let transaction = try await storeManager.purchase(product)
                
                // Verify subscription with backend
                if let receiptData = await getReceiptData(from: transaction) {
                    _ = try await APIClient.shared.verifySubscription(receiptData: receiptData)
                    
                    // Reload subscription status
                    await subscriptionManager.loadSubscriptionStatus()
                    
                    // Update AppState subscription status
                    await MainActor.run {
                        if subscriptionManager.subscriptionStatus == .active {
                            appState.subscriptionStatus = .active
                        }
                    }
                }
                
                // Complete transaction
                if let transaction = transaction {
                    await transaction.finish()
                }
                
                // Notify that subscription is now active
                await MainActor.run {
                    isPurchasing = false
                    NotificationCenter.default.post(name: NSNotification.Name("SubscriptionActivated"), object: nil)
                }
            } catch {
                await MainActor.run {
                    isPurchasing = false
                    purchaseError = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    #if DEBUG
    private func activateTestBypass() async {
        isPurchasing = true
        purchaseError = nil
        
        do {
            // Call backend test bypass API
            let response = try await APIClient.shared.testBypass()
            print("[PaywallView] Test bypass activated: \(response.message)")
            
            if let subscription = response.subscription {
                print("[PaywallView] Subscription status: \(subscription.status), plan: \(subscription.plan)")
                
                // Update subscription status
                await MainActor.run {
                    appState.subscriptionStatus = .active
                    subscriptionManager.subscriptionStatus = .active
                }
                
                // Reload subscription status to ensure it's updated
                await subscriptionManager.loadSubscriptionStatus()
                
                // Notify that subscription is now active (this will be handled by RootView)
                await MainActor.run {
                    // The RootView will check subscription status and hide paywall
                    NotificationCenter.default.post(name: NSNotification.Name("SubscriptionActivated"), object: nil)
                    isPurchasing = false
                }
            }
        } catch let apiError as APIError {
            print("[PaywallView] Test bypass failed: \(apiError)")
            
            await MainActor.run {
                isPurchasing = false
                
                purchaseError = ErrorMessageHelper.getContextualMessage(for: apiError, context: .subscription)
                showError = true
            }
        } catch {
            print("[PaywallView] Test bypass failed with unknown error: \(error)")
            await MainActor.run {
                isPurchasing = false
                purchaseError = ErrorMessageHelper.getContextualMessage(for: error, context: .subscription)
                showError = true
            }
        }
    }
    #endif
    
    private func restorePurchases() {
        Task {
            do {
                try await AppStore.sync()
                // Reload subscription status after restore
                await subscriptionManager.loadSubscriptionStatus()
                
                // Update AppState
                await MainActor.run {
                    if subscriptionManager.subscriptionStatus == .active {
                        appState.subscriptionStatus = .active
                    }
                }
            } catch {
                print("[PaywallView] Failed to restore purchases: \(error)")
            }
        }
    }
    
    @available(iOS 15.0, *)
    private func getReceiptData(from transaction: StoreKit.Transaction?) async -> String? {
        guard let transaction = transaction else {
            return nil
        }
        
        // For StoreKit 2, create transaction data structure for backend verification
        // The backend will verify the transaction with Apple's servers using the transaction ID
        let transactionData: [String: Any] = [
            "transactionId": String(transaction.id),
            "productId": transaction.productID,
            "purchaseDate": transaction.purchaseDate.timeIntervalSince1970,
            "originalPurchaseDate": transaction.originalPurchaseDate.timeIntervalSince1970,
            "expiresDate": transaction.expirationDate?.timeIntervalSince1970 ?? 0
        ]
        
        // Encode as JSON and base64
        guard let jsonData = try? JSONSerialization.data(withJSONObject: transactionData) else {
            print("[PaywallView] Failed to encode transaction data")
            return nil
        }
        
        return jsonData.base64EncodedString()
    }
}

// MARK: - Paywall Plan Card
struct PaywallPlanCard: View {
    let plan: PaywallView.SubscriptionPlan
    let isSelected: Bool
    let price: String?
    let isLoading: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Radio button
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.primaryGreen : Color.clear)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle()
                                .stroke(isSelected ? Color.primaryGreen : Color.white.opacity(0.3), lineWidth: 2)
                        )
                    
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.black)
                    }
                }
                
                // Plan info
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.displayName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                    
                    if isLoading && price == nil {
                        Text("Loading...")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.white.opacity(0.5))
                    } else if let price = price {
                        Text(price)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                Spacer()
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(isSelected ? 0.1 : 0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color.primaryGreen.opacity(0.5) : Color.white.opacity(0.1), lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Store Manager (for purchases)
@MainActor
class StoreManager: ObservableObject {
    static let shared = StoreManager()
    
    @Published var products: [Product] = []
    @Published var isLoadingProducts: Bool = false
    
    private let productIDs: Set<String> = [
        "membership_monthly",
        "membership_yearly"
    ]
    
    private init() {}
    
    func loadProducts() {
        guard products.isEmpty else { return }
        
        isLoadingProducts = true
        
        Task {
            do {
                let storeProducts = try await Product.products(for: productIDs)
                await MainActor.run {
                    self.products = storeProducts
                    self.isLoadingProducts = false
                }
            } catch {
                print("[StoreManager] Failed to load products: \(error)")
                await MainActor.run {
                    self.isLoadingProducts = false
                }
            }
        }
    }
    
    func getProduct(for productID: String) -> Product? {
        return products.first { $0.id == productID }
    }
    
    func getPrice(for productID: String) -> String? {
        guard let product = getProduct(for: productID) else {
            return nil
        }
        return product.displayPrice
    }
    
    func purchase(_ product: Product) async throws -> StoreKit.Transaction? {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            switch verification {
            case .verified(let transaction):
                return transaction
            case .unverified(_, let error):
                throw error
            }
        case .userCancelled:
            throw StoreError.userCancelled
        case .pending:
            throw StoreError.pending
        @unknown default:
            throw StoreError.unknown
        }
    }
}

enum StoreError: LocalizedError {
    case userCancelled
    case pending
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .userCancelled:
            return "Purchase was cancelled."
        case .pending:
            return "Purchase is pending approval."
        case .unknown:
            return "An unknown error occurred."
        }
    }
}

