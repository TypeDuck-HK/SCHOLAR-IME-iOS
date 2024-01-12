//
//  Settings.swift
//  Cantoboard
//
//  Created by Alex Man on 16/10/21.
//

import UIKit
import CantoboardFramework

struct Section {
    var header: String?
    var options: [Option]
    
    fileprivate init(_ header: String? = nil, _ options: [Option] = []) {
        self.header = header
        self.options = options
    }
}

protocol Option {
    var title: String { get }
    var description: String? { get }
    var videoUrl: String? { get }
    func dequeueCell(with controller: MainViewController) -> UITableViewCell
    func updateSettings()
}

private class Switch: Option {
    var title: String
    var description: String?
    var videoUrl: String?
    var key: WritableKeyPath<Settings, Bool>
    var value: Bool
    
    private var controller: MainViewController!
    private var control: UISwitch!
    
    init(_ title: String, _ key: WritableKeyPath<Settings, Bool>, _ description: String? = nil, _ videoUrl: String? = nil) {
        self.title = title
        self.key = key
        self.value = Settings.cached[keyPath: key]
        self.description = description
        self.videoUrl = videoUrl
    }
    
    func dequeueCell(with controller: MainViewController) -> UITableViewCell {
        self.controller = controller
        control = UISwitch()
        control.isOn = value
        control.addTarget(self, action: #selector(updateSettings), for: .valueChanged)
        return OptionTableViewCell(option: self, optionView: control)
    }
    
    @objc func updateSettings() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        value = control.isOn
        controller.settings[keyPath: key] = value
        controller.view.endEditing(true)
        Settings.save(controller.settings)
    }
}

private class Segment<T: Equatable>: Option {
    var title: String
    var description: String?
    var videoUrl: String?
    var key: WritableKeyPath<Settings, T>
    var value: T
    var options: KeyValuePairs<String, T>
    
    private var controller: MainViewController!
    private var control: UISegmentedControl!
    
    init(_ title: String, _ key: WritableKeyPath<Settings, T>, _ options: KeyValuePairs<String, T>, _ description: String? = nil, _ videoUrl: String? = nil) {
        self.title = title
        self.key = key
        self.value = Settings.cached[keyPath: key]
        self.options = options
        self.description = description
        self.videoUrl = videoUrl
    }
    
    func dequeueCell(with controller: MainViewController) -> UITableViewCell {
        self.controller = controller
        control = UISegmentedControl(items: options.map { $0.key })
        control.setTitleTextAttributes(String.HKAttribute, for: .normal)
        control.selectedSegmentIndex = options.firstIndex(where: { $1 == value })!
        control.apportionsSegmentWidthsByContent = Bundle.main.preferredLocalizations[0] == "en"
        control.addTarget(self, action: #selector(updateSettings), for: .valueChanged)
        return OptionTableViewCell(option: self, optionView: control)
    }
    
    @objc func updateSettings() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        value = options[control.selectedSegmentIndex].value
        controller.settings[keyPath: key] = value
        controller.view.endEditing(true)
        Settings.save(controller.settings)
    }
}

extension Settings {
    private var enableCorrector: Bool {
        get { rimeSettings.enableCorrector }
        set { rimeSettings.enableCorrector = newValue }
    }
    
    static func buildSections() -> [Section] {
        let padSection = Section(
            LocalizedStrings.padSettings,
            [
                Segment(LocalizedStrings.candidateBarStyle, \.fullPadCandidateBar, [
                        LocalizedStrings.candidateBarStyle_full: true,
                        LocalizedStrings.candidateBarStyle_ios: false,
                ]),
                Segment(LocalizedStrings.padLeftSysKey, \.padLeftSysKeyAsKeyboardType, [
                        LocalizedStrings.padLeftSysKey_default: false,
                        LocalizedStrings.padLeftSysKey_keyboardType: true,
                    ],
                    LocalizedStrings.padLeftSysKey_description
                ),
            ]
        )
        
        return [
            Section(
                LocalizedStrings.inputMethodSettings,
                [
                    Switch(LocalizedStrings.mixedMode, \.isMixedModeEnabled),
                    Switch(LocalizedStrings.longPressSymbolKeys, \.isLongPressSymbolKeysEnabled, LocalizedStrings.longPressSymbolKeys_description),
                    Switch(LocalizedStrings.smartFullStop, \.isSmartFullStopEnabled,
                           LocalizedStrings.smartFullStop_description, "Guide8-1"),
                    Switch(LocalizedStrings.audioFeedback, \.isAudioFeedbackEnabled),
                ] + (UIDevice.current.userInterfaceIdiom == .pad ? [] : [
                    Switch(LocalizedStrings.tapHapticFeedback, \.isTapHapticFeedbackEnabled),
                ]) + [
                    Switch(LocalizedStrings.enableCharPreview, \.enableCharPreview),
                    Segment(LocalizedStrings.candidateFontSize, \.candidateFontSize, [
                            LocalizedStrings.candidateFontSize_small: .small,
                            LocalizedStrings.candidateFontSize_normal: .normal,
                            LocalizedStrings.candidateFontSize_large: .large,
                    ]),
                    Segment(LocalizedStrings.candidateGap, \.candidateGap, [
                            LocalizedStrings.candidateGap_normal: .normal,
                            LocalizedStrings.candidateGap_large: .large,
                    ]),
                    Segment(LocalizedStrings.symbolShape, \.symbolShape, [
                            LocalizedStrings.symbolShape_half: .half,
                            LocalizedStrings.symbolShape_full: .full,
                            LocalizedStrings.symbolShape_smart: .smart,
                    ]),
                ]
            ),
            UIDevice.current.userInterfaceIdiom == .pad ? padSection : nil,
            Section(
                LocalizedStrings.chineseInputSettings,
                [
                    Switch(LocalizedStrings.enablePredictiveText, \.enablePredictiveText,
                           LocalizedStrings.enablePredictiveText_description),
                    Segment(LocalizedStrings.compositionMode, \.compositionMode, [
                            LocalizedStrings.compositionMode_immediate: .immediate,
                            LocalizedStrings.compositionMode_multiStage: .multiStage,
                        ],
                        LocalizedStrings.compositionMode_description, "Guide2-1"
                    ),
                    Segment(LocalizedStrings.spaceAction, \.spaceAction, [
                            LocalizedStrings.spaceAction_nextPage: .nextPage,
                            LocalizedStrings.spaceAction_insertCandidate: .insertCandidate,
                            LocalizedStrings.spaceAction_insertText: .insertText,
                    ]),
                    Segment(LocalizedStrings.showRomanizationMode, \.showRomanizationMode, [
                            LocalizedStrings.showRomanizationMode_never: .never,
                            LocalizedStrings.showRomanizationMode_always: .always,
                            LocalizedStrings.showRomanizationMode_onlyInNonCantoneseMode: .onlyInNonCantoneseMode,
                    ]),
                    Switch(LocalizedStrings.showCodeInReverseLookup, \.showCodeInReverseLookup),
                    Switch(LocalizedStrings.enableCorrector, \.enableCorrector,
                           LocalizedStrings.enableCorrector_description, "Guide12-1"),
                    Segment(LocalizedStrings.cantoneseKeyboardLayout, \.cantoneseKeyboardLayout, [
                            LocalizedStrings.cantoneseKeyboardLayout_qwerty: .qwerty,
                            LocalizedStrings.cantoneseKeyboardLayout_tenKeys: .tenKeys,
                        ]
                    ),
                    Segment(LocalizedStrings.toneInputMode, \.toneInputMode, [
                            LocalizedStrings.toneInputMode_vxq: .vxq,
                            LocalizedStrings.toneInputMode_longPress: .longPress,
                        ],
                        LocalizedStrings.toneInputMode_description, "Guide3-2"
                    ),
                    Segment(LocalizedStrings.cangjieVersion, \.cangjieVersion, [
                            LocalizedStrings.cangjie3: .cangjie3,
                            LocalizedStrings.cangjie5: .cangjie5,
                        ]
                    ),
                ]
            ),
            Section(
                LocalizedStrings.englishInputSettings,
                [
                    Switch(LocalizedStrings.autoCap, \.isAutoCapEnabled),
                    Segment(LocalizedStrings.englishLocale, \.englishLocale, [
                            LocalizedStrings.englishLocale_au: .au,
                            LocalizedStrings.englishLocale_ca: .ca,
                            LocalizedStrings.englishLocale_gb: .gb,
                            LocalizedStrings.englishLocale_us: .us,
                    ]),
                ]
            ),
        ].compactMap({ $0 })
    }
}
