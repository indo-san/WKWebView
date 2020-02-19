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

import Combine

/// No-op functions used as placeholders during adapting RxSwift to Combine.
class Bags
{
    class func bagCreate() -> (DisposeBagConsumer, AnyObject) -> Void {{ _, _ in }}
    class func bagDispose() -> (DisposeBagConsumer, AnyObject) -> Void {{ _, _ in }}
}
