import SwiftUI

extension Color {
    var components: (red: Double, green: Double, blue: Double, opacity: Double) {
        let uiColor = UIColor(self)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return (red, green, blue, alpha)
    }
}

struct RadioButton<Option: Equatable>: View {
    public let label: String
    public let option: Option
    @Binding public var selectedOption: Option?
    
    var body: some View {
        HStack {
            Circle()
                .stroke(selectedOption == option ? Color.blue : Color.gray, lineWidth: 2)
                .background(Circle().fill(selectedOption == option ? Color.blue : Color.clear))
                .frame(width: 20, height: 20)
            Text(label)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            selectedOption = option
        }
    }
}
