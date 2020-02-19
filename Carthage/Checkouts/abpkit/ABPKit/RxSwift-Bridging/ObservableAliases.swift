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
import WebKit

// Corresponds to ABPKit-Combine/Protocols/PublisherAliases.swift:

typealias CompoundRemovers = Observable<Observable<String>>
typealias SingleData = Observable<Data>
typealias SingleRawRulesOptional = Observable<String?>
@available(OSXApplicationExtension 10.13, *)
typealias SingleRuleList = Observable<WKContentRuleList>
typealias SingleRuleListID = Observable<String>
typealias SingleRuleListIDsOptional = Observable<[String]?>
@available(OSXApplicationExtension 10.13, *)
typealias SingleRuleListOptional = Observable<WKContentRuleList?>
typealias SingleRuleStringAndCount = Observable<(String, Int)>
typealias SingleRulesValidation = Single<RulesValidation>
typealias SingleUpdater = Observable<Updater>
typealias SingleUser = Observable<User>
typealias SingleVoid = Observable<Void>
typealias StreamDownloadEvent = Observable<DownloadEvent>
typealias StreamRule = Observable<BlockingRule>
typealias StreamRuleListID = Observable<String>
typealias ValueSubjectDownloadEvent = BehaviorSubject<DownloadEvent>
typealias ValueSubjectErrorOptional = BehaviorSubject<Error?>
