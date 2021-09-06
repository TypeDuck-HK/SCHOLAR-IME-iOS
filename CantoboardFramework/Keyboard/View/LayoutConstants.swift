//
//  KeyDimensions.swift
//  Stockboard
//
//  Created by Alex Man on 1/14/21.
//

import Foundation
import UIKit

import CocoaLumberjackSwift

enum LayoutIdiom {
    case phone, pad, padFloating
}

struct LayoutConstants {
    // Fixed:
    static let keyboardViewTopInset = CGFloat(8)
    
    // Provided:
    // Keyboard size
    let idiom: LayoutIdiom
    let isPortrait: Bool
    let keyboardSize: CGSize
    let keyboardViewInsets: UIEdgeInsets
    
    // General
    let keyHeight: CGFloat
    let autoCompleteBarHeight: CGFloat
    
    // iPhone specific
    let keyButtonWidth: CGFloat
    let systemButtonWidth: CGFloat
    let shiftButtonWidth: CGFloat
    
    // Computed:
    let keyboardViewHeight: CGFloat
    let keyboardSuperviewSize: CGSize
    
    let buttonGap: CGFloat
    let keyRowGap: CGFloat
    
    let keypadButtonUnitSize: CGSize
    
    var numOfSingleCharCandidateInRow: Int {
        switch idiom {
        case .phone, .padFloating:
            return isPortrait ? 8 : 15
        case .pad:
            return isPortrait ? 15 : 20
        }
    }
        
    internal init(idiom: LayoutIdiom,
                  isPortrait: Bool,
                  keyboardSize: CGSize,
                  buttonGap: CGFloat,
                  systemKeyWidth: CGFloat,
                  shiftKeyWidth: CGFloat,
                  keyHeight: CGFloat,
                  autoCompleteBarHeight: CGFloat,
                  edgeHorizontalInset: CGFloat,
                  keyViewBottomInset: CGFloat,
                  superviewWidth: CGFloat) {
        self.idiom = idiom
        self.isPortrait = isPortrait
        self.keyboardSize = keyboardSize
        self.buttonGap = buttonGap
        self.keyboardViewInsets = UIEdgeInsets(top: Self.keyboardViewTopInset, left: edgeHorizontalInset, bottom: keyViewBottomInset, right: edgeHorizontalInset)
        self.shiftButtonWidth = shiftKeyWidth
        self.systemButtonWidth = systemKeyWidth
        self.keyHeight = keyHeight
        self.autoCompleteBarHeight = autoCompleteBarHeight
        
        keyButtonWidth = (keyboardSize.width - 2 * edgeHorizontalInset - 9 * buttonGap) / 10
        keyboardViewHeight = keyboardSize.height - autoCompleteBarHeight - Self.keyboardViewTopInset - keyViewBottomInset
        keyRowGap = (keyboardViewHeight - 4 * keyHeight) / 3
        
        keyboardSuperviewSize = CGSize(width: superviewWidth, height: keyboardSize.height)
        
        let width = (keyboardSize.width - 2 * edgeHorizontalInset - 4 * buttonGap) / 5
        let height = ((keyboardSize.height - Self.keyboardViewTopInset - keyViewBottomInset - autoCompleteBarHeight) - 3 * buttonGap) / 4
        keypadButtonUnitSize = CGSize(width: width, height: height)
    }
    
    internal static func makeiPhoneLayout(isPortrait: Bool,
                                          keyboardSize: CGSize,
                                          buttonGap: CGFloat,
                                          systemKeyWidth: CGFloat,
                                          shiftKeyWidth: CGFloat,
                                          keyHeight: CGFloat,
                                          autoCompleteBarHeight: CGFloat,
                                          keyboardViewLeftRightInset: CGFloat,
                                          keyboardSuperviewWidth: CGFloat,
                                          isPadFloating: Bool = false) -> LayoutConstants {
        return LayoutConstants(
            idiom: isPadFloating ? .padFloating : .phone,
            isPortrait: isPortrait,
            keyboardSize: keyboardSize,
            buttonGap: buttonGap,
            systemKeyWidth: systemKeyWidth,
            shiftKeyWidth: shiftKeyWidth,
            keyHeight: keyHeight,
            autoCompleteBarHeight: autoCompleteBarHeight,
            edgeHorizontalInset: keyboardViewLeftRightInset,
            keyViewBottomInset: 4,
            superviewWidth: keyboardSuperviewWidth)
    }
    
    internal static func makeiPadLayout(isPortrait: Bool,
                                        keyboardWidth: CGFloat,
                                        buttonGapX: CGFloat,
                                        rowGapY: CGFloat,
                                        returnKeyWidth: CGFloat,
                                        rightShiftKeyWidth: CGFloat,
                                        keyHeight: CGFloat,
                                        autoCompleteBarHeight: CGFloat,
                                        edgeHorizontalInset: CGFloat,
                                        keyViewBottomInset: CGFloat,
                                        superviewWidth: CGFloat) -> LayoutConstants {
        return LayoutConstants(
            idiom: .pad,
            isPortrait: isPortrait,
            keyboardSize: CGSize(width: keyboardWidth, height: keyHeight * 4 + rowGapY * 3 + autoCompleteBarHeight + Self.keyboardViewTopInset + keyViewBottomInset),
            buttonGap: buttonGapX,
            systemKeyWidth: returnKeyWidth,
            shiftKeyWidth: rightShiftKeyWidth,
            keyHeight: keyHeight,
            autoCompleteBarHeight: autoCompleteBarHeight,
            edgeHorizontalInset: edgeHorizontalInset,
            keyViewBottomInset: keyViewBottomInset,
            superviewWidth: superviewWidth)
    }
}

let layoutConstantsList: [IntDuplet: LayoutConstants] = [
    // iPhone 12 Pro Max
    // Portrait:
    IntDuplet(428, 926): LayoutConstants.makeiPhoneLayout(
        isPortrait: true,
        keyboardSize: CGSize(width: 428, height: 175+49+45),
        buttonGap: 6,
        systemKeyWidth: 48,
        shiftKeyWidth: 47,
        keyHeight: 45,
        autoCompleteBarHeight: 45,
        keyboardViewLeftRightInset: 3,
        keyboardSuperviewWidth: 428),
    // Landscape:
    IntDuplet(926, 428): LayoutConstants.makeiPhoneLayout(
        isPortrait: false,
        keyboardSize: CGSize(width: 692, height: 160+38),
        buttonGap: 5,
        systemKeyWidth: 62,
        shiftKeyWidth: 84,
        keyHeight: 32,
        autoCompleteBarHeight: 38,
        keyboardViewLeftRightInset: 3,
        keyboardSuperviewWidth: 926),
    
    // iPhone 12, 12 Pro
    // Portrait:
    IntDuplet(390, 844): LayoutConstants.makeiPhoneLayout(
        isPortrait: true,
        keyboardSize: CGSize(width: 390, height: 216+45),
        buttonGap: 6,
        systemKeyWidth: 43,
        shiftKeyWidth: 44,
        keyHeight: 42,
        autoCompleteBarHeight: 45,
        keyboardViewLeftRightInset: 3,
        keyboardSuperviewWidth: 390),
    // Landscape:
    IntDuplet(844, 390): LayoutConstants.makeiPhoneLayout(
        isPortrait: false,
        keyboardSize: CGSize(width: 694, height: 160+38),
        buttonGap: 5,
        systemKeyWidth: 62,
        shiftKeyWidth: 84,
        keyHeight: 32,
        autoCompleteBarHeight: 38,
        keyboardViewLeftRightInset: 3,
        keyboardSuperviewWidth: 844),
    
    // iPhone 12 mini, 11 Pro, X, Xs
    // Portrait:
    IntDuplet(375, 812): LayoutConstants.makeiPhoneLayout(
        isPortrait: true,
        keyboardSize: CGSize(width: 375, height: 216+45),
        buttonGap: 6,
        systemKeyWidth: 40,
        shiftKeyWidth: 42,
        keyHeight: 42,
        autoCompleteBarHeight: 45,
        keyboardViewLeftRightInset: 3,
        keyboardSuperviewWidth: 375),
    // Landscape:
    IntDuplet(812, 375): LayoutConstants.makeiPhoneLayout(
        isPortrait: false,
        keyboardSize: CGSize(width: 662, height: 150+38),
        buttonGap: 5,
        systemKeyWidth: 59,
        shiftKeyWidth: 80,
        keyHeight: 30,
        autoCompleteBarHeight: 38,
        keyboardViewLeftRightInset: 3,
        keyboardSuperviewWidth: 812),
    
    // iPhone 11 Pro Max, Xs Max, 11, Xr
    // Portrait:
    IntDuplet(414, 896): LayoutConstants.makeiPhoneLayout(
        isPortrait: true,
        keyboardSize: CGSize(width: 414, height: 226+45),
        buttonGap: 6,
        systemKeyWidth: 46,
        shiftKeyWidth: 46,
        keyHeight: 45,
        autoCompleteBarHeight: 45,
        keyboardViewLeftRightInset: 4,
        keyboardSuperviewWidth: 414),
    // Landscape:
    IntDuplet(896, 414): LayoutConstants.makeiPhoneLayout(
        isPortrait: false,
        keyboardSize: CGSize(width: 662, height: 150+38),
        buttonGap: 5,
        systemKeyWidth: 59,
        shiftKeyWidth: 80,
        keyHeight: 30,
        autoCompleteBarHeight: 38,
        keyboardViewLeftRightInset: 3,
        keyboardSuperviewWidth: 896),
    
    // iPhone 8+, 7+, 6s+, 6+
    // Portrait:
    IntDuplet(414, 736): LayoutConstants.makeiPhoneLayout(
        isPortrait: true,
        keyboardSize: CGSize(width: 414, height: 226+45),
        buttonGap: 6,
        systemKeyWidth: 46,
        shiftKeyWidth: 45,
        keyHeight: 45,
        autoCompleteBarHeight: 45,
        keyboardViewLeftRightInset: 4,
        keyboardSuperviewWidth: 414),
    // Landscape:
    IntDuplet(736, 414): LayoutConstants.makeiPhoneLayout(
        isPortrait: false,
        keyboardSize: CGSize(width: 588, height: 162+38),
        buttonGap: 6,
        systemKeyWidth: 69,
        shiftKeyWidth: 69,
        keyHeight: 32,
        autoCompleteBarHeight: 38,
        keyboardViewLeftRightInset: 2,
        keyboardSuperviewWidth: 736),
    
    // iPhone SE (2nd gen), 8, 7, 6s, 6
    // Portrait:
    IntDuplet(375, 667): LayoutConstants.makeiPhoneLayout(
        isPortrait: true,
        keyboardSize: CGSize(width: 375, height: 216+44),
        buttonGap: 6,
        systemKeyWidth: 40,
        shiftKeyWidth: 42,
        keyHeight: 42,
        autoCompleteBarHeight: 44,
        keyboardViewLeftRightInset: 3,
        keyboardSuperviewWidth: 375),
    // Landscape:
    IntDuplet(667, 375): LayoutConstants.makeiPhoneLayout(
        isPortrait: false,
        keyboardSize: CGSize(width: 526, height: 162+38),
        buttonGap: 6,
        systemKeyWidth: 63,
        shiftKeyWidth: 63,
        keyHeight: 32,
        autoCompleteBarHeight: 38,
        keyboardViewLeftRightInset: 3,
        keyboardSuperviewWidth: 667),
    
    // iPhone SE (1st gen), 5c, 5s, 5
    // Portrait:
    IntDuplet(320, 568): LayoutConstants.makeiPhoneLayout(
        isPortrait: true,
        keyboardSize: CGSize(width: 320, height: 216+38),
        buttonGap: 6,
        systemKeyWidth: 34,
        shiftKeyWidth: 36,
        keyHeight: 38,
        autoCompleteBarHeight: 38,
        keyboardViewLeftRightInset: 3,
        keyboardSuperviewWidth: 320),
    // Landscape:
    IntDuplet(568, 320): LayoutConstants.makeiPhoneLayout(
        isPortrait: false,
        keyboardSize: CGSize(width: 568, height: 162+38),
        buttonGap: 5,
        systemKeyWidth: 50,
        shiftKeyWidth: 68,
        keyHeight: 32,
        autoCompleteBarHeight: 38,
        keyboardViewLeftRightInset: 3,
        keyboardSuperviewWidth: 568),
    
    // iPad 1024x1366 iPad Pro 12.9"
    // Portrait:
    IntDuplet(1024, 1366): LayoutConstants.makeiPadLayout(
        isPortrait: true,
        keyboardWidth: 1024,
        buttonGapX: 7,
        rowGapY: 7,
        returnKeyWidth: 100,
        rightShiftKeyWidth: 147,
        keyHeight: 62,
        autoCompleteBarHeight: 55,
        edgeHorizontalInset: 3,
        keyViewBottomInset: 3,
        superviewWidth: 1024),
    // Landscape:
    IntDuplet(1366, 1024): LayoutConstants.makeiPadLayout(
        isPortrait: false,
        keyboardWidth: 1366,
        buttonGapX: 9,
        rowGapY: 9,
        returnKeyWidth: 132,
        rightShiftKeyWidth: 194,
        keyHeight: 80,
        autoCompleteBarHeight: 55,
        edgeHorizontalInset: 7,
        keyViewBottomInset: 3,
        superviewWidth: 1366),
    
    // iPad 834×1194 iPad Pro 11"
    // Portrait:
    IntDuplet(834, 1194): LayoutConstants.makeiPadLayout(
        isPortrait: true,
        keyboardWidth: 834,
        buttonGapX: 11,
        rowGapY: 11,
        returnKeyWidth: 59,
        rightShiftKeyWidth: 115,
        keyHeight: 55,
        autoCompleteBarHeight: 55,
        edgeHorizontalInset: 3,
        keyViewBottomInset: 3,
        superviewWidth: 834),
    // Landscape:
    IntDuplet(1194, 834): LayoutConstants.makeiPadLayout(
        isPortrait: false,
        keyboardWidth: 1194,
        buttonGapX: 11,
        rowGapY: 11,
        returnKeyWidth: 81.5,
        rightShiftKeyWidth: 165,
        keyHeight: 75,
        autoCompleteBarHeight: 55,
        edgeHorizontalInset: 7,
        keyViewBottomInset: 3,
        superviewWidth: 1194),
    
    // iPad 820×1180 iPad Air (gen 4)
    // Portrait:
    IntDuplet(820, 1180): LayoutConstants.makeiPadLayout(
        isPortrait: true,
        keyboardWidth: 820,
        buttonGapX: 8,
        rowGapY: 8,
        returnKeyWidth: 59,
        rightShiftKeyWidth: 115,
        keyHeight: 55,
        autoCompleteBarHeight: 55,
        edgeHorizontalInset: 3,
        keyViewBottomInset: 3,
        superviewWidth: 820),
    // Landscape:
    IntDuplet(1180, 820): LayoutConstants.makeiPadLayout(
        isPortrait: false,
        keyboardWidth: 1180,
        buttonGapX: 11,
        rowGapY: 11,
        returnKeyWidth: 81.5,
        rightShiftKeyWidth: 165,
        keyHeight: 73,
        autoCompleteBarHeight: 55,
        edgeHorizontalInset: 7,
        keyViewBottomInset: 3,
        superviewWidth: 1180),
    
    // iPad 810×1080 iPad (gen 8/7)
    // Portrait:
    IntDuplet(810, 1080): LayoutConstants.makeiPadLayout(
        isPortrait: true,
        keyboardWidth: 810,
        buttonGapX: 12,
        rowGapY: 9,
        returnKeyWidth: 112.5,
        rightShiftKeyWidth: 81,
        keyHeight: 55,
        autoCompleteBarHeight: 55,
        edgeHorizontalInset: 6,
        keyViewBottomInset: 8,
        superviewWidth: 810),
    // Landscape:
    IntDuplet(1080, 810): LayoutConstants.makeiPadLayout(
        isPortrait: false,
        keyboardWidth: 1080,
        buttonGapX: 14.5,
        rowGapY: 12,
        returnKeyWidth: 152,
        rightShiftKeyWidth: 111.5,
        keyHeight: 74,
        autoCompleteBarHeight: 55,
        edgeHorizontalInset: 7,
        keyViewBottomInset: 10,
        superviewWidth: 1080),
    
    // iPad 834×1112 iPad Air (gen 3) iPad Pro 10.5"
    // Portrait:
    IntDuplet(834, 1112): LayoutConstants.makeiPadLayout(
        isPortrait: true,
        keyboardWidth: 834,
        buttonGapX: 12,
        rowGapY: 9,
        returnKeyWidth: 115.5,
        rightShiftKeyWidth: 83,
        keyHeight: 55,
        autoCompleteBarHeight: 55,
        edgeHorizontalInset: 6.5,
        keyViewBottomInset: 8,
        superviewWidth: 834),
    // Landscape:
    IntDuplet(1112, 834): LayoutConstants.makeiPadLayout(
        isPortrait: false,
        keyboardWidth: 1112,
        buttonGapX: 14.5,
        rowGapY: 12,
        returnKeyWidth: 156.5,
        rightShiftKeyWidth: 114.5,
        keyHeight: 74,
        autoCompleteBarHeight: 55,
        edgeHorizontalInset: 7.5,
        keyViewBottomInset: 10,
        superviewWidth: 1112),
    
    // iPad 768x1024 iPad (gen 6/5/4/3/2/1) iPad Pro 9.7" iPad Air (gen 2/1) iPad mini (gen 5/4/3/2/1)
    // Portrait:
    IntDuplet(768, 1024): LayoutConstants.makeiPadLayout(
        isPortrait: true,
        keyboardWidth: 768,
        buttonGapX: 12,
        rowGapY: 9,
        returnKeyWidth: 106,
        rightShiftKeyWidth: 76,
        keyHeight: 55,
        autoCompleteBarHeight: 55,
        edgeHorizontalInset: 6,
        keyViewBottomInset: 8,
        superviewWidth: 768),
    // Landscape:
    IntDuplet(1024, 768): LayoutConstants.makeiPadLayout(
        isPortrait: false,
        keyboardWidth: 1024,
        buttonGapX: 12,
        rowGapY: 9,
        returnKeyWidth: 144,
        rightShiftKeyWidth: 105,
        keyHeight: 74,
        autoCompleteBarHeight: 55,
        edgeHorizontalInset: 7,
        keyViewBottomInset: 10,
        superviewWidth: 1024),
    
    // iPad floating mode
    IntDuplet(320, 254): LayoutConstants.makeiPhoneLayout(
        isPortrait: false,
        keyboardSize: CGSize(width: 320, height: 254),
        buttonGap: 6,
        systemKeyWidth: 34,
        shiftKeyWidth: 36,
        keyHeight: 39,
        autoCompleteBarHeight: 38,
        keyboardViewLeftRightInset: 3,
        keyboardSuperviewWidth: 320,
        isPadFloating: true),
]

extension LayoutConstants {
    static var forMainScreen: LayoutConstants {
        return getContants(screenSize: UIScreen.main.bounds.size)
    }
    
    static func getContants(screenSize: CGSize) -> LayoutConstants {
        // TODO instead of returning an exact match, return the nearest (floorKey?) match.
        guard let ret = layoutConstantsList[IntDuplet(Int(screenSize.width), Int(screenSize.height))] else {
            DDLogInfo("Cannot find constants for (\(screenSize.width), \(screenSize.height)).")
            return layoutConstantsList.first!.value
        }
        
        return ret
    }
}
