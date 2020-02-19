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

/// A Filter List is also known as a Block List within the context of content
/// blocking on iOS/macOS.
///
/// This struct is used for decoding all rules where the rules are unkeyed.
/// This is for verification and handling of v1 filter lists in JSON format.
struct V1FilterList: Decodable {
    var container: UnkeyedDecodingContainer!

    init(from decoder: Decoder) throws {
        container = try decoder.unkeyedContainer()
    }
}
