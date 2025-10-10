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
        self.view.window?.makeKeyAndOrderFront(nil)
    }
    
    deinit{
        
    }
}
