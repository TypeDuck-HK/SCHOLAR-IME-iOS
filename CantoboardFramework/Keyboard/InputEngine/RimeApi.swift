//
//  RimeApi.swift
//  KeyboardKit
//
//  Created by Alex Man on 2/19/21.
//

import Foundation

import CocoaLumberjackSwift

private let patchHeader = "patch:\n  __patch:\n"

enum RimeOption: String {
    case disableCompletion = "disable_completion"
    case enableCorrection = "enable_correction"
    case disableSentence = "disable_sentence"
    case disableLearning = "disable_learning"
    case separateCandidates = "separate_candidates"
    case showFullCode = "show_full_code"
    
    var configLine: String {
        "    - common:/\(self.rawValue)\n"
    }
}

// Make RimeApi a singleton with listener.
extension RimeApi {
    private static var _shared: RimeApi?
    private static var listener = RimeApiListener()
    static var stateChangeCallbacks: [RimeApiListener.StateChangeBlock] {
        get { listener.stateChangeCallbacks }
        set { listener.stateChangeCallbacks = newValue }
    }
    
    static var shared: RimeApi {
        if _shared == nil {
            atexit {
                RimeApi._shared = nil
            }
            _shared = RimeApi(bundle: Bundle(for: RimeApi.self))
        }
        return _shared!
    }
    
    static func closeShared() {
        DDLogInfo("Deinitializing RimeApi.")
        RimeApi._shared = nil
    }
}

// Proivde an app level initializer.
extension RimeApi {
    static func generateSchemaPatchFromSettings() {
        let userDataPath = DataFileManager.rimeUserDirectory
        let settings = Settings.cached
        var patchOptions: [RimeOption] = [.separateCandidates, .showFullCode]
        
        let jyutPingSchemaCustomPath = userDataPath + "/jyut6ping3.custom.yaml"
        let commonSchemaCustomPath = userDataPath + "/common.custom.yaml"
        try? FileManager.default.removeItem(atPath: jyutPingSchemaCustomPath)
        try? FileManager.default.removeItem(atPath: commonSchemaCustomPath)
        
        if !settings.rimeSettings.enableCompletion { patchOptions.append(.disableCompletion) }
        if settings.rimeSettings.enableCorrector { patchOptions.append(.enableCorrection) }
        if !settings.rimeSettings.enableSentence { patchOptions.append(.disableSentence) }
        if !settings.rimeSettings.enableLearning { patchOptions.append(.disableLearning) }
        
        if !patchOptions.isEmpty {
            let commonCustomPatch = patchHeader + patchOptions.map(\.configLine).joined()
            DDLogInfo("commonCustomPatch: \(commonCustomPatch)")
            do {
                try commonCustomPatch.write(toFile: commonSchemaCustomPath, atomically: true, encoding: .utf8)
            } catch {
                DDLogInfo("Failed to generate custom schema patch at \(commonSchemaCustomPath).")
            }
        }
        DDLogInfo("Rime patches generated.")
    }
    
    static func removeQuickStartFlagFile() {
        let userDataPath = DataFileManager.rimeUserDirectory
        try? FileManager.default.removeItem(atPath: "\(userDataPath)/\(RimeApi.quickStartFlagFileName()!)")
        DDLogInfo("Removed quick start flag file due to config change.")
    }
    
    convenience init(bundle: Bundle) {
        let schemaPath = DataFileManager.rimeSharedDirectory
        let userDataPath = DataFileManager.rimeUserDirectory
        
        if !DataFileManager.hasInstalled {
            fatalError("Data files not installed.")
        }
        
        // Generate schema patch.
        RimeApi.generateSchemaPatchFromSettings()
        
        DDLogInfo("Shared data path: \(schemaPath) User data path: \(userDataPath)")
        
        self.init(RimeApi.listener, sharedDataPath: schemaPath, userDataPath: userDataPath)
    }
    
    private static var appVersion: String {
        if let dict = Bundle.main.infoDictionary,
           let version = dict["CFBundleShortVersionString"] as? String,
           let bundleVersion = dict["CFBundleVersion"] as? String {
                return "\(version).\(bundleVersion)"
        }
        return "unknown"
    }
}

extension RimeApiState {
    public var debugDescription: String {
        description
    }
    
    public var description: String {
        switch self {
        case .uninitialized: return "uninitialized"
        case .deploying: return "deploying"
        case .failure: return "failure"
        case .succeeded: return "succeeded"
        @unknown default: return "unknown"
        }
    }
}

extension String.StringInterpolation {
    mutating func appendInterpolation(_ state: RimeApiState) {
        appendLiteral("\(state.description)")
    }
}
