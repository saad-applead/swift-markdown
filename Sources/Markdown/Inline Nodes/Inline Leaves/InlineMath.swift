/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2021 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

/// An inline math markup element, representing a LaTeX math equation.
public struct InlineMath: RecurringInlineMarkup {
    public var _data: _MarkupData

    init(_ raw: RawMarkup) throws {
        guard case .inlineMath = raw.data else {
            throw RawMarkup.Error.concreteConversionError(from: raw, to: InlineMath.self)
        }
        let absoluteRaw = AbsoluteRawMarkup(markup: raw, metadata: MarkupMetadata(id: .newRoot(), indexInParent: 0))
        self.init(_MarkupData(absoluteRaw))
    }

    init(_ data: _MarkupData) {
        self._data = data
    }
}

// MARK: - Public API

public extension InlineMath {
    /// Create an inline math element from a string.
    init(_ math: String) {
        try! self.init(.inlineMath(parsedRange: nil, math: math))
    }

    /// The literal math content.
    var math: String {
        get {
            guard case let .inlineMath(math) = _data.raw.markup.data else {
                fatalError("\(self) markup wrapped unexpected \(_data.raw)")
            }
            return math
        }
        set {
            self._data = _data.replacingSelf(.inlineMath(parsedRange: nil, math: newValue))
        }
    }

    // MARK: PlainTextConvertibleMarkup

    var plainText: String {
        return "$\(math)$"
    }

    // MARK: Visitation

    func accept<V: MarkupVisitor>(_ visitor: inout V) -> V.Result {
        return visitor.visitInlineMath(self)
    }
}
