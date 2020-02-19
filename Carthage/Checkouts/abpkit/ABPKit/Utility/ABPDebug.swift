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

/// Global functions for development only.

/// Log messages useful for debugging. Output is made via NSLog only when ABPDEBUG is defined.
public
func log(_ message: String,
         filename: String = #file,
         line: Int = #line,
         function: String = #function) {
    #if ABPDEBUG
        let newMsg = "-[\((filename as NSString).lastPathComponent):\(line)] \(function) - \(message)"
        NSLog(newMsg)
    #endif
}

/// returns: True when tests are running.
public
func isTesting() -> Bool {
    ProcessInfo().environment["XCTestConfigurationFilePath"] != nil
}
