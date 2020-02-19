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
protocol HistoryEditable {
    func prunedHistory<U: BlockListable>(_ max: Int) -> ([U]) -> [U]
}

extension HistoryEditable {
    /// This assumes that members are added at the tail.
    public
    func prunedHistory<U: BlockListable>(_ max: Int) -> ([U]) -> [U] {
        { arr in
            guard arr.count > 0 else { return [] }
            var copy = arr
            if copy.count > max { copy.removeFirst(arr.count - max) }
            return copy
        }
    }
}
