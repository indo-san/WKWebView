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
import WebKit

// Corresponds to ABPKit/RxSwift-Bridging/ObservableAliases.swift:

typealias CompoundRemovers = AnyPublisher<AnyPublisher<String, Error>, Error>
typealias SingleData = AnyPublisher<Data, Error>
typealias SingleRawRulesOptional = AnyPublisher<String?, Error>
typealias SingleRuleList = AnyPublisher<WKContentRuleList, Error>
typealias SingleRuleListID = AnyPublisher<String, Error>
typealias SingleRuleListIDsOptional = AnyPublisher<[String]?, Error>
typealias SingleRuleListOptional = AnyPublisher<WKContentRuleList?, Error>
typealias SingleRuleStringAndCount = AnyPublisher<(String, Int), Error>
typealias SingleRulesValidation = AnyPublisher<RulesValidation, Error>
typealias SingleUpdater = AnyPublisher<Updater, Error>
typealias SingleUser = AnyPublisher<User, Error>
typealias SingleVoid = AnyPublisher<Void, Error>
typealias StreamDownloadEvent = AnyPublisher<DownloadEvent, Error>
typealias StreamRule = AnyPublisher<BlockingRule, Error>
typealias StreamRuleListID = AnyPublisher<String, Error>
typealias ValueSubjectDownloadEvent = CurrentValueSubject<DownloadEvent, Error>
typealias ValueSubjectErrorOptional = CurrentValueSubject<Error?, Error>
