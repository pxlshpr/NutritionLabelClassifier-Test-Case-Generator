import SwiftUI

struct BoxCell: View {
    @Binding var box: Box
    
    var body: some View {
        HStack {
            Text(box.cellTitle)
            Spacer()
            Image(systemName: "\(box.status.systemImage).square")
                .foregroundColor(box.status.color)
//                .renderingMode(.original)
        }
    }
}
