import SwiftUI

extension SearchHighlightedString {
    func styledText(defaultColor: Color) -> Text {
        var attributedString = AttributedString()

        for segment in segments {
            var part = AttributedString(segment.text)
            part.foregroundColor = segment.isHighlighted
                ? Color.recapBlue300
                : defaultColor
            attributedString.append(part)
        }

        return Text(attributedString)
    }
}
