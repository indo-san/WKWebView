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

import RxSwift

/// Various rules handling operations.
class LegacyRulesHelper {
    var bag: DisposeBag!
    /// Override default bundle eg use test bundle, if set.
    var useBundle: Bundle?

    init() {
        bag = DisposeBag()
    }

    /// - parameter customBundle: Testing bundles can be passed in with this parameter.
    convenience
    init(customBundle: Bundle?) {
        self.init()
        useBundle = customBundle
    }

    /// Get rules based on a filename. Used to pre-load downloaded rules.
    func rulesForFilename() -> (String?) throws -> URL? {
        {
            guard let name = $0 else { return nil }
            let containerURL = try Config().containerURL()
            let fileURL = containerURL.appendingPathComponent(name)
            if FileManager.default.fileExists(atPath: fileURL.path) { return fileURL }
            return nil
        }
    }

    ///  The bundle may need to be explicitly set when accessing rules from a bundle other than the
    /// Config's bundle.
    /// Example: rulesURL(bundle: Bundle(for: ...))
    ///
    /// This function also handles BlockListSourceables during the transition to a
    /// final definition of FilterList. Usage of FilterList will likely be removed
    /// in future versions.
    ///
    /// Parameter identifier is not used for user block lists.
    /// - returns: URL for local content blocking rules, the JSON file.
    func rulesURL(identifier: String? = nil,
                  blockList: BlockList? = nil,
                  withAA: Bool = true,
                  bundle: Bundle = Config().bundle(),
                  ignoreBundle: Bool = false) throws -> URL? {
        let bndlToUse = useBundle ?? bundle
        if let url = fromBundledSourceable(blockList?.source, withAA: withAA, bundle: bndlToUse) { return url }
        if let blst = blockList, let url = try fromDownloadedBlockList(blst) { return url }
        // Search filter list models:
        let matched = try Persistor()
            .loadFilterListModels()
            .filter { $0.name == identifier }
        switch matched.count {
        case let cnt where cnt == 0 :
            throw ABPBlockListParameterizedError.notFoundForBL(blockList)
        case let cnt where cnt != 0 && cnt != 1:
            throw ABPFilterListError.ambiguousModels
        default:
            break
        }
        let fname = matched.first?.fileName
        let url = try? Config().containerURL()
        let pathURL = fname != nil ? url?.appendingPathComponent(fname!) : nil
        if pathURL != nil && FileManager.default.fileExists(atPath: pathURL!.path) {
            return pathURL
        }
        // Only if URL not found in the container and not a BlockListSourceable, look in the bundle:
        if !ignoreBundle, let idr = identifier {
           return fromBundle(name: idr, bundle: bndlToUse)
        }
        return nil
    }

    /// Used for handling bundled rules:
    /// - returns: URL for a sourceable with a given AA state from a bundle if the source consists of bundled rules.
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

    /// Subsequent encoding via Codable may not be time efficient wrt reduce operations. This may be
    /// due to unoptimized complexity within the ABPKit implementation and/or a consequence of using
    /// Codable, known to not offer as high performance as other methods.
    /// - returns: Observable of parsed CB rules.
    func decodedRulesFromURL() -> (URL?) throws -> StreamRule {
        {
            if $0 == nil { return .error(ABPFilterListError.badSource) }
            return try JSONDecoder().decode(V1FilterList.self, from: self.contentBlockingData(url: $0!)).rules()
        }
    }

    /// Blocking rules from a string.
    func decodedRulesFromString() -> (String?) -> StreamRule {
        {
            do {
                if $0 == nil { return .error(ABPBlockListError.badRulesRaw) }
                return try $0!.data(using: Constants.blocklistEncoding)
                    .map { try JSONDecoder().decode(V1FilterList.self, from: $0).rules() } ?? .empty()
            } catch let err { return .error(err) }
        }
    }

    /// - returns: Observable of raw JSON content blocking rules or an empty JSON array.
    func rawRulesString() -> (URL?) -> SingleRawRulesOptional {
        { [unowned self] in
            do {
                return try self.rawRulesData()($0)
                    .flatMap { data -> SingleRawRulesOptional in
                        .just(String(data: data, encoding: Constants.blocklistEncoding))
                    }
            } catch let err { return .error(err) }
        }
    }

    func rawRulesData() -> (URL?) throws -> SingleData {
        {
            if $0 == nil { return .error(ABPFilterListError.badSource) }
            if let data = FileManager.default.contents(atPath: ($0!.path)) {
                return .just(data)
            }
            return .error(ABPFilterListError.invalidData)
        }
    }

    func ruleToStringWithEncoder(_ encoder: JSONEncoder) -> (BlockingRule) throws -> String {
        {
            guard let data = try? encoder.encode($0), let rule = String(data: data, encoding: .utf8)
            else { throw ABPFilterListError.failedEncodeRule }
            return rule
        }
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

    /// Closure withName for debugging as found useful during testing.
    private
    func fromLocalStorage(_ name: String, withName: ((String) -> Void)? = nil) throws -> URL? {
        let url = try Config().containerURL()
            .appendingPathComponent(name.addingFileExtension(Constants.rulesExtension))
        if FileManager.default
            .fileExists(atPath: url.path) { return url }
        return nil
    }

    /// Match by filename.
    private
    func fromBundle(filename: String, bundle: Bundle) -> URL? {
        try? ContentBlockerUtility()
            .getBundledFilterListFileURL(filename: filename, bundle: bundle)
    }

    /// Match a FilterList model by name.
    private
    func fromBundle(name: String, bundle: Bundle) -> URL? {
        try? ContentBlockerUtility()
            .getBundledFilterListFileURL(modelName: name, bundle: bundle)
    }

    /// Get content blocking data.
    /// - parameter url: File URL of the data
    /// - returns: Data of the filter list
    /// - throws: ABPKitTestingError
    private
    func contentBlockingData(url: URL) throws -> Data {
        try Data(contentsOf: url, options: .uncached)
    }
}
