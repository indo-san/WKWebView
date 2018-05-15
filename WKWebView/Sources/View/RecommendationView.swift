//
//  RecommendationView.swift
//  WKWebView
//
//  Created by 中田諒 on 2018/05/14.
//  Copyright © 2018年 Tsubasa Hayashi. All rights reserved.
//

import UIKit

class RecommendationView: UIView {
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.dataSource = self
            tableView.register(UINib(nibName: "RecommendationCell", bundle: nil), forCellReuseIdentifier: "RecommendationCell")
        }
    }
}

extension RecommendationView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RecommendationCell", for: indexPath)
        return cell
    }
}
