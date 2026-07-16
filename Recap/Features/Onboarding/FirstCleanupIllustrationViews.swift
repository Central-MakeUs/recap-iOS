import SwiftUI

struct CleanupCardStack: View {
    private let rotations: [Double] = [-8, -2, 6, 12]
    private let xOffsets: [CGFloat] = [-76, -26, 44, 96]
    private let yOffsets: [CGFloat] = [4, 0, 8, 18]

    var body: some View {
        ZStack {
            ForEach(0..<4, id: \.self) { index in
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.recapControlFill)
                    .frame(width: index == 1 ? 118 : 112, height: index == 1 ? 151 : 146)
                    .rotationEffect(.degrees(rotations[index]))
                    .offset(x: xOffsets[index], y: yOffsets[index])
            }
        }
    }
}
