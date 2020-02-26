//
//  AdBlockSetup.swift
//  WKWebView
//
//  Created by 中田諒 on 2020/02/19.
//  Copyright © 2020 Tsubasa Hayashi. All rights reserved.
//

import ABPKit

struct AdBlockSetup {
    
    static func saveFirstUser() {
        do {
            _ = try User(fromPersistentStorage: true)
        } catch {
            do {
                try User().save()
            } catch let error {
                print(error)
            }
        }
    }
    
    static func setAdBlock(host: ABPBlockable, withAcceptableAds: Bool = true) -> ABPWebViewBlocker? {
        
        do {
            let abp = try ABPWebViewBlocker(host: host)
            let user = getUser()
            abp.user = user
            let whitelistDomains: [String] = []
            try abp.user = abp.lastUser().whiteListedDomainsSet()(whitelistDomains).saved()
            setBlockList(user: user, withAcceptableAds: withAcceptableAds)
            abp.useContentBlocking(forceCompile: false) { (error) in
                if let error = error {
                    print(error)
                }
                print(abp.user.getWhiteListedDomains()!)
            }
            return abp
        } catch let error {
            print(error)
            return nil
        }
    }
    
    private static func getUser() -> User? {
        let user: User?
        do {
            if let savedUser = try User(fromPersistentStorage: true) {
                user = savedUser
            } else {
                user = try User()
            }
        } catch let error {
            print(error)
            do {
                user = try User()
            } catch let error {
                print(error)
                return nil
            }
        }
        
        return user
    }
    
    private static func setBlockList(user: User?, withAcceptableAds: Bool) {
        do {
            _ = try user?.blockListSet()(BlockList(
                withAcceptableAds: withAcceptableAds,
                source: RemoteBlockList.easylist,
                initiator: .userAction))
        } catch let error {
            print(error)
        }
    }
}
