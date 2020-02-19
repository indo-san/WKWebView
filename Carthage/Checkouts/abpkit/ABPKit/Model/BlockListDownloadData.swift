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

/// Data sent during downloads of block lists.
struct BlockListDownloadData {
    let cfg: (String?, [AnyClass]?) -> Result<ABPKitConfiguration?, Error> = {
        var model: ABPKitConfiguration?
        do {
            model = try Configured().byBundledPlist(
                name: $0 ?? Constants.configPlistName,
                startWith: $1 ?? [Config.self],
                for: ABPKitConfiguration.self)
        } catch let err { return Result.failure(err) }
        return Result.success(model)
    }
    let addonNameDefault = "abpkit",
    addonVer = ABPActiveVersions.abpkitVersion() ?? "",
    applicationVer = ABPActiveVersions.osVersion(),
    platform = "webkit",
    platformVer = ABPActiveVersions.webkitVersion() ?? ""
    #if os(iOS)
    let application = ABPPlatform.ios.rawValue
    #elseif os(macOS)
    let application = ABPPlatform.macos.rawValue
    #else
    let application = "unknown"
    #endif
    public var queryItems: [URLQueryItem]!
    var overridePlistName: String?
    var startWith: [AnyClass]?

    /// Create download data for a given User state.
    /// The configuration file can be overridden for testing purposes.
    /// - parameters:
    ///   - consumer: Model state that uses the configuration.
    ///   - configPlistName: Name of the plist to use (optional).
    ///   - startWith: Array of classes to identify bundles to search (optional).
    init<S>(consumer: S, configPlistName: String? = nil, startWith: [AnyClass]? = nil) throws
    where S: BlockListDownloadable & Persistable {
        overridePlistName = configPlistName
        self.startWith = startWith
        queryItems = [
            URLQueryItem(name: "addonName", value: try partnerData(.addonName) ?? addonNameDefault),
            URLQueryItem(name: "addonVersion", value: addonVer),
            URLQueryItem(name: "application", value: try partnerData(.partnerApplication) ?? application),
            URLQueryItem(name: "applicationVersion", value: try partnerData(.partnerApplicationVersion) ?? applicationVer),
            URLQueryItem(name: "platform", value: platform),
            URLQueryItem(name: "platformVersion", value: platformVer),
            URLQueryItem(name: "lastVersion", value: lastVersion()(consumer)),
            URLQueryItem(name: "downloadCount", value: downloadCountString())
        ]
    }
}

extension BlockListDownloadData {
    enum PartnerDataField {
        case addonName
        case partnerApplication
        case partnerApplicationVersion
    }

    func partnerData(_ field: PartnerDataField) throws -> String? {
        let stringValue: (String) -> String? = {
            if $0.count > 0 { return $0 }; return nil
        }
        return try cfg(overridePlistName, startWith).get()
            .flatMap { cfg -> String? in
                switch (field, cfg) {
                case let pair where pair.0 == .addonName:
                    return stringValue(pair.1.addonName)
                case let pair where pair.0 == .partnerApplication:
                    return stringValue(pair.1.partnerApplication)
                case let pair where pair.0 == .partnerApplicationVersion:
                    return stringValue(pair.1.partnerApplicationVersion)
                case (_, _):
                    throw ABPConfigurationError.unexpectedData
                }
            }
    }
}

extension BlockListDownloadData {
    /// The initial value of the download counter is being handled in the catch for a not yet
    /// existing counter. This can be better encapsulated the DownloadCounter to go along with a
    /// refactor of the DownloadCounter creation mechanism.
    func downloadCountString() -> String {
        do {
            return try DownloadCounter(fromPersistentStorage: true)?.stringForHTTPRequest() ?? "0"
        } catch { return "0" }
    }

    func lastVersion<S>() -> (S) -> String where S: BlockListDownloadable & Persistable {
        { $0.lastVersion ?? "0" }
    }
}
