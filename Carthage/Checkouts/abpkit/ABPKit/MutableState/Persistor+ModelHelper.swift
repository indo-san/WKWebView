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

// Helper operations for filter lists models in persistence storage:
// * save
// * load
// * clear
extension Persistor {
    func loadModels<T: Decodable>(type: T.Type,
                                  state: ABPMutableState.StateName) throws -> T {
        try decodeModelData(type: T.self, modelData: load(type: Data.self, key: state))
    }

    func decodeModelData<T: Decodable>(type: T.Type,
                                       modelData: Data) throws -> T {
        try PropertyListDecoder().decode(T.self, from: modelData)
    }

    func saveModel<T: Encodable>(_ model: T,
                                 state: ABPMutableState.StateName) throws {
        try save(type: Data.self, value: encodeModel(model), key: state)
    }

    func encodeModel<T: Encodable>(_ model: T) throws -> Data {
        try PropertyListEncoder().encode(model)
    }
}
