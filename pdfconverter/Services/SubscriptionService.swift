import Foundation
import RevenueCat
import SwiftUI
import Combine

@MainActor
class SubscriptionService: NSObject, ObservableObject {
    static let shared = SubscriptionService()
    
    @Published var isPro = false
    @Published var currentOffering: Offering?
    
    override private init() {
        super.init()
    }
    
    func configure() {
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: "appl_NoYuJauIbQqoRTgWzsgYUIWsOOk")
        
        Purchases.shared.delegate = self
        
        checkEntitlement()
        fetchOfferings()
    }
    
    func checkEntitlement() {
        Purchases.shared.getCustomerInfo { [weak self] (info, error) in
            guard let self = self else { return }
            if let info = info {
                self.updateProStatus(with: info)
            }
        }
    }
    
    func fetchOfferings() {
        Purchases.shared.getOfferings { [weak self] (offerings, error) in
            guard let self = self else { return }
            if let offerings = offerings {
                self.currentOffering = offerings.current
            }
        }
    }
    
    func purchase(package: Package) async throws {
        let result = try await Purchases.shared.purchase(package: package)
        updateProStatus(with: result.customerInfo)
    }
    
    func restorePurchases() async throws {
        let info = try await Purchases.shared.restorePurchases()
        updateProStatus(with: info)
    }
    
    private func updateProStatus(with customerInfo: CustomerInfo) {
        withAnimation {
            self.isPro = customerInfo.entitlements["PDF Converter Pro"]?.isActive == true
        }
    }
}

extension SubscriptionService: PurchasesDelegate {
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        updateProStatus(with: customerInfo)
    }
}
