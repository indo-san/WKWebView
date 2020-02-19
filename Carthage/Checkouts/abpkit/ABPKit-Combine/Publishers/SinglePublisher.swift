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

protocol GenericPublishable: Publisher
{
    associatedtype SomeType
}

/// Almost the same as Just but has an error slot.
struct SinglePublisher<U>: GenericPublishable
{
    typealias SomeType = U
    typealias Output = SomeType
    typealias Failure = Error

    let value: Output
    let error: Error? = nil

    init(_ value: Output)
    {
        self.value = value
    }

    func receive<S>(subscriber: S)
    where S: Subscriber, SinglePublisher.Failure == S.Failure, SinglePublisher.Output == S.Input
    {
        _ = subscriber.receive(value)
        subscriber.receive(completion: .finished)
    }
}
