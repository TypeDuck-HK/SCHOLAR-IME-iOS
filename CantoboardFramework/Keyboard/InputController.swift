//
//  InputHandler.swift
//  CantoboardFramework
//
//  Created by Alex Man on 1/26/21.
//

import Foundation
import UIKit

enum ContextualType: Equatable {
    case english, chinese, rime, url(isRimeComposing: Bool)
}

class InputController {
    private weak var keyboardViewController: KeyboardViewController?
    private let inputEngine: BilingualInputEngine
    
    private var lastKey: KeyboardAction?
    private var isHoldingShift = false
    
    private var hasInsertedAutoSpace = false
    private var shouldApplyChromeSearchBarHack = false, shouldSkipNextTextDidChange = false
    private var needClearInput = false
    
    private var prevTextBefore: String?
    
    private(set) var reverseLookupSchemaId: RimeSchemaId? {
        didSet {
            inputEngine.reverseLookupSchemaId = reverseLookupSchemaId
            keyboardView?.currentRimeSchemaId = reverseLookupSchemaId ?? .jyutping
        }
    }
    
    private(set) var candidateOrganizer = CandidateOrganizer()
    
    private var _keyboardType = KeyboardType.alphabetic(.lowercased)
    private var keyboardType: KeyboardType {
        get { _keyboardType }
        set {
            guard _keyboardType != newValue else { return }
            _keyboardType = newValue
            // TODO instead of setting a bunch of fields to keyboardView, cuasing unnecessary changes,
            // pass input controller to keyboardView. Then call a method to update keyboardView.
            keyboardView?.keyboardType = _keyboardType
        }
    }
    
    private var keyboardContextualType: ContextualType = .english {
        didSet {
            keyboardView?.keyboardContextualType = keyboardContextualType
        }
    }
    
    private var textDocumentProxy: UITextDocumentProxy? {
        keyboardViewController?.textDocumentProxy
    }
    
    private var keyboardView: KeyboardView? {
        keyboardViewController?.keyboardView
    }
    
    init(keyboardViewController: KeyboardViewController) {
        self.keyboardViewController = keyboardViewController
        inputEngine = BilingualInputEngine(textDocumentProxy: keyboardViewController.textDocumentProxy)
    }
    
    func textWillChange(_ textInput: UITextInput?) {
        prevTextBefore = textDocumentProxy?.documentContextBeforeInput
        // NSLog("textWillChange \(prevTextBefore)")
    }
    
    func textDidChange(_ textInput: UITextInput?) {
        // NSLog("textDidChange prevTextBefore \(prevTextBefore) documentContextBeforeInput \(textDocumentProxy?.documentContextBeforeInput)")
        shouldApplyChromeSearchBarHack = isTextChromeSearchBar()
        if prevTextBefore != textDocumentProxy?.documentContextBeforeInput && !shouldSkipNextTextDidChange {
            // clearState()
        } else if inputEngine.composition != nil, !shouldApplyChromeSearchBarHack {
            self.updateMarkedText()
        }
        
        shouldSkipNextTextDidChange = false
        
        updateContextualSuggestion()
    }
    
    private func updateContextualSuggestion() {
        checkAutoCap()
        refreshKeyboardContextualType()
        showAutoSuggestCandidates()
    }
    
    private func candidateSelected(_ choice: Int, isFromCandidateBar: Bool) {
        if let staticCandidateSource = candidateOrganizer.candidateSource as? AutoSuggestionCandidateSource {
            if let candidate = staticCandidateSource.candidates[choice] as? String {
                insertText(candidate, isFromCandidateBar: isFromCandidateBar)
            }
        } else if let commitedText = inputEngine.selectCandidate(choice) {
            insertText(commitedText, isFromCandidateBar: isFromCandidateBar)
        }
    }
    
    private func handleSpace() {
        guard let textDocumentProxy = textDocumentProxy else { return }
        
        let spaceOutputMode = Settings.cached.spaceOutputMode
        // If spaceOutputMode is input or there's no candidates, insert the raw English input string.
        if spaceOutputMode == .bestCandidate && candidateOrganizer.candidateSource is InputEngineCandidateSource,
           let bestCandidateIndex = candidateOrganizer.getCandidateIndex(indexPath: [0, 0]) {
            candidateSelected(bestCandidateIndex, isFromCandidateBar: false)
        } else {
            if !insertComposingText() {
                if !handleAutoSpace() {
                    textDocumentProxy.insertText(" ")
                }
            }
        }
    }
    
    func keyPressed(_ action: KeyboardAction) {
        guard let textDocumentProxy = textDocumentProxy else { return }
        guard RimeApi.shared.state == .succeeded else {
            // If RimeEngine isn't ready, disable the keyboard.
            NSLog("Disabling keyboard")
            keyboardView?.isEnabled = false
            return
        }
        
        defer {
            lastKey = action
        }
        
        needClearInput = false
        let isComposing = inputEngine.isComposing
        
        switch action {
        case .moveCursorForward, .moveCursorBackward:
            moveCursor(offset: action == .moveCursorBackward ? -1 : 1)
        case .character(let c):
            guard let char = c.first else { return }
            if !isComposing && shouldApplyChromeSearchBarHack {
                self.shouldSkipNextTextDidChange = true
                textDocumentProxy.insertText("")
            }
            let shouldFeedCharToInputEngine = char.isASCII && char.isLetter && c.count == 1
            if !(shouldFeedCharToInputEngine && inputEngine.processChar(char)) {
                if !insertComposingText(appendBy: c) {
                    insertText(c)
                }
            }
            if !isHoldingShift && keyboardType == .some(.alphabetic(.uppercased)) {
                keyboardType = .alphabetic(.lowercased)
            }
        case .rime(let rc):
            guard isComposing || rc == .sym else { return }
            _ = inputEngine.processRimeChar(rc.rawValue)
        case .space:
            handleSpace()
        case .newLine:
            if !insertComposingText(shouldDisableSmartSpace: true) {
                insertText("\n")
            }
        case .backspace, .deleteWord, .deleteWordSwipe:
            if reverseLookupSchemaId != nil && !isComposing {
                reverseLookupSchemaId = nil
            } else if isComposing {
                if action == .deleteWordSwipe {
                    needClearInput = true
                } else {
                    _ = inputEngine.processBackspace()
                }
            } else {
                switch action {
                case .backspace: textDocumentProxy.deleteBackward()
                case .deleteWord: textDocumentProxy.deleteBackwardWord()
                case .deleteWordSwipe:
                    if textDocumentProxy.documentContextBeforeInput?.last?.isASCII ?? false {
                        textDocumentProxy.deleteBackwardWord()
                    } else {
                        textDocumentProxy.deleteBackward()
                    }
                default:()
                }
            }
        case .emoji(let e):
            AudioFeedbackProvider.play(keyboardAction: action)
            if !insertComposingText(appendBy: e, shouldDisableSmartSpace: true) {
                textDocumentProxy.insertText(e)
            }
        case .shiftDown:
            isHoldingShift = true
            keyboardType = .alphabetic(.uppercased)
            return
        case .shiftUp:
            keyboardType = .alphabetic(.lowercased)
            isHoldingShift = false
            return
        case .shiftRelax:
            isHoldingShift = false
            return
        case .keyboardType(let type):
            keyboardType = type
            self.checkAutoCap()
            return
        case .setCharForm(let cs):
            var settings = Settings.cached
            settings.charForm = cs
            Settings.save(settings)
            inputEngine.refreshChineseCharForm()
            return
        case .refreshMarkedText: ()
        case .reverseLookup(let schemaId):
            reverseLookupSchemaId = schemaId
            clearInput(needResetSchema: false)
            return
        case .selectCandidate(let choice):
            candidateSelected(choice, isFromCandidateBar: true)
        default: ()
        }
        if needClearInput {
            clearInput()
        } else {
            updateInputState()
        }
    }
    
    private func isTextChromeSearchBar() -> Bool {
        guard let textFieldType = textDocumentProxy?.keyboardType else { return false }
        //print("isTextChromeSearchBar", textFieldType, textDocumentProxy.documentContextBeforeInput)
        return textFieldType == UIKeyboardType.webSearch
    }
    
    private func shouldApplyAutoCap() -> Bool {
        guard let textDocumentProxy = textDocumentProxy else { return false }
        //print("autocapitalizationType", textDocumentProxy.autocapitalizationType?.rawValue)
        if textDocumentProxy.autocapitalizationType == .some(.none) { return false }
        if inputEngine.composition?.text != nil { return false }
        
        // There are three cases we should apply auto cap:
        // - First char in the doc. nil
        // - Half shaped: e.g. ". " -> "<sym><space>"
        // - Full shaped: e.g. "。" -> "<sym>"
        let lastChar = textDocumentProxy.documentContextBeforeInput?.last
        let lastSymbol = textDocumentProxy.documentContextBeforeInput?.last(where: { $0 != " " })
        // NSLog("documentContextBeforeInput \(textDocumentProxy.documentContextBeforeInput) \(lastChar)")
        let isFirstCharInDoc = lastChar == nil || lastChar == "\n"
        let isHalfShapedCase = (lastChar?.isWhitespace ?? false && lastSymbol?.isHalfShapeTerminalPunctuation ?? false)
        let isFullShapedCase = lastChar?.isFullShapeTerminalPunctuation ?? false
        return isFirstCharInDoc || isHalfShapedCase || isFullShapedCase
    }
    
    private func checkAutoCap() {
        guard Settings.cached.isAutoCapEnabled && !isHoldingShift && reverseLookupSchemaId == nil &&
              (keyboardType == .alphabetic(.lowercased) || keyboardType == .alphabetic(.uppercased))
            else { return }
        keyboardType = shouldApplyAutoCap() ? .alphabetic(.uppercased) : .alphabetic(.lowercased)
    }
    
    private func clearInput(needResetSchema: Bool = true) {
        inputEngine.clearInput()
        updateInputState()
        if needResetSchema { reverseLookupSchemaId = nil }
    }
    
    func clearState() {
        // clearInput()
        hasInsertedAutoSpace = false
        shouldSkipNextTextDidChange = false
        lastKey = nil
        prevTextBefore = nil
    }
    
    private var hasMarkedText = false
    
    private func insertText(_ text: String, isFromCandidateBar: Bool = false) {
        guard !text.isEmpty else { return }
        guard let textDocumentProxy = textDocumentProxy else { return }
        let isNewLine = text == "\n"
        
        if shouldRemoveSmartSpace(text) {
            // If there's marked text, we've to make an extra call to deleteBackward to remove the marked text before we could delete the space.
            if hasMarkedText {
                textDocumentProxy.deleteBackward()
                // If we hit this case, textDocumentProxy.documentContextBeforeInput will no longer be in-sync with the text of the document,
                // It will contain part of the marked text which the doc doesn't contain.
                // Fortunately, contextual update looks at the tail of the documentContextBeforeInput only.
                // After inserting text, the inaccurate text doesn't affect the contextual update.
            }
            textDocumentProxy.deleteBackward()
            hasInsertedAutoSpace = false
        }
        
        let textToBeInserted: String
        
        if shouldInsertSmartSpace(text, isFromCandidateBar, isNewLine) {
            textToBeInserted = text + " "
            hasInsertedAutoSpace = true
        } else {
            textToBeInserted = text
        }
        
        if hasMarkedText {
            textDocumentProxy.setMarkedText("", selectedRange: NSRange(location: 0, length: 0))
            textDocumentProxy.unmarkText()
            hasMarkedText = false
        }
        
        textDocumentProxy.insertText(textToBeInserted)
        
        needClearInput = true
        
        // NSLog("insertText() hasInsertedAutoSpace \(hasInsertedAutoSpace) isLastInsertedTextFromCandidate \(isLastInsertedTextFromCandidate)")
    }
    
    private func updateInputState() {
        updateMarkedText()
        
        if inputEngine.isComposing {
            let candidates = self.inputEngine.getCandidates()
            candidateOrganizer.candidateSource = InputEngineCandidateSource(
                candidates: candidates,
                requestMoreCandidate: { [weak self] in
                    return self?.inputEngine.loadMoreCandidates() ?? false
                },
                getCandidateSource: { [weak self] index in
                    return self?.inputEngine.getCandidateSource(index)
                },
                getCandidateComment: { [weak self] index in
                    return self?.inputEngine.getCandidateComment(index)
                })
        } else {
            candidateOrganizer.candidateSource = nil
        }
        updateContextualSuggestion()
    }
    
    private func updateMarkedText() {
        switch candidateOrganizer.inputMode {
        case .chinese: setMarkedText(inputEngine.rimeComposition)
        case .english: setMarkedText(inputEngine.englishComposition)
        case .mixed: setMarkedText(inputEngine.composition)
        }
    }
    
    private func setMarkedText(_ composition: Composition?) {
        guard let textDocumentProxy = textDocumentProxy else { return }
        
        guard var text = composition?.text, !text.isEmpty else {
            if hasMarkedText {
                textDocumentProxy.setMarkedText("", selectedRange: NSRange(location: 0, length: 0))
                textDocumentProxy.unmarkText()
                hasMarkedText = false
            }
            return
        }
        var caretPosition = composition?.caretIndex ?? NSNotFound
        
        let inputType = textDocumentProxy.keyboardType ?? .default
        let shouldStripSpace = inputType == .URL || inputType == .emailAddress || inputType == .webSearch
        if shouldStripSpace {
            let spaceStrippedSpace = text.filter { $0 != " " }
            caretPosition -= text.prefix(caretPosition).reduce(0, { $0 + ($1 != " " ? 0 : 1) })
            text = spaceStrippedSpace
        }
        
        textDocumentProxy.setMarkedText(text, selectedRange: NSRange(location: caretPosition, length: 0))
        hasMarkedText = true
    }
    
    private var shouldEnableSmartInput: Bool {
        guard let textFieldType = textDocumentProxy?.keyboardType else { return true }
        return textFieldType != .URL &&
            textFieldType != .asciiCapableNumberPad &&
            textFieldType != .decimalPad &&
            textFieldType != .emailAddress &&
            textFieldType != .namePhonePad &&
            textFieldType != .numberPad &&
            textFieldType != .numbersAndPunctuation &&
            textFieldType != .phonePad;
    }
    
    private func insertComposingText(appendBy: String? = nil, shouldDisableSmartSpace: Bool = false) -> Bool {
        if var composingText = inputEngine.composition?.text.filter({ $0 != " " && !$0.isRimeSpecialChar }),
           !composingText.isEmpty {
            EnglishInputEngine.userDictionary.learnWordIfNeeded(word: composingText)
            if let c = appendBy { composingText.append(c) }
            insertText(composingText)
            return true
        }
        return false
    }
    
    private func moveCursor(offset: Int) {
        if inputEngine.isComposing {
            _ = inputEngine.moveCaret(offset: offset)
        } else {
            self.textDocumentProxy?.adjustTextPosition(byCharacterOffset: offset)
        }
    }
    
    private func handleAutoSpace() -> Bool {
        guard let textDocumentProxy = textDocumentProxy else { return false }
        
        // NSLog("handleAutoSpace() hasInsertedAutoSpace \(hasInsertedAutoSpace) isLastInsertedTextFromCandidate \(isLastInsertedTextFromCandidate)")
        
        if hasInsertedAutoSpace, case .selectCandidate = lastKey {
            // Mimic iOS stock behaviour. Swallow the space tap.
            return true
        } else if hasInsertedAutoSpace || lastKey == .space,
           let last2CharsInDoc = textDocumentProxy.documentContextBeforeInput?.suffix(2),
           Settings.cached.isSmartFullStopEnabled &&
           (last2CharsInDoc.first ?? " ").couldBeFollowedBySmartSpace && last2CharsInDoc.last?.isWhitespace ?? false {
            // Translate double space tap into ". "
            textDocumentProxy.deleteBackward()
            if keyboardContextualType == .chinese {
                textDocumentProxy.insertText("。")
                hasInsertedAutoSpace = false
            } else {
                textDocumentProxy.insertText(". ")
                hasInsertedAutoSpace = true
            }
            return true
        }
        return false
    }
    
    private func shouldRemoveSmartSpace(_ textBeingInserted: String) -> Bool {
        guard
            // If we are inserting newline in Google Chrome address bar, do not remove smart space
            !(isTextChromeSearchBar() && textBeingInserted == "\n"),
            let textDocumentProxy = textDocumentProxy else { return false }
        
        if let last2CharsInDoc = textDocumentProxy.documentContextBeforeInput?.suffix(2),
            hasInsertedAutoSpace && last2CharsInDoc.last?.isWhitespace ?? false {
            // Remove leading smart space if:
            // English" "(中/.)
            if (last2CharsInDoc.first?.isEnglishLetter ?? false) && textBeingInserted.first!.isChineseChar ||
               (last2CharsInDoc.first?.isLetter ?? false) && textBeingInserted.first!.isPunctuation ||
                textBeingInserted == "\n" {
                // For some reason deleteBackward() does nothing unless it's wrapped in an main async block.
                NSLog("Should remove smart space. last2CharsInDoc '\(last2CharsInDoc)'")
                return true
            }
        }
        return false
    }
    
    private func shouldInsertSmartSpace(_ insertingText: String, _ isFromCandidateBar: Bool, _ isNewLine: Bool) -> Bool {
        guard shouldEnableSmartInput && !isNewLine,
              let textDocumentProxy = textDocumentProxy,
              let lastChar = insertingText.last else { return false }
        
        // If we are typing a url or just sent combo text like .com, do not insert smart space.
        if case .url = keyboardContextualType, insertingText.contains(".") { return false }
        
        // If the user is typing something like a url, do not insert smart space.
        let lastSpaceIndex = textDocumentProxy.documentContextBeforeInput?.lastIndex(where: { $0.isWhitespace })
        let lastDotIndex = textDocumentProxy.documentContextBeforeInput?.lastIndex(of: ".")
        
        guard lastDotIndex == nil ||
              // Scan the text before input from the end, if we hit a dot before hitting a space, do not insert smart space.
              lastSpaceIndex != nil && textDocumentProxy.documentContextBeforeInput?.distance(from: lastDotIndex!, to: lastSpaceIndex!) ?? 0 >= 0 else {
            // NSLog("Guessing user is typing url \(textDocumentProxy.documentContextBeforeInput)")
            return false
        }
        
        
        let nextChar = textDocumentProxy.documentContextAfterInput?.first
        // Insert space after english letters and [.,;], and if the input is followed by an English letter.
        // If the input isnt from the candidate bar and there are chars following, do not insert space.
        let isTextFromCandidateBarOrCommitingAtTheEnd = isFromCandidateBar || nextChar == nil
        let isInsertingEnglishWordBeforeEnglish = lastChar.isEnglishLetter && (nextChar?.isEnglishLetter ?? true)
        return isTextFromCandidateBarOrCommitingAtTheEnd && isInsertingEnglishWordBeforeEnglish
    }
    
    private func refreshKeyboardContextualType() {
        guard let textDocumentProxy = textDocumentProxy else { return }
        
        if textDocumentProxy.keyboardType == .some(.URL) || textDocumentProxy.keyboardType == .some(.webSearch) {
            keyboardContextualType = .url(isRimeComposing: inputEngine.composition?.text != nil)
        } else if inputEngine.composition?.text != nil {
            keyboardContextualType = .rime
        } else {
            let symbolShape = Settings.cached.symbolShape
            if symbolShape == .smart {
                // Default to English.
                guard let lastChar = textDocumentProxy.documentContextBeforeInput?.last(where: { !$0.isWhitespace }) else {
                    self.keyboardContextualType = .english
                    return
                }
                // If the last char is Chinese, change contextual type to Chinese.
                if lastChar.isChineseChar {
                    self.keyboardContextualType = .chinese
                } else {
                    self.keyboardContextualType = .english
                }
            } else {
                self.keyboardContextualType = symbolShape == .half ? .english : .chinese
            }
        }
    }
    
    private static let halfWidthPunctuationCandidateSource = AutoSuggestionCandidateSource([".", ",", "?", "!", "。", "，", "？", "！"])
    private static let fullWidthPunctuationCandidateSource = AutoSuggestionCandidateSource(["。", "，", "？", "！", ".", ",", "?", "!"])
    
    private static let halfWidthDigitCandidateSource = AutoSuggestionCandidateSource(["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"])
    private static let fullWidthArabicDigitCandidateSource = AutoSuggestionCandidateSource(["０", "１", "２", "３", "４", "５", "６", "７", "８", "９"])
    private static let fullWidthLowerDigitCandidateSource = AutoSuggestionCandidateSource(["一", "二", "三", "四", "五", "六", "七", "八", "九", "十", "零", "廿", "百", "千", "萬", "億"])
    private static let fullWidthUpperDigitCandidateSource = AutoSuggestionCandidateSource(["零", "壹", "貳", "叄", "肆", "伍", "陸", "柒", "捌", "玖", "拾", "佰", "仟", "萬", "億"])
    
    private func showAutoSuggestCandidates() {
        guard let keyboardView = keyboardView, candidateOrganizer.candidateSource == nil else { return }
        
        let textAfterInput = textDocumentProxy?.documentContextAfterInput ?? ""
        let textBeforeInput = textDocumentProxy?.documentContextBeforeInput ?? ""
        
        guard let lastCharBefore = textBeforeInput.last else {
            candidateOrganizer.candidateSource = nil
            return
        }
        
        switch keyboardView.keyboardContextualType {
        case .english where !lastCharBefore.isNumber && textAfterInput.isEmpty:
            candidateOrganizer.candidateSource = InputController.halfWidthPunctuationCandidateSource
        case .chinese where !lastCharBefore.isNumber && textAfterInput.isEmpty:
            candidateOrganizer.candidateSource = InputController.fullWidthPunctuationCandidateSource
        default:
            if lastCharBefore.isNumber {
                if lastCharBefore.isASCII {
                    candidateOrganizer.candidateSource = InputController.halfWidthDigitCandidateSource
                } else {
                    switch lastCharBefore {
                    case "０", "１", "２", "３", "４", "５", "６", "７", "８", "９":
                        candidateOrganizer.candidateSource = InputController.fullWidthArabicDigitCandidateSource
                    case "一", "二", "三", "四", "五", "六", "七", "八", "九", "十", "零", "廿", "百", "千", "萬", "億":
                        candidateOrganizer.candidateSource = InputController.fullWidthLowerDigitCandidateSource
                    case "壹", "貳", "叄", "肆", "伍", "陸", "柒", "捌", "玖", "拾", "佰", "仟":
                        candidateOrganizer.candidateSource = InputController.fullWidthUpperDigitCandidateSource
                    default: candidateOrganizer.candidateSource = nil
                    }
                }
            }
        }
    }
}
