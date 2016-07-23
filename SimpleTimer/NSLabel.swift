//
//  NSLabel.swift
//  SimpleTimer
//
//  Created by appletomato on 07/07/16.
//  Copyright © 2016 SimpleTimer Foundation. All rights reserved.
//

import Cocoa

class NSLabel: NSTextField {
    
    // Default initializer
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        
        self.bezeled = false
        self.editable = false
        self.drawsBackground = false
        self.selectable = false
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented", file: "", line: 0)
    }
    
}
