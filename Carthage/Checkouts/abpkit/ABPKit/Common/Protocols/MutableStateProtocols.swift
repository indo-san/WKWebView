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

/// For models that can be stored.
public
protocol Persistable: Codable {
    var name: String { get }

    /// Init with default values.
    init() throws
    /// Init from persistent storage.
    init?(persistenceID: String) throws
    func save(file: String, line: Int, function: String) throws
    func saved(file: String, line: Int, function: String) throws -> Self
}

extension Persistable {
    func save(file: String = #file, line: Int = #line, function: String = #function) throws {
        try save(file: file, line: line, function: function)
    }

    func saved(file: String = #file, line: Int = #line, function: String = #function) throws -> Self {
        return try saved(file: file, line: line, function: function)
    }
}
