/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2021 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import XCTest
@testable import Markdown

class MathTests: XCTestCase {
    func testInlineMathManual() {
        let math = InlineMath("a^2 + b^2 = c^2")
        XCTAssertEqual(math.math, "a^2 + b^2 = c^2")
        XCTAssertEqual(math.plainText, "$a^2 + b^2 = c^2$")
    }

    func testBlockMathManual() {
        let math = BlockMath("E = mc^2")
        XCTAssertEqual(math.math, "E = mc^2")
    }

    func testInlineMathParsing() {
        let source = "$a^2$"
        let document = Document(parsing: source, options: [.parseMath])
        
        var visitor = MathFinder()
        visitor.visit(document)
        
        XCTAssertEqual(visitor.foundInline.count, 1)
        XCTAssertEqual(visitor.foundInline.first, "a^2")
    }
    
    func testBlockMathParsing() {
        let source = """
        $$
        a^2
        $$
        """
        let document = Document(parsing: source, options: [.parseMath])
        
        var visitor = MathFinder()
        visitor.visit(document)
        
        XCTAssertEqual(visitor.foundBlock.count, 1)
        XCTAssertTrue(visitor.foundBlock.first?.contains("a^2") ?? false)
    }
}

struct MathFinder: MarkupWalker {
    var foundInline: [String] = []
    var foundBlock: [String] = []

    mutating func visitInlineMath(_ inlineMath: InlineMath) {
        foundInline.append(inlineMath.math)
    }
    
    mutating func visitBlockMath(_ blockMath: BlockMath) {
        foundBlock.append(blockMath.math)
    }
}
