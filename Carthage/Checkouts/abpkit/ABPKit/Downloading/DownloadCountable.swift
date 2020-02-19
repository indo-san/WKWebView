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

/// Updates the global download counter.
public
protocol DownloadCountable {
    func incrementDownloadCount() throws
}

extension DownloadCountable {
    /// The counter is intended to be incremented for the life of an installation.
    /// Making a new counter based on the error for one not existing will be refactored in future
    /// versions.
    /// - parameter called: Prevents an infinite loop.
    private
    func incrementDownloadCount(_ called: Int = 0) throws {
        var copy: DownloadCounter!
        do {
            copy = try DownloadCounter(fromPersistentStorage: true)
        } catch let err {
            if (err as? ABPMutableStateError) == .invalidType {
                let ctr = try DownloadCounter()
                try ctr.save()
                if called == 0 {
                    try self.incrementDownloadCount(1)
                }
                return
            }
            throw err
        }
        copy.downloadCount += 1
        try copy.save()
    }

    /// Increment download counter.
    /// Make a new counter if one doesn't exist.
    public
    func incrementDownloadCount() throws {
        try self.incrementDownloadCount(0)
    }
}
