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
import SwiftUI

@main
struct AllResToolApp: App {
    @State private var data: [Display] = availableDisplayModes()
    
    var body: some Scene {
        MenuBarExtra("AllResTool", systemImage: "tv.fill") {
            Text("AllResTool v1.1")
            Divider()
            ForEach(data.indices, id: \.self) { index in
                Picker(data[index].name, selection: $data[index].requestedModeNumber) {
                    ForEach(data[index].modes, id: \.modeNumber) { mode in
                        Text(mode.name)
                    }
                }
            }
            Divider()
            Button("Refresh") {
                data = availableDisplayModes()
            }
            Button("Quit") {
                exit(0)
            }
        }
        .menuBarExtraStyle(.menu)
        .onChange(of: data, { _, _ in
            for display in data {
                if display.currentModeNumber != display.requestedModeNumber {
                    switchToMode(display.id, display.requestedModeNumber)
                }
            }
            data = availableDisplayModes()
        })
    }
}

struct Mode: Equatable {
    let name: String
    let width: UInt32
    let height: UInt32
    let freq: UInt16
    let modeNumber: Int32
}

struct Display: Equatable {
    let name: String
    let id: CGDirectDisplayID
    let modes: [Mode]
    var currentModeNumber: Int32
    var requestedModeNumber: Int32
}

func availableDisplayModes() -> [Display] {
    let maxDisplays: UInt32 = 64
    var onlineDisplays: [CGDirectDisplayID] = .init(repeating: 0, count: Int(maxDisplays))
    var displayCount: UInt32 = 0
    
    CGGetOnlineDisplayList(maxDisplays, &onlineDisplays, &displayCount)
    
    var availableDisplays: [Display] = []
    
    for onlineDisplay in onlineDisplays[0..<Int(displayCount)] {
        
        let name = NSScreen.screens.first(where: { $0.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID == onlineDisplay })?.localizedName ?? ""
        
        var modeId: Int32 = 0
        CGSGetCurrentDisplayMode(onlineDisplay, &modeId)
        
        let extendedName = "\(name) (\(CGDisplayPixelsWide(onlineDisplay)) x \(CGDisplayPixelsHigh(onlineDisplay))) [\(onlineDisplay)]"
        
        var numDisplayModes: Int32 = 0
        CGSGetNumberOfDisplayModes(onlineDisplay, &numDisplayModes)
        
        var availableModes: [Mode] = []
        
        for i in 0..<numDisplayModes {
            var mode = CGSDisplayMode()
            CGSGetDisplayModeDescriptionOfLength(onlineDisplay, i, &mode, 212)
            let name = "\(mode.width) x \(mode.height), \(mode.freq) Hz, \(mode.density)x \(mode.density > 1.0 ? "(HiDPI)" : "") [\(mode.modeNumber)]"
            availableModes.append(Mode(name: name, width: mode.width, height: mode.height, freq: mode.freq, modeNumber: Int32(mode.modeNumber)))
        }
        
        availableDisplays.append(Display(name: extendedName, id: onlineDisplay, modes: availableModes.sorted(by: { ($0.width, $0.height, $0.freq) > ($1.width, $1.height, $1.freq) }), currentModeNumber: modeId, requestedModeNumber: modeId))
    }
    
    return availableDisplays
}

func switchToMode(_ display: CGDirectDisplayID, _ mode: Int32) {
    let availableModes = availableDisplayModes()
    guard availableModes.first(where: { $0.id == display })?.modes.first(where: { $0.modeNumber == mode }) != nil else {
        print("Invalid display or mode.")
        return
    }
    var config: CGDisplayConfigRef?
    CGBeginDisplayConfiguration(&config)
    CGSConfigureDisplayMode(config, display, mode)
    CGCompleteDisplayConfiguration(config, .permanently)
}
