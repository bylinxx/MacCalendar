//
//  FocusableHostingController.swift
//  MacCalendar
//
//  Created by ruihelin on 2025/10/10.
//

import SwiftUI

class FocusableHostingController<Content: View>: NSHostingController<Content> {
    override func viewDidAppear() {
        super.viewDidAppear()
    }
    
    // 显式声明空的析构函数，防止 Xcode 在 Release 模式下触发 EarlyPerfInliner 内联优化器崩溃 Bug
    deinit {
            
    }
}
