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

/// A container for RxSwift DisposeBags for the purpose of reducing code duplication between RxSwift
/// and Combine.
/// **Each static dispose bag instance must be explicity created and destroyed.**
class Bags
{
    private static var blockListDownloaderBags: [ObjectIdentifier: DisposeBag?] = [:]
    private static var blockListUpdaterBags: [ObjectIdentifier: DisposeBag?] = [:]
    private static var webViewBlockerBags: [ObjectIdentifier: DisposeBag?] = [:]
    /// This bag won't be created under normal usage. It serves as a fail-safe for the case of a missing bag.
    private static var backupBag: DisposeBag!

    init()
    {
        fatalError("Only static properties should be instantiated.")
    }

    class func bagCreate() -> (DisposeBagConsumer, AnyObject) -> Void
    {
        { cnsmr, obj in
            let idr = ObjectIdentifier(obj)
            switch cnsmr {
            case .blockListDownloader:
                Bags.blockListDownloaderBags[idr] = DisposeBag()
            case .blockListUpdater:
                Bags.blockListUpdaterBags[idr] = DisposeBag()
            case .webViewBlocker:
                Bags.webViewBlockerBags[idr] = DisposeBag()
            }
        }
    }

    /// A dispose bag for a given consumer and identifier.
    class func bag() -> (DisposeBagConsumer, AnyObject) -> DisposeBag
    {
        { cnsmr, obj in
            var dbg: DisposeBag!
            let idr = ObjectIdentifier(obj)
            switch cnsmr {
            case .blockListDownloader:
                dbg = Bags.blockListDownloaderBags[idr] as? DisposeBag
            case .blockListUpdater:
                dbg = Bags.blockListUpdaterBags[idr] as? DisposeBag
            case .webViewBlocker:
                dbg = Bags.webViewBlockerBags[idr] as? DisposeBag
            }
            dbg = dbg ?? Bags.useBackup()
            return dbg
        }
    }

    class func bagDispose() -> (DisposeBagConsumer, AnyObject) -> Void
    {
        { cnsmr, obj in
            let idr = ObjectIdentifier(obj)
            switch cnsmr {
            case .blockListDownloader:
                Bags.blockListDownloaderBags[idr] = nil
            case .blockListUpdater:
                Bags.blockListUpdaterBags[idr] = nil
            case .webViewBlocker:
                Bags.webViewBlockerBags[idr] = nil
            }
        }
    }

    /// Does not get used unless a bag is not available.
    /// This can occur from the following programmer errors where
    /// - a bag has not been created
    /// - a bag has been destroyed prematurely
    class func useBackup() -> DisposeBag
    {
        backupBag = DisposeBag()
        return backupBag
    }
}
