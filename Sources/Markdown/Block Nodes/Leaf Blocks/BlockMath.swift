/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2021 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

/// A block math element.
public struct BlockMath: BlockMarkup {
    public var _data: _MarkupData
    init(_ raw: RawMarkup) throws {
        guard case .blockMath = raw.data else {
            throw RawMarkup.Error.concreteConversionError(from: raw, to: BlockMath.self)
        }
        let absoluteRaw = AbsoluteRawMarkup(markup: raw, metadata: MarkupMetadata(id: .newRoot(), indexInParent: 0))
        self.init(_MarkupData(absoluteRaw))
    }

    init(_ data: _MarkupData) {
        self._data = data
    }
}

// MARK: - Public API

public extension BlockMath {
    /// Create a block math element with raw `math`.
    init(_ math: String) {
        try! self.init(RawMarkup.blockMath(parsedRange: nil, math: math))
    }

    /// The raw text representing the math of this block.
    var math: String {
        get {
            guard case let .blockMath(math) = _data.raw.markup.data else {
                fatalError("\(self) markup wrapped unexpected \(_data.raw)")
            }
            return math
        }
        set {
            _data = _data.replacingSelf(.blockMath(parsedRange: nil, math: newValue))
        }
    }

    // MARK: Visitation

    func accept<V: MarkupVisitor>(_ visitor: inout V) -> V.Result {
        return visitor.visitBlockMath(self)
    }
}
