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

@available(iOS 11.0, macOS 10.13, *)
extension ABPWebViewBlocker {
    /// An existing blocklist record copy that matches the user's block list.
    enum UserBlockListMatch {
        case automaticUpdate
        case userHistory
        case userDownload
    }

    /// Matches an automatic download or user history item against the users block list type that is set.
    /// - returns: If there is a match, a copy of the block list, otherwise nil.
    static func matchUserBlockList(toListType: UserBlockListMatch) -> (User, Updater?) -> BlockList? {
        let asRemoteBL: (BlockListSourceable) -> RemoteBlockList? = { $0 as? RemoteBlockList }
        return { user, updtr in
            let automaticUpdateCopy: (BlockList) -> BlockList? = { blst in
                updtr?.getDownloads()?.filter { (dld: BlockList) in
                    #if ABPDEBUG
                    let debug = true
                    #else
                    let debug = false
                    #endif
                    return user.blockList?.isExpired(debug: debug) == true &&
                        dld.initiator == .automaticUpdate &&
                        dld.dateDownload != nil &&
                        dld.dateDownload?.compare(user.blockList?.dateDownload ?? .distantPast) == .orderedDescending &&
                        asRemoteBL(blst.source) == asRemoteBL(dld.source) &&
                        updtr?.acceptableAdsInUse() == asRemoteBL(dld.source)?.hasAcceptableAds()
                }.first
            }
            let userHistoryCopy: (BlockList) -> BlockList? = { blst in
                user.getHistory()?.filter { itm in
                    itm.dateDownload != nil &&
                        asRemoteBL(blst.source) == asRemoteBL(itm.source) &&
                        user.acceptableAdsInUse() == asRemoteBL(itm.source)?.hasAcceptableAds()
                }.first
            }
            let userDownloadCopy: (BlockList) -> BlockList? = { blst in
                user.getDownloads()?.filter { itm in
                    itm.dateDownload != nil &&
                        asRemoteBL(blst.source) == asRemoteBL(itm.source) &&
                        user.acceptableAdsInUse() == asRemoteBL(itm.source)?.hasAcceptableAds()
                }.first
            }
            guard let blst = user.getBlockList() else { return nil }
            switch toListType {
            case .automaticUpdate:
                return automaticUpdateCopy(blst)
            case .userHistory:
                return userHistoryCopy(blst)
            case .userDownload:
                return userDownloadCopy(blst)
            }
        }
    }
}
