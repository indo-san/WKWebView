/*
 * This file is part of Adblock Plus <https://adblockplus.org/>,
 * Copyright (C) 2006-present eyeo GmbH
 *
 * Adblock Plus is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 as
 * published by the Free Software Foundation.
 *
 * Adblock Plus is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Adblock Plus.  If not, see <http://www.gnu.org/licenses/>.
 */

import Foundation

/// Constants that are global to the framework. Some are not relevant in all
/// contexts being only applicable to the legacy iOS app.
public
struct Constants {
    /// Default interval for expiration of a block list.
    public static let defaultFilterListExpiration: TimeInterval = 86400
    public static let rulesExtension = "json"
    /// Parameter to preserve newly downloaded files when they are not synced with user state.
    /// It is for testing and debugging.
    static let automaticUpdateKeepFactor: Double = 1
    /// Internal distribution label for eyeo.
    static let devbuildsName = "devbuilds"
    /// Used to perform checks for user block list updating.
    static let periodicUpdateDivisor: Double = 4320
    static let abpkitDir = "ABPKit.framework"
    static let abpkitResourcesDir = "Resources"
    static let blocklistArrayEnd = "]"
    static let blocklistArrayStart = "["
    static let blocklistEncoding = String.Encoding.ascii
    static let blocklistExpirationDebug: TimeInterval = defaultFilterListExpiration
    static let blocklistRuleSeparator = ","
    static let blocklistRulesMax = 50000
    static let configPlistName = "ABPKit-Configuration.plist"
    static let contentRuleStoreID = "wk-content-rule-list-store"
    static let downloadCounterMax = 4
    static let domainWrapLeader = "^[^:]+:(//)?([^/]+\\.)?"
    static let domainWrapTrailer = "[^\\.][/:]?"
    static let extensionSafariNameIOS = "AdblockPlusSafariExtension"
    static let extensionSafariNameMacOS = "HostCBExt-macOS"
    static let organization = "org.adblockplus"
    static let productNameIOS = "AdblockPlusSafari"
    static let productNameMacOS = "ABPKit.HostApp-macOS"
    static let queueDownloads = organization + ".OperationQueue.UserBlockListDownloader"
    static let queueRules = organization + ".OperationQueue.RulesProcessing"
    static let srcAcceptableAdsNotApplicable = "aa-na"
    static let srcBundled = "bundled"
    static let srcEasylist = "easylist"
    static let srcEasylistPlusExceptions = "easylistPlusExceptions"
    static let srcRemote = "remote"
    static let srcSep = "/"
    static let srcTestingBundled = "bundled-testing"
    static let srcTestingEasylist = "test-easylist"
    static let srcTestingEasylistPlusExceptions = "test-easylistPlusExceptions"
    static let srcUserWhiteListLocallyGenerated = "user-whitelist-locally-generated"
    static let updaterBlockListMax = 5
    static let userBlockListMax = 5
    static let userHistoryMax = 5
}

struct Platform {
    func active() throws -> ABPPlatform {
        #if os(iOS)
        return .ios
        #elseif os(macOS)
        return .macos
        #else
        throw ABPConfigurationError.badPlatform
        #endif
    }
}

struct Configured: ABPConfigurable {
    /// Get a configuration model struct based on a bundled plist where the first match is used.
    /// - parameters:
    ///   - name: The actual plist name.
    ///   - startWith: Classes to examine in order after the main bundle (optional).
    ///   - model: The model for decoding.
    /// - returns: A decoded plist.
    func byBundledPlist<U: Decodable>(name: String = Constants.configPlistName,
                                      startWith: [AnyClass] = [],
                                      for model: U.Type) throws -> U? {
        try bundleFor(name, bundlesFor: startWith + [Config.self])
            .map { try PropertyListDecoder().decode(model, from: Data(contentsOf: $0)) }
    }
}

/// ABPKit configuration class for accessing globally relevant functions.
public
class Config {
    let adblockPlusSafariActionExtension = "AdblockPlusSafariActionExtension"
    let backgroundSession = "BackgroundSession"

    init() {
        // Intentionally empty.
    }

    /// Legacy configuration: References the host app.
    /// - returns: App identifier prefix such as org.adblockplus.devbuilds or org.adblockplus.
    private
    func bundlePrefix() -> BundlePrefix? {
        if let comps = Bundle.main.bundleIdentifier?.components(separatedBy: ".") {
            var newComps = [String]()
            if comps.contains(Constants.devbuildsName) {
                newComps = Array(comps[0...2])
            } else {
                newComps = Array(comps[0...1])
            }
            return newComps.joined(separator: ".")
        }
        return nil
    }

    /// Bundle reference for resources including:
    /// * bundled blocklists
    func bundle() -> Bundle {
        Bundle(for: Config.self)
    }

    func appGroup() throws -> AppGroupName {
        guard let cfg = try Configured().byBundledPlist(for: ABPKitConfiguration.self)
        else { throw ABPConfigurationError.missingConfigPlist }
        switch try Platform().active() {
        case .ios:
            return cfg.appGroupIOS
        case .macos:
            return cfg.appGroupMacOS
        }
    }

    /// This suite name function exists to support the legacy app.
    func defaultsSuiteName() throws -> DefaultsSuiteName {
        try appGroup()
    }

    /// A copy of the content blocker identifier function found in the legacy ABP implementation.
    /// - returns: A content blocker ID such as
    ///            "org.adblockplus.devbuilds.AdblockPlusSafari.AdblockPlusSafariExtension" or nil
    func contentBlockerIdentifier(platform: ABPPlatform) -> ContentBlockerIdentifier? {
        guard let name = bundlePrefix() else { return nil }
        switch platform {
        case .ios:
            return "\(name).\(Constants.productNameIOS).\(Constants.extensionSafariNameIOS)"
        case .macos:
            return "\(name).\(Constants.productNameMacOS).\(Constants.extensionSafariNameMacOS)"
        }
    }

    func backgroundSessionConfigurationIdentifier() throws -> String {
        guard let prefix = bundlePrefix() else { throw ABPConfigurationError.invalidBundlePrefix }
        return "\(prefix).\(Constants.productNameIOS).\(backgroundSession)"
    }

    func containerURL() throws -> AppGroupContainerURL {
        if let url = try FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroup()) {
                return url
            }
        if try Platform().active() == .ios {
            return try Persistor.applicationSupportDirectory()
        }
        throw ABPConfigurationError.invalidContainerURL
    }

    func rulesStoreIdentifier() throws -> URL {
        do {
            return try containerURL().appendingPathComponent(Constants.contentRuleStoreID)
        } catch let err { throw err }
    }
}
