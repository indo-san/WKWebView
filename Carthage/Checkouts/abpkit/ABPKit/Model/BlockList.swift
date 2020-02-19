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

public
enum DownloadInitiator: String,
                        Codable {
    case automaticUpdate
    case repurposedExisting
    case userAction
}

/// Represents content blocking lists for WKWebView and Safari.
/// FilterList represents the legacy data model that is linked to this newer model.
/// FilterList will likely be reconfigured/renamed in the future.
/// Currently, this struct is not separately Persistable, because it is stored in User.
/// Saved rules are named after the BlockList's name.
public
struct BlockList: BlockListable {
    /// Identifier.
    public let name: String
    /// Only settable at creation.
    public let source: BlockListSourceable
    var dateDownload: Date?
    var initiator: DownloadInitiator

    enum CodingKeys: CodingKey {
        case name
        case source
        case dateDownload
        case initiator
    }

    public
    init(withAcceptableAds: Bool,
         source: BlockListSourceable,
         name: String? = nil,
         dateDownload: Date? = nil,
         initiator: DownloadInitiator) throws {
        if try AcceptableAdsHelper().aaExists()(source) != withAcceptableAds {
            throw ABPFilterListError.aaStateMismatch
        }
        self.name = name ?? UUID().uuidString
        self.source = source
        self.dateDownload = dateDownload
        self.initiator = initiator
    }

    public
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}

extension BlockList {
    /// Determine if a block list is expired or not.
    /// - parameter debug: If true, debug block list expiration value is used.
    /// - returns: True if considered expired.
    public
    func isExpired(debug: Bool = false) -> Bool {
        if dateDownload != nil {
            switch debug {
            case true:
                return dateDownload!
                    .addingTimeInterval(Constants.blocklistExpirationDebug)
                    .timeIntervalSinceReferenceDate
                < Date.timeIntervalSinceReferenceDate
            case false:
                return dateDownload!
                    .addingTimeInterval(Constants.defaultFilterListExpiration)
                    .timeIntervalSinceReferenceDate
                < Date.timeIntervalSinceReferenceDate
            }
        }
        return true
    }
}

extension BlockList {
    public
    init(from decoder: Decoder) throws {
        let vals = try decoder.container(keyedBy: CodingKeys.self)
        name = try vals.decode(String.self, forKey: .name)
        dateDownload = try vals.decode(Date?.self, forKey: .dateDownload)
        source = try SourceHelper()
            .sourceDecoded()(vals.decode(String.self, forKey: .source))
        initiator = try vals.decode(DownloadInitiator.self, forKey: .initiator)
    }

    public
    func encode(to encoder: Encoder) throws {
        var cntr = encoder.container(keyedBy: CodingKeys.self)
        try cntr.encode(name, forKey: .name)
        try cntr.encode(dateDownload, forKey: .dateDownload)
        try cntr.encode(SourceHelper().sourceEncoded()(source), forKey: .source)
        try cntr.encode(initiator, forKey: .initiator)
    }
}

extension BlockList {
    public static
    func == (lhs: BlockList, rhs: BlockList) -> Bool {
        lhs.name == rhs.name
    }
}
