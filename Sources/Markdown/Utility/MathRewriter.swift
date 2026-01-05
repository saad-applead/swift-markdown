/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2021 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import Foundation

/// A rewriter that detects and converts LaTeX math syntax into `InlineMath` and `BlockMath` nodes.
public struct MathRewriter: MarkupRewriter {
    
    public init() {}

    public mutating func visitDocument(_ document: Document) -> Markup? {
        let newChildren = processBlocks(document.children)
        return document.withUncheckedChildren(newChildren)
    }

    public mutating func visitBlockQuote(_ blockQuote: BlockQuote) -> Markup? {
        let newChildren = processBlocks(blockQuote.children)
        return blockQuote.withUncheckedChildren(newChildren)
    }

    public mutating func visitListItem(_ listItem: ListItem) -> Markup? {
        let newChildren = processBlocks(listItem.children)
        return listItem.withUncheckedChildren(newChildren)
    }

    public mutating func visitCustomBlock(_ customBlock: CustomBlock) -> Markup? {
        let newChildren = processBlocks(customBlock.children)
        return customBlock.withUncheckedChildren(newChildren)
    }

    public mutating func visitParagraph(_ paragraph: Paragraph) -> Markup? {
        let newInlines = processInlines(paragraph.children)
        return paragraph.withUncheckedChildren(newInlines)
    }
    
    public mutating func defaultVisit(_ markup: Markup) -> Markup? {
        let newChildren = markup.children.compactMap {
            return self.visit($0)
        }
        return markup.withUncheckedChildren(newChildren)
    }

    // MARK: - Processing

    private mutating func processBlocks(_ blocks: MarkupChildren) -> [Markup] {
        var result: [Markup] = []
        
        for block in blocks {
            if let paragraph = block as? Paragraph {
                let splitNodes = processParagraphForBlockMath(paragraph)
                for node in splitNodes {
                    if let rewrote = self.visit(node) {
                        result.append(rewrote)
                    }
                }
            } else {
                if let rewrote = self.visit(block) {
                    result.append(rewrote)
                }
            }
        }
        return result
    }

    private func processParagraphForBlockMath(_ paragraph: Paragraph) -> [Markup] {
        let text = paragraph.plainText
        let pattern = #"(?<!\\)(?:\$\$(.*?)(?<!\\)\$\$|\\\[(.*?)(?<!\\)\\\])"#
        let regex = try! NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators])
         
        let nsString = text as NSString
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
        
        if matches.isEmpty {
            return [paragraph]
        }
        
        var results: [Markup] = []
        var currentIndex = 0
        
        for match in matches {
            let start = match.range.location
            let end = match.range.location + match.range.length
            
            if start > currentIndex {
                let before = nsString.substring(with: NSRange(location: currentIndex, length: start - currentIndex))
                if !before.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    results.append(Paragraph(Text(before)))
                }
            }
            
            let mathRange = match.range(at: 1).location != NSNotFound ? match.range(at: 1) : match.range(at: 2)
            let mathContent = nsString.substring(with: mathRange)
            results.append(BlockMath(mathContent))
            
            currentIndex = end
        }
        
        if currentIndex < nsString.length {
            let after = nsString.substring(with: NSRange(location: currentIndex, length: nsString.length - currentIndex))
             if !after.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                results.append(Paragraph(Text(after)))
            }
        }
        
        return results
    }

    private mutating func processInlines(_ inlines: MarkupChildren) -> [Markup] {
        var newInlines: [Markup] = []
        var textBuffer: String = ""
        var nodesInBuffer: [Markup] = []
        
        // Use a closure that captures self as mutating if needed, but here we can just do it in-place or pass state.
        // Since we are in a mutating method, we can define a nested function.
        
        func flushBuffer(_ target: inout [Markup]) {
            if textBuffer.isEmpty {
                target.append(contentsOf: nodesInBuffer)
                nodesInBuffer = []
                return
            }
            let pattern = #"(?<!\\)(?:\$(.+?)(?<!\\)\$|\\\((.*?)(?<!\\)\\\))"#
            let regex = try! NSRegularExpression(pattern: pattern, options: [])
            let nsString = textBuffer as NSString
            let matches = regex.matches(in: textBuffer, options: [], range: NSRange(location: 0, length: nsString.length))
            
            if matches.isEmpty {
                target.append(Text(textBuffer))
            } else {
                var currentIndex = 0
                for match in matches {
                     let start = match.range.location
                     let end = match.range.location + match.range.length
                     
                     if start > currentIndex {
                         let before = nsString.substring(with: NSRange(location: currentIndex, length: start - currentIndex))
                         target.append(Text(before))
                     }
                     
                     let mathRange = match.range(at: 1).location != NSNotFound ? match.range(at: 1) : match.range(at: 2)
                     let mathContent = nsString.substring(with: mathRange)
                     target.append(InlineMath(mathContent))
                     
                     currentIndex = end
                }
                if currentIndex < nsString.length {
                    let after = nsString.substring(with: NSRange(location: currentIndex, length: nsString.length - currentIndex))
                    target.append(Text(after))
                }
            }
            
            textBuffer = ""
            nodesInBuffer = []
        }
        
        for child in inlines {
            if let text = child as? Text {
                textBuffer += text.string
                nodesInBuffer.append(child)
            } else if child is SoftBreak {
                textBuffer += "\n"
                nodesInBuffer.append(child)
            } else if child is LineBreak {
                textBuffer += "\n"
                nodesInBuffer.append(child)
            } else {
                flushBuffer(&newInlines)
                if let rewrote = self.visit(child) {
                    newInlines.append(rewrote)
                }
            }
        }
        flushBuffer(&newInlines)
        
        return newInlines
    }
}
