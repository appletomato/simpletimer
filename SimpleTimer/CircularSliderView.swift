//
//  CircularSliderView.swift
//  SimpleTimer
//
//  Created by appletomato on 06/07/16.
//  Copyright © 2016 SimpleTimer Foundation. All rights reserved.
//

import Cocoa

@IBDesignable class CircularSliderView: NSView {
    
    @IBInspectable var startColor:NSColor = NSColor.blueColor()
    @IBInspectable var endColor:NSColor = NSColor.redColor()
    
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        let slider:CircularSlider = CircularSlider(startColor:self.startColor, endColor:self.endColor, frame: self.bounds)
        
        self.addSubview(slider)
    }
}