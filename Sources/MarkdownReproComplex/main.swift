import Foundation
import Markdown

func test(text: String, label: String) {
    print("--- \(label) ---")
    print("Input (escaped): \(text.replacingOccurrences(of: "\n", with: "\\n"))")
    let doc = Document(parsing: text)
    print("Debug Description:")
    print(doc.debugDescription())
    print("Formatted (escaped): \(doc.format().replacingOccurrences(of: "\n", with: "\\n"))")
    print()
}

test(text: "\n\nLine 1", label: "Leading Newlines")
test(text: "Line 1\n\n", label: "Trailing Newlines")
test(text: "Line 1\n\n\nLine 4", label: "Multiple Gaps")
test(text: "# Heading\n\nParagraph", label: "Heading to Paragraph")
test(text: "- Item 1\n\n- Item 2", label: "List Items")
test(text: "> Quote\n\n> Quote 2", label: "BlockQuotes")
test(text: "```swift\n\nCode\n\n```", label: "CodeBlock spacing")
