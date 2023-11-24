// AllResTool
//
// Copyright (c) 2023 Leszek S
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation
import CoreGraphics
import AppKit

print("AllResTool v1.0\n")

let maxDisplays: UInt32 = 64
var onlineDisplays: [CGDirectDisplayID] = .init(repeating: 0, count: Int(maxDisplays))
var displayCount: UInt32 = 0

CGGetOnlineDisplayList(maxDisplays, &onlineDisplays, &displayCount)

var validDisplaysWithModes: [String] = []

print("Available displays:\n")

for onlineDisplay in onlineDisplays[0..<Int(displayCount)] {
    
    let name = NSScreen.screens.first(where: { $0.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID == onlineDisplay })?.localizedName ?? ""
    
    var modeId: Int32 = 0
    CGSGetCurrentDisplayMode(onlineDisplay, &modeId)
    
    print("  \(name) (\(CGDisplayPixelsWide(onlineDisplay)) x \(CGDisplayPixelsHigh(onlineDisplay)))")
    print("  displayID = \(onlineDisplay)\n  modeID = \(modeId)")
    
    var numDisplayModes: Int32 = 0
    CGSGetNumberOfDisplayModes(onlineDisplay, &numDisplayModes)
    print("  \(numDisplayModes) modes available:\n")

    for i in 0..<numDisplayModes {
        var mode = CGSDisplayMode()
        CGSGetDisplayModeDescriptionOfLength(onlineDisplay, i, &mode, 212)
        print("    modeID \(mode.modeNumber):\t\(mode.width) x \(mode.height)\t\(mode.density)  \(mode.freq)Hz")
        validDisplaysWithModes.append("\(onlineDisplay) \(mode.modeNumber)")
    }

    print("")
}

let argv = CommandLine.arguments
if argv.count == 3 {
    let display = CGDirectDisplayID(argv[1])
    let mode = Int32(argv[2])
    guard let display = display, let mode = mode, validDisplaysWithModes.contains("\(display) \(mode)") else {
        print("Invalid display or mode.")
        exit(1)
    }
    print("Setting mode \(mode) on display \(display).")
    
    var config: CGDisplayConfigRef?
    CGBeginDisplayConfiguration(&config)
    CGSConfigureDisplayMode(config, display, mode)
    CGCompleteDisplayConfiguration(config, .permanently)
} else {
    print("To switch mode use:\n    allrestool [displayID] [modeID]\n")
}
