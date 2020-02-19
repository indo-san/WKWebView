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

import WebKit

@available(iOS 11.0, macOS 10.13, *)
public
protocol ABPBlockable: class
{
    var webView: WKWebView! { get }
}

@available(OSXApplicationExtension 10.13, *)
extension ABPWebViewBlocker
{
    public
    func loadURLString(_ urlString: String, completion: (URL?, Error?) -> Void)
    {
        if let url = URL(string: urlString.addingWebProtocol()) {
            DispatchQueue.main.async {
                self.host.webView.load(URLRequest(url: url))
            }
            completion(url, nil)
        } else { completion(nil, ABPWebViewBlockerError.badURL) }
    }
}
