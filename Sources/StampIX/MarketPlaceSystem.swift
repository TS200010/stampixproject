//
//  MarketPlaceSystem.swift
//  stampixproject
//
//  Created by Anthony Stanners on 16/05/2026.
//

import Foundation
import SkipMarketplace

// MARK: - Platform Guards (Skip/Fuse model)

//#if SKIP
//let isAndroid = true
//#else
//let isAndroid = false
//#endif
//
//#if os(iOS)
//let isIOS = true
//#else
//let isIOS = false
//#endif

// MARK: - Core Abstraction Boundary

protocol MarketplaceProtocol {
    func fetchProductIDs() async throws -> Set<String>
}

// MARK: - Live Implementation (SkipMarketplace unified API)

struct LiveMarketplace: MarketplaceProtocol {

    func fetchProductIDs() async throws -> Set<String> {

        let entitlements = try await Marketplace.current.fetchEntitlements()

        let productIDs = entitlements.flatMap { $0.products }

        return Set(productIDs)
    }
}

// MARK: - Mock Implementation (deterministic system testing)

enum MockScenario {
    case free
    case plus
    case pro
    case broken
}

struct MockMarketplace: MarketplaceProtocol {

    let scenario: MockScenario

    func fetchProductIDs() async throws -> Set<String> {

        switch scenario {

        case .free:
            return []

        case .plus:
            return ["plus_yearly"]

        case .pro:
            return ["pro_yearly"]

        case .broken:
            return ["plus_yearly", "pro_yearly"]
        }
    }
}

// MARK: - Composition Root Resolver

enum MarketplaceMode {
    case live
    case mock(MockScenario)
}

func makeMarketplace() -> MarketplaceProtocol {

    #if SKIP
    if gLiveMarketplaceAndroid {
        return LiveMarketplace()
    }
    #else
    if gLiveMarketplaceiOS {
        return LiveMarketplace()
    }
    #endif

    // Default deterministic mode
    return MockMarketplace(scenario: .free)
}
