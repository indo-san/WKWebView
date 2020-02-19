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

extension RulesOperable {
    /// Get content blocking data.
    /// - parameter url: File URL of the data
    /// - returns: Data of the filter list
    /// - throws: ABPKitTestingError
    func contentBlockingData(url: URL) throws -> Data {
        try Data(contentsOf: url, options: .uncached)
    }

    /// Closure withName for debugging as found useful during testing.
    private
    func fromLocalStorage(_ name: String, withName: ((String) -> Void)? = nil) throws -> URL? {
        let url = try Config().containerURL()
            .appendingPathComponent(name.addingFileExtension(Constants.rulesExtension))
        if FileManager.default
            .fileExists(atPath: url.path) { return url }
        return nil
    }

    private
    func fromDownloadedBlockList(_ blockList: BlockList) throws -> URL? {
        switch blockList.source {
        case let src where src as? RemoteBlockList != nil:
            return try fromLocalStorage(blockList.name)
        default:
            return nil
        }
    }

    /// Match by filename.
    private
    func fromBundle(filename: String, bundle: Bundle) -> URL? {
        try? ContentBlockerUtility()
            .getBundledFilterListFileURL(filename: filename, bundle: bundle)
    }

    /// Used for handling bundled rules:
    /// - returns: URL for a sourceable with a given AA state from a bundle if the source consists of bundled rules.
    private
    func fromBundledSourceable(_ source: BlockListSourceable?,
                               withAA: Bool,
                               bundle: Bundle) -> URL? {
        switch source {
        case let src where src as? BundledBlockList != nil:
            switch withAA {
            case true:
                return fromBundle(filename: BundledBlockList.easylistPlusExceptions.rawValue, bundle: bundle)
            case false:
                return fromBundle(filename: BundledBlockList.easylist.rawValue, bundle: bundle)
            }
        case let src where src as? BundledTestingBlockList != nil:
            switch withAA {
            case true:
                return fromBundle(filename: BundledTestingBlockList.fakeExceptions.rawValue, bundle: bundle)
            case false:
                return fromBundle(filename: BundledTestingBlockList.testingEasylist.rawValue, bundle: bundle)
            }
        default:
            return nil
        }
    }

    /// The bundle here may need to be explicitly set when accessing rules from a bundle other than
    /// the Config's bundle.
    /// Example: rulesURL(bundle: Bundle(for: ...))
    /// - returns: URL for local content blocking rules, the JSON file.
    private
    func rulesURL(blockList: BlockList? = nil,
                  withAA: Bool = true,
                  bundle: Bundle? = Config().bundle()) throws -> URL? {
        guard let bndlToUse = bundle else { throw ABPConfigurationError.invalidBundle }
        if let url = fromBundledSourceable(blockList?.source, withAA: withAA, bundle: bndlToUse) { return url }
        if let blst = blockList, let url = try fromDownloadedBlockList(blst) { return url }
        return nil
    }
}

extension RulesOperable where Self: BlockListDownloadable {
    /// Get the URL for content blocking rules.
    func rulesURL(customBundle: Bundle? = nil) throws -> URL? {
        guard let blst = self.blockList else { return nil }
        switch customBundle {
        case .some(let bundle):
            return try self.rulesURL(blockList: blst, withAA: self.acceptableAdsInUse(), bundle: bundle)
        case .none:
            return try self.rulesURL(blockList: blst, withAA: self.acceptableAdsInUse())
        }
    }
}
