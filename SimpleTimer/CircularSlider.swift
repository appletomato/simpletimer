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
    static let CS_SAFEAREA_PADDING:CGFloat = 4.0
    static let CS_SENSITIVITY_IN_DECASECONDS:Int = 6
}


class CircularSlider: NSControl {
    
    
    var timerField:NSLabel!
    var alarmTimeField:NSLabel!
    var myTimer: Timer?
    var angle:Int = 0
    var radius:CGFloat?
    var startColor = NSColor.blue
    var endColor = NSColor.red
    var secondsLeft:Int = 0
    var arcDirection:Int32 = 1
    var alarmIsDue:Bool = false
    var modusString:String = "stopWatchMode_paused"
    var alarmTime:CFAbsoluteTime!
    
    
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
        
        let timeFieldFont = NSFont.monospacedDigitSystemFont(ofSize: Config.CS_TIME_FIELD_FONTSIZE, weight: NSFontWeightRegular)
        let timeStr = "HHH:MM" as NSString
        let timeFieldFontSize:CGSize = timeStr.size(withAttributes: [NSFontAttributeName:timeFieldFont])
        
        
        let timeFieldRect = CGRect(
            x: (frame.size.width  - timeFieldFontSize.width) / 2.0,
            y: (frame.size.height - timeFieldFontSize.height) / 2.0,
            width: timeFieldFontSize.width, height: timeFieldFontSize.height);
        
        
        timerField = NSLabel(frame: timeFieldRect)
        timerField?.isEditable = true
        timerField.selectText(nil)
        timerField?.target = self
        timerField?.action = #selector(enterTimerField)
        timerField?.textColor = NSColor.black
        timerField?.alignment = .center
        timerField?.font = timeFieldFont
        timerField?.stringValue = "0:00"
        timerField?.focusRingType = NSFocusRingType.none
        
        addSubview(timerField!)
        
        
        /** alarmTimeField for displaying alarm time **/
        
        let alarmTimeFieldFont = NSFont.monospacedDigitSystemFont(ofSize: Config.CS_ALARM_TIME_FIELD_FONTSIZE, weight: NSFontWeightRegular)
        let alarmStr = "HH:MM:SS" as NSString
        let alarmTimeFieldFontSize:CGSize = alarmStr.size(withAttributes: [NSFontAttributeName:alarmTimeFieldFont])
        
        
        let alarmTimeFieldRect = CGRect(
            x: (frame.size.width  - alarmTimeFieldFontSize.width) / 2.0,
            y: (frame.size.height - alarmTimeFieldFontSize.height) / 2.0 - timeFieldFontSize.height,
            width: alarmTimeFieldFontSize.width, height: 1.25 * alarmTimeFieldFontSize.height);
        
        
        alarmTimeField = NSLabel(frame:alarmTimeFieldRect)
        
        alarmTimeField?.textColor = NSColor.darkGray
        alarmTimeField?.alignment = .center
        alarmTimeField?.font = alarmTimeFieldFont
        alarmTimeField?.stringValue = "--:--"
        
        addSubview(alarmTimeField!)
        
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented", file: "", line: 0)
    }
    
    
    /** Use the draw rect to draw the Background, the Circle and the Handle **/
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        
        let ctx = NSGraphicsContext.current()!.cgContext
        
        
        // Draw the background
        ctx.addArc(center: CGPoint(x: CGFloat(self.frame.size.width/2), y: CGFloat(self.frame.size.height/2)), radius: 5*radius!, startAngle: 0, endAngle: CGFloat(M_PI*2.0), clockwise: true)
        
        
        // Set fill/stroke color
        if (alarmIsDue) {
            NSColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0).set()
        } else {
            NSColor.clear.set()
        }
        
        ctx.setLineWidth(Config.CS_LINE_WIDTH)
        ctx.drawPath(using: CGPathDrawingMode.fillStroke)
        
        
        
        // Draw the time indicator
        ctx.addArc(center: CGPoint(x: CGFloat(self.frame.size.width/2), y: CGFloat(self.frame.size.height/2)), radius: radius!, startAngle: CGFloat(M_PI/2.0), endAngle: CGFloat(-1.0*DegreesToRadians(Double(angle))+M_PI/2.0), clockwise: Bool(arcDirection as NSNumber))
        
    
    
        ctx.setLineWidth(Config.CS_LINE_WIDTH)
        ctx.setLineCap(CGLineCap.butt)
        
        let red_val  = CGFloat(2.0*(1.0/(1.0+exp(-2000.0/Double(secondsLeft)))-0.5))
        let blue_val = CGFloat(2.0/(1.0+exp(2000.0/Double(secondsLeft))))

        
        ctx.setStrokeColor(NSColor(red: red_val, green: 0.0, blue: blue_val, alpha: 1.0).cgColor)
        ctx.drawPath(using: CGPathDrawingMode.fillStroke)
        

        // Draw the handle
        let handleCenter = pointFromAngle(angle-90)

        
        NSColor.darkGray.set()
        
        ctx.addArc(center: CGPoint(x: handleCenter.x, y: handleCenter.y), radius: Config.CS_LINE_WIDTH/2.0+1.0, startAngle: 0, endAngle: CGFloat(M_PI*2.0), clockwise: true)
        
        ctx.setLineWidth(1.0)
        ctx.setStrokeColor(NSColor.white.cgColor)
        ctx.drawPath(using: CGPathDrawingMode.fillStroke)
        
        
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
    
    
    
    func moveHandle(_ lastPoint:CGPoint){
        
        
        // Handle cannot be moved if timer is busy
        if (modusString == "stopWatchMode") || (modusString == "countDownMode") {
            return
        }
        
        
        // Get the winding number
        let w:Int = angle / 360
        
        
        let centerPoint:CGPoint  = CGPoint(x: self.frame.size.width/2, y: self.frame.size.height/2);
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
    
    
    
    override func mouseDragged(with theEvent: NSEvent) {
        super.mouseDragged(with: theEvent)
        let lastPoint: NSPoint = theEvent.locationInWindow
        self.moveHandle(lastPoint)
    }
    
    
    
    override func mouseDown(with theEvent: NSEvent) {
        
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
            
            
            timerField.isEditable = true
            timerField.selectText(nil)
            setNeedsDisplay()
            
            
            if (modusString == "stopWatchMode") {
                modusString = "stopWatchMode_paused"
            }
            
            
            if (modusString == "countDownMode") {
                modusString = "countDownMode_paused"
            }
            
            
        } else {
            
            // Timer not yet running, start it
            myTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(timerTask), userInfo: nil, repeats: true)
            
            secondsLeft = readTimerField()
            
            timerField.isEditable = false
            timerField.isSelectable = false
            timerField.window?.makeFirstResponder(nil)
            timerField.resignFirstResponder()
            
            
            if (modusString == "stopWatchMode_paused") {
                alarmTime = CFAbsoluteTimeGetCurrent() - Double(secondsLeft)
                modusString = "stopWatchMode"
            }
            
            
            if (modusString == "countDownMode_paused") {
                alarmTime = CFAbsoluteTimeGetCurrent() + Double(secondsLeft)
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
            secondsLeft = lround(CFAbsoluteTimeGetCurrent() - alarmTime)
        } else {
            secondsLeft = lround(alarmTime - CFAbsoluteTimeGetCurrent())
        }
        
        calcAngleFromSecondsLeft()
        
        
        updateTimerField()
        updateAlarmTimeField()
        setNeedsDisplay()
        
        
        //        let appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
        //        if let button = appDelegate.statusItem.button {
        //            button.title = "⍾ " + alarmTimeField.stringValue
        //        }
        
        
        if (secondsLeft <= 0) && (modusString == "countDownMode") {
            let appDelegate = NSApplication.shared().delegate as! AppDelegate
            
            if (!alarmIsDue) {
                alarmIsDue = true
                appDelegate.showNotification()
            }
            
            // App enters stopWatch mode, i.e., starts counting seconds up
            modusString = "stopWatchMode"
            secondsLeft = abs(secondsLeft)
            
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
            let currentDate = Date()
            let calculatedDate = currentDate.addingTimeInterval(Double(additionalSecs))
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm"
            
            alarmTimeField!.stringValue = dateFormatter.string(from: calculatedDate)
        }
        
        
    }
    
    
    func resetAlarmTimeField() {
        
        alarmTimeField!.stringValue = "--:--"
    }
    
    
    // Return time shown in timerField in seconds
    func readTimerField () -> Int {
        
        let timeString = timerField.stringValue
        
        // Test if timeString is valid input of the form MM:SS
        let charset = CharacterSet(charactersIn: ":")
        
        if timeString.rangeOfCharacter(from: charset) != nil {
            
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
    
    
    func DegreesToRadians (_ value:Double) -> Double {
        return value * M_PI / 180.0
    }
    
    func RadiansToDegrees (_ value:Double) -> Double {
        return value * 180.0 / M_PI
    }
    
    func Square (_ value:CGFloat) -> CGFloat {
        return value * value
    }
    
    
    
    // Calculate the direction in degrees from a center point to an arbitrary position.
    func AngleFromNorth(_ p1:CGPoint , p2:CGPoint , flipped:Bool) -> Double {
        var v:CGPoint  = CGPoint(x: p2.x - p1.x, y: p2.y - p1.y)
        let vmag:CGFloat = Square(Square(v.x) + Square(v.y))
        var result:Double = 0.0
        v.x /= vmag;
        v.y /= vmag;
        let radians = Double(atan2(v.y,v.x))
        result = RadiansToDegrees(radians) - 90
        return (result >= 0  ? result : result + 360.0);
    }
    
    
    
    // Given the angle, get the point position on circumference
    func pointFromAngle(_ angleInt:Int)->CGPoint{
        
        let centerPoint = CGPoint(x: self.frame.size.width/2.0, y: self.frame.size.height/2.0);
        
        var result:CGPoint = CGPoint.zero
        let y = round(Double(radius!) * sin(DegreesToRadians(Double(-angleInt)))) + Double(centerPoint.y)
        let x = round(Double(radius!) * cos(DegreesToRadians(Double(-angleInt)))) + Double(centerPoint.x)
        result.y = CGFloat(y)
        result.x = CGFloat(x)
        
        return result;
    }
    
    
}








