//
//  CircularSlider.swift
//  SimpleTimer
//
//  The idea to use a circular slider for
//  controlling the UI has been inspired by the
//  work of Yari D'areglia from
//  http://www.thinkandbuild.it/building-a-custom-and-designabl-control-in-swift/
//
//
//  Created by appletomato on 06/07/16.
//  Copyright © 2016 SimpleTimer Foundation. All rights reserved.
//

import Cocoa


struct Config {
    
    static let CS_TIME_FIELD_FONTSIZE:CGFloat = 20.0
    static let CS_ALARM_TIME_FIELD_FONTSIZE:CGFloat = 12.0
    static let CS_LINE_WIDTH:CGFloat = 5.0
    static let CS_SAFEAREA_PADDING:CGFloat = 8.0
    static let CS_SENSITIVITY_IN_DECASECONDS:Int = 6
}


class CircularSlider: NSControl {
    
    
    var timerField:NSLabel!
    var alarmTimeField:NSLabel!
    var myTimer: NSTimer?
    var angle:Int = 0
    var radius:CGFloat?
    var startColor = NSColor.blueColor()
    var endColor = NSColor.redColor()
    var secondsLeft:Int = 0
    var arcDirection:Int32 = 1
    var alarmIsDue:Bool = false
    var modusString:String = "stopWatchMode_paused"
    
    
    // ----------------------------------------------------------------------------------------------------
    // Layout
    
    
    convenience init(startColor:NSColor, endColor:NSColor, frame:CGRect){
        self.init(frame: frame)
        self.startColor = startColor
        self.endColor = endColor
    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        
        radius = self.frame.size.width/2 - Config.CS_SAFEAREA_PADDING
        
        
        /** timeField for displaying remaining time **/
        
        let timeFieldFont = NSFont.monospacedDigitSystemFontOfSize(Config.CS_TIME_FIELD_FONTSIZE, weight: NSFontWeightRegular)
        let timeStr = "HHH:MM" as NSString
        let timeFieldFontSize:CGSize = timeStr.sizeWithAttributes([NSFontAttributeName:timeFieldFont])
        
        
        let timeFieldRect = CGRectMake(
            (frame.size.width  - timeFieldFontSize.width) / 2.0,
            (frame.size.height - timeFieldFontSize.height) / 2.0,
            timeFieldFontSize.width, timeFieldFontSize.height);
        
        
        timerField = NSLabel(frame: timeFieldRect)
        
        timerField?.editable = true
        timerField?.target = self
        timerField?.action = #selector(enterTimerField)
        timerField?.textColor = NSColor.blackColor()
        timerField?.alignment = .Center
        timerField?.font = timeFieldFont
        timerField?.stringValue = "0:00"
        timerField?.focusRingType = NSFocusRingType.None
        
        addSubview(timerField!)
        
        
        /** alarmTimeField for displaying alarm time **/
        
        let alarmTimeFieldFont = NSFont.monospacedDigitSystemFontOfSize(Config.CS_ALARM_TIME_FIELD_FONTSIZE, weight: NSFontWeightRegular)
        let alarmStr = "HH:MM:SS" as NSString
        let alarmTimeFieldFontSize:CGSize = alarmStr.sizeWithAttributes([NSFontAttributeName:alarmTimeFieldFont])
        
        
        let alarmTimeFieldRect = CGRectMake(
            (frame.size.width  - alarmTimeFieldFontSize.width) / 2.0,
            (frame.size.height - alarmTimeFieldFontSize.height) / 2.0 - timeFieldFontSize.height,
            alarmTimeFieldFontSize.width, 1.25 * alarmTimeFieldFontSize.height);
        
        
        alarmTimeField = NSLabel(frame:alarmTimeFieldRect)
        
        alarmTimeField?.textColor = NSColor.darkGrayColor()
        alarmTimeField?.alignment = .Center
        alarmTimeField?.font = alarmTimeFieldFont
        alarmTimeField?.stringValue = "--:--"
        
        addSubview(alarmTimeField!)
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented", file: "", line: 0)
    }
    
    
    /** Use the draw rect to draw the Background, the Circle and the Handle **/
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        
        
        let ctx = NSGraphicsContext.currentContext()!.CGContext
        
        
        // Draw the background
        CGContextAddArc(ctx, CGFloat(self.frame.size.width / 2.0), CGFloat(self.frame.size.height / 2.0), radius!, 0, CGFloat(M_PI * 2), arcDirection)
        
        
        // Set fill/stroke color
        if (alarmIsDue) {
            NSColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0).set()
        } else {
            NSColor.clearColor().set()
        }
        
        
        // Set line info
        CGContextSetLineWidth(ctx, frame.size.width)
        CGContextSetLineCap(ctx, CGLineCap.Butt)
        CGContextDrawPath(ctx, CGPathDrawingMode.FillStroke)
        
        
        // Create THE MASK Image
        let anImage = NSImage(size: CGSizeMake(self.bounds.size.width, self.bounds.size.height))
        anImage.lockFocus()
        let imageCtx = NSGraphicsContext.currentContext()!.CGContext
        
        
        if (angle >= 0) {
            // draw clockwise
            arcDirection = 1
        } else {
            // draw counter-clockwise
            arcDirection = 0
        }
        
        
        CGContextAddArc(imageCtx, CGFloat(self.frame.size.width/2)  , CGFloat(self.frame.size.height/2), radius!, CGFloat(M_PI/2.0), CGFloat(-1.0*DegreesToRadians(Double(angle))+M_PI/2.0), arcDirection);
        NSColor.redColor().set()
        
        
        // Use shadow to create the Blur effect
        CGContextSetShadowWithColor(imageCtx, CGSizeMake(0, 0), CGFloat(self.angle/15), NSColor.blackColor().CGColor);
        
        
        // Define the path
        CGContextSetLineWidth(imageCtx, Config.CS_LINE_WIDTH)
        CGContextDrawPath(imageCtx, CGPathDrawingMode.Stroke)
        
        
        // Save the context content into the image mask
        let mask:CGImageRef = CGBitmapContextCreateImage(NSGraphicsContext.currentContext()!.CGContext)!
        anImage.unlockFocus()
        
        
        // Clip Context to the mask
        CGContextSaveGState(ctx)
        CGContextClipToMask(ctx, self.bounds, mask)
        
        
        // Split colors in components (rgba)
        let startColorComps:UnsafePointer<CGFloat> = CGColorGetComponents(startColor.CGColor);
        let endColorComps:UnsafePointer<CGFloat> = CGColorGetComponents(endColor.CGColor);
        
        let components : [CGFloat] = [
            startColorComps[0], startColorComps[1], startColorComps[2], 1.0,     // Start color
            endColorComps[0], endColorComps[1], endColorComps[2], 1.0      // End color
        ]
        
        
        // Setup the gradient
        let baseSpace = CGColorSpaceCreateDeviceRGB()
        let gradient = CGGradientCreateWithColorComponents(baseSpace, components, nil, 2)
        
        
        // Gradient direction
        let startPoint = CGPointMake(CGRectGetMinX(rect), CGRectGetMidY(rect))
        let endPoint = CGPointMake(CGRectGetMaxX(rect), CGRectGetMidY(rect))
        
        
        // Draw the gradient
        CGContextDrawLinearGradient(ctx, gradient!, startPoint, endPoint, []);
        CGContextRestoreGState(ctx);
        
        
        // Draw the handle
        CGContextSaveGState(ctx);
        
        
        // Shadow
        CGContextSetShadowWithColor(ctx, CGSizeMake(0, 0), 3, NSColor.blackColor().CGColor);
        
        
        // Get the handle position
        let handleCenter = pointFromAngle(angle-90)
        
        
        // Draw
        NSColor.whiteColor().set();
        CGContextFillEllipseInRect(ctx, CGRectMake(handleCenter.x, handleCenter.y, Config.CS_LINE_WIDTH, Config.CS_LINE_WIDTH));
        CGContextRestoreGState(ctx);
    }
    
    
    
    // ----------------------------------------------------------------------------------------------------
    // Program behaviour
    //
    // The program can may be in four different modes:
    //
    //     1. Paused in stopWatchMode
    //
    //     2. Paused in countDownMode
    //
    //     3. Busy in stopWatchMode
    //
    //     4. Busy in countDown Mode
    //
    // At the beginning, the program shall be in mode 1, i.e.,
    // starting the clock without setting an alarm time will lead to an increment
    // of the seconds shown in the timerField.
    
    
    
    func moveHandle(lastPoint:CGPoint){
        
        
        // Handle cannot be moved if timer is busy
        if (modusString == "stopWatchMode") || (modusString == "countDownMode") {
            return
        }
        
        
        // Get the winding number
        let w:Int = angle / 360
        
        
        let centerPoint:CGPoint  = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
        let currentAngle:Double = AngleFromNorth(centerPoint, p2: lastPoint, flipped: false);
        let angleInt = 360 - (Int(floor(currentAngle)) / Config.CS_SENSITIVITY_IN_DECASECONDS) * Config.CS_SENSITIVITY_IN_DECASECONDS
        
        
        // Store the new angle
        if (angle % 360 > 270) && (angleInt < 90) {
            angle = angleInt + (w+1)*360
        } else if (angle % 360 < 90) && (angleInt > 270) {
            angle = angleInt + (w-1)*360
        } else {
            angle = angleInt + w*360
        }
        
        
        if angle <= 0 {
            angle = 0
        }
        
        
        // 1 degree => 10 seconds
        secondsLeft = angle * 10
        
        
        // Change modus if handle has been moved
        if secondsLeft == 0 {
            modusString = "stopWatchMode_paused"
        } else {
            modusString = "countDownMode_paused"
        }
        
        
        updateTimerField()
        updateAlarmTimeField()
        setNeedsDisplay()
    }
    
    
    
    override func mouseDragged(theEvent: NSEvent) {
        super.mouseDragged(theEvent)
        let lastPoint: NSPoint = theEvent.locationInWindow
        self.moveHandle(lastPoint)
    }
    
    
    
    override func mouseDown(theEvent: NSEvent) {
        if theEvent.clickCount == 1 {
            return
        }
        
        secondsLeft = readTimerField()
        
        if (secondsLeft < 0) {
            return
        } else {
            startStopTimer()
        }
    }
    
    
    
    func startStopTimer() {
        
        if (modusString == "stopWatchMode") || (modusString == "countDownMode") {
            
            // Timer is already running, stop it
            myTimer!.invalidate()
            myTimer = nil
            
            
            if alarmIsDue {
                alarmIsDue = false
            }
            
            
            timerField.editable = true
            setNeedsDisplay()
            
            
            if (modusString == "stopWatchMode") {
                modusString = "stopWatchMode_paused"
            }
            
            
            if (modusString == "countDownMode") {
                modusString = "countDownMode_paused"
            }
            
            
        } else {
            
            // Timer not yet running, start it
            myTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(timerTask), userInfo: nil, repeats: true)
            
            secondsLeft = readTimerField()
            
            timerField.editable = false
            timerField.selectable = false
            timerField.window?.makeFirstResponder(nil)
            timerField.resignFirstResponder()
            
            
            if (modusString == "stopWatchMode_paused") {
                modusString = "stopWatchMode"
            }
            
            
            if (modusString == "countDownMode_paused") {
                modusString = "countDownMode"
            }
        }
    }
    
    
    func calcAngleFromSecondsLeft () {
        // 1 degree => 10 seconds
        if (secondsLeft >= 0) {
            angle = secondsLeft/10 + 1
        } else {
            angle = secondsLeft/10
        }
    }
    
    
    func timerTask() {
        
        if (modusString == "stopWatchMode") {
            secondsLeft = secondsLeft + 1
        } else {
            secondsLeft = secondsLeft - 1
        }
        
        calcAngleFromSecondsLeft()
        
        
        updateTimerField()
        updateAlarmTimeField()
        setNeedsDisplay()
        
        
        //        let appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
        //        if let button = appDelegate.statusItem.button {
        //            button.title = "⍾ " + alarmTimeField.stringValue
        //        }
        
        
        if (secondsLeft == 0) && (modusString == "countDownMode") {
            let appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
            
            if (!alarmIsDue) {
                alarmIsDue = true
                appDelegate.showNotification()
            }
            
            // App enters stopWatch mode, i.e., starts counting seconds up
            modusString = "stopWatchMode"
            
        }
    }
    
    
    func enterTimerField() {
        
        secondsLeft = readTimerField()
        
        
        if (secondsLeft < 0) {
            return
        }
        
        
        calcAngleFromSecondsLeft()
        updateAlarmTimeField()
        setNeedsDisplay()
        
        
        if secondsLeft == 0 {
            modusString = "stopWatchMode_paused"
            resetAlarmTimeField()
        } else {
            modusString = "countDownMode_paused"
        }
        
        startStopTimer()
    }
    
    
    func updateTimerField() {
        // 1 degree => 10 seconds
        let min:Int = secondsLeft / 60
        let sec:Int = secondsLeft % 60
        timerField!.stringValue = "\(min)" + ":" + String(format: "%02d", sec)
    }
    
    
    func updateAlarmTimeField() {
        if (modusString == "stopWatchMode") || (modusString == "stopWatchMode_paused") {
            resetAlarmTimeField()
        } else {
            let additionalSecs = readTimerField()
            let currentDate = NSDate()
            let calculatedDate = currentDate.dateByAddingTimeInterval(Double(additionalSecs))
            
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "HH:mm"
            
            alarmTimeField!.stringValue = dateFormatter.stringFromDate(calculatedDate)
        }
    }
    
    
    func resetAlarmTimeField() {
        alarmTimeField!.stringValue = "--:--"
    }
    
    
    // Return time shown in timerField in seconds
    func readTimerField () -> Int {
        
        let timeString = timerField.stringValue
        
        // Test if timeString is valid input of the form MM:SS
        let charset = NSCharacterSet(charactersInString: ":")
        
        if timeString.rangeOfCharacterFromSet(charset) != nil {
            
            let timeStringArr = timeString.characters.split{$0 == ":"}.map(String.init)
            
            let min = Int(timeStringArr[0])
            let sec = Int(timeStringArr[1])
            
            if (min != nil) && (sec != nil) {
                return min! * 60 + sec!
            } else {
                // Invalid input
                return -1
            }
            
        } else {
            // Invalid input
            return -1
        }
    }
    
    
    
    // ----------------------------------------------------------------------------------------------------
    // MARK: Math Helpers
    
    
    func DegreesToRadians (value:Double) -> Double {
        return value * M_PI / 180.0
    }
    
    func RadiansToDegrees (value:Double) -> Double {
        return value * 180.0 / M_PI
    }
    
    func Square (value:CGFloat) -> CGFloat {
        return value * value
    }
    
    
    
    // Calculate the direction in degrees from a center point to an arbitrary position.
    func AngleFromNorth(p1:CGPoint , p2:CGPoint , flipped:Bool) -> Double {
        var v:CGPoint  = CGPointMake(p2.x - p1.x, p2.y - p1.y)
        let vmag:CGFloat = Square(Square(v.x) + Square(v.y))
        var result:Double = 0.0
        v.x /= vmag;
        v.y /= vmag;
        let radians = Double(atan2(v.y,v.x))
        result = RadiansToDegrees(radians) - 90
        return (result >= 0  ? result : result + 360.0);
    }
    
    
    
    // Given the angle, get the point position on circumference
    func pointFromAngle(angleInt:Int)->CGPoint{
        
        let centerPoint = CGPointMake(self.frame.size.width/2.0 - Config.CS_LINE_WIDTH/2.0, self.frame.size.height/2.0 - Config.CS_LINE_WIDTH/2.0);
        
        var result:CGPoint = CGPointZero
        let y = round(Double(radius!) * sin(DegreesToRadians(Double(-angleInt)))) + Double(centerPoint.y)
        let x = round(Double(radius!) * cos(DegreesToRadians(Double(-angleInt)))) + Double(centerPoint.x)
        result.y = CGFloat(y)
        result.x = CGFloat(x)
        
        return result;
    }
    
    
}








