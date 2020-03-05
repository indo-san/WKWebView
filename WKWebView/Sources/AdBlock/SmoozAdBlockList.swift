//
//  SmoozAdBlockList.swift
//  WKWebView
//
//  Created by 中田諒 on 2020/03/05.
//  Copyright © 2020 Tsubasa Hayashi. All rights reserved.
//

import UIKit
import ABPKit

enum SmoozAdBlockList: String,
                              CaseIterable,
                              BlockListSourceable,
                              AcceptableAdsEnableable {
    public typealias RawValue = String
    case list = "SmoozBlockerListHosts.json"

    public
    func hasAcceptableAds() -> Bool {
        return false
    }
}
