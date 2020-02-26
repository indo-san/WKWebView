//
//  OriginalAdBlocker.swift
//  WKWebView
//
//  Created by 中田諒 on 2020/02/26.
//  Copyright © 2020 Tsubasa Hayashi. All rights reserved.
//

import Foundation
import WebKit

// MARK: - WKContentRuleListStore
struct OriginalAdBlocker {
    
    private static var blockImagesRule: WKContentRuleList?
    
    static func addBlockRules(to webView: WKWebView) {
        deleteBeforeRuleList()
        guard BlockRuleType.current != .none else { return }
        
        lookUpRuleListThisVersion(type: BlockRuleType.current) { (contentRuleList, _) in
            webView.configuration.userContentController.add(contentRuleList)
        }
    }
    
    static func updateBlockRulesThisVersion(to webView: WKWebView) {
        deleteBeforeRuleList()
        
        /// remove before rule list
        lookUpRuleListThisVersion(type: BlockRuleType.getBefore()) { (contentRuleList, _) in
            webView.configuration.userContentController.remove(contentRuleList)
        }
        
        guard BlockRuleType.current != .none else { return }
        /// add new rule list
        lookUpRuleListThisVersion(type: BlockRuleType.current) { (contentRuleList, _) in
            webView.configuration.userContentController.add(contentRuleList)
        }
    }
    
    private static func lookUpRuleListThisVersion(type: BlockRuleType, handler: @escaping (WKContentRuleList, Error?) -> Void) {
        WKContentRuleListStore.default().lookUpContentRuleList(forIdentifier: type.identifier) { (contentRuleList, error) in
            guard let list = contentRuleList else {
                compileRuleList(type: type, handler: handler)
                return
            }
            handler(list, error)
        }
    }
    
    private static func compileRuleList(type: BlockRuleType, handler: @escaping (WKContentRuleList, Error?) -> Void) {
        do {
            var scriptContent = ""
            let smoozBlockerListHosts = Bundle.main.path(forResource: "SmoozBlockerListHosts", ofType: "json")
            scriptContent = "["
            scriptContent += try String(contentsOfFile: smoozBlockerListHosts!, encoding: .utf8)
            scriptContent += "]"
            WKContentRuleListStore.default().compileContentRuleList(forIdentifier: type.identifier, encodedContentRuleList: scriptContent) { (contentRuleList, error) in
                if let err = error {
                    printRuleListError(err)
                }
                if let list = contentRuleList {
                    handler(list, error)
                }
            }
        } catch {
            print(#function, error)
        }
    }
    
    private static func printRuleListError(_ error: Error, text: String = "") {
        guard let wkerror = error as? WKError else {
            print("\(text) \(type(of: self)) \(#function): \(error)")
            return
        }
        switch wkerror.code {
        case WKError.contentRuleListStoreLookUpFailed:
            print("\(text) WKError.contentRuleListStoreLookUpFailed: \(wkerror)")
        case WKError.contentRuleListStoreCompileFailed:
            print("\(text) WKError.contentRuleListStoreCompileFailed: \(wkerror)")
        case WKError.contentRuleListStoreRemoveFailed:
            print("\(text) WKError.contentRuleListStoreRemoveFailed: \(wkerror)")
        case WKError.contentRuleListStoreVersionMismatch:
            print("\(text) WKError.contentRuleListStoreVersionMismatch: \(wkerror)")
        default:
            print("\(text) other WKError \(type(of: self)) \(#function):\(wkerror.code) \(wkerror)")
        }
    }
    
    private static func deleteBeforeRuleList() {
        let thisVersionIndentifers = [BlockRuleType.adBlock.identifier]
        WKContentRuleListStore.default().getAvailableContentRuleListIdentifiers { (availableRuleLists) in
            guard let list = availableRuleLists else {
                return
            }
            guard list.count > 2 else { return } // exist only now version (images, adBlock)
            _ = list.filter { !thisVersionIndentifers.contains($0) }
                .map { deleteRuleList(identifer: $0, errorHandler: nil) }
        }
    }
    
    private static func deleteRuleList(identifer: String, errorHandler: ((_ error: Error) -> Void)?) {
        WKContentRuleListStore.default().removeContentRuleList(forIdentifier: identifer) { (error) in
            if let err = error {
                print("error occurred during remove content rule list")
                errorHandler?(err)
            }
        }
    }
}

/// コンテンツブロックのタイプ定義
enum BlockRuleType: Int {
    case none                     /// ブロックなし
    case adBlock                  /// 広告ブロック
    
    fileprivate static let currentAppVersion: String = "1.0"
    
    static var current: BlockRuleType {
        if AdBlockSettingRepository.isOn {
            return .adBlock
        } else {
            return .none
        }
    }
    
    var identifier: String {
        switch self {
        case .none:
            return ""
        case .adBlock:
            return "ContentBlockingRules-AdBlock-\(BlockRuleType.currentAppVersion)"
        }
    }
        
    /// 状態が変化する前に適用されていたBlockRuleType を 保存, 取得
    /// 前の状態が分かれば、webView から ruleList を remove できる
    fileprivate static let beforeBlockRuleTypeForUserDefaultsKey = "beforeBlockRuleTypeForUserDefaultsKey"
    static func saveBefore(_ blockRuleType: BlockRuleType) {
        UserDefaults.standard.set(blockRuleType.rawValue, forKey: beforeBlockRuleTypeForUserDefaultsKey)
    }
    static func getBefore() -> BlockRuleType {
        guard let rawValue = UserDefaults.standard.value(forKey: beforeBlockRuleTypeForUserDefaultsKey) as? Int else {
            return BlockRuleType.none
        }
        return BlockRuleType(rawValue: rawValue) ?? BlockRuleType.none
    }
}

struct AdBlockSettingRepository {
    static let key = "ad_block_setting_key"
    static func toggle() {
        UserDefaults.standard.set(!isOn, forKey: key)
    }
    
    static var isOn: Bool {
        UserDefaults.standard.bool(forKey: key)
    }
}
