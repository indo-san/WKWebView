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

/// A WebKit content blocking rule. Used for decoding individual rules.
public
struct BlockingRule: Codable {
    var action: Action?
    var trigger: Trigger?

    // Keys here are intended to be comprehensive for WebKit content-blocking rules.
    enum CodingKeys: String,
                     CodingKey {
        case action
        case trigger
    }
}

/// Intended to represent all available keys for trigger resource-type.
/// See [Introduction to WebKit Content Blockers](https://webkit.org/blog/3476/content-blockers-first-look/).
enum TriggerResourceType: String,
Codable {
    case document
    case image
    case styleSheet = "style-sheet"
    case script
    case font
    case raw // any untyped load, like XMLHttpRequest
    case svgDocument = "svg-document"
    case media
    case popup
}

/// Trigger loadType is correct as an array. The following error is reported if
/// set to a String:
///     Rule list compilation failed: Invalid trigger flags array.
struct Trigger: Codable {
    var ifTopURL: [String]?
    var loadType: [String]?
    var resourceType: [TriggerResourceType]?
    var unlessTopURL: [String]?
    var urlFilter: String?
    var urlFilterIsCaseSensitive: Bool?

    // Keys here are intended to be comprehensive for WebKit content-blocking triggers.
    enum CodingKeys: String,
                     CodingKey {
        case ifTopURL = "if-top-url"
        case loadType = "load-type"
        case resourceType = "resource-type"
        case unlessTopURL = "unless-top-url"
        case urlFilter = "url-filter"
        case urlFilterIsCaseSensitive = "url-filter-is-case-sensitive"
    }
}

struct Action: Codable {
    // Keys here are intended to be comprehensive for WebKit content-blocking actions.
    var selector: String?
    var type: String?
}
