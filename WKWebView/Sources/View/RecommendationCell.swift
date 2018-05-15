//
//  RecommendationCell.swift
//  WKWebView
//
//  Created by 中田諒 on 2018/05/15.
//  Copyright © 2018年 Tsubasa Hayashi. All rights reserved.
//

import UIKit

class RecommendationCell: UITableViewCell {

    @IBOutlet weak var siteImageView: UIImageView! {
        didSet {
            siteImageView.layer.cornerRadius = 4
        }
    }
}
