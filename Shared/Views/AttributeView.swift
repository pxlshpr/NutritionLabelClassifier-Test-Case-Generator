import SwiftUI
import NutritionLabelClassifier

extension Output {
    func doubleFor(_ attribute: Attribute) -> Double? {
        switch attribute {
        case .servingAmount:
            return serving?.amount
        case .servingEquivalentAmount:
            return serving?.equivalentSize?.amount
        case .servingsPerContainerAmount:
            return serving?.perContainer?.amount
        default:
            return nil
        }
    }
}
struct AttributeView: View {
    
    @Environment(\.dismiss) var dismiss
    
//    @State var row: Output.Nutrients.Row
    
    @State var attribute: Attribute
    @State var value1: Value?
    @State var value2: Value?
    @State var double: Double?
    @State var string: String?
    @State var unit: NutritionUnit?
    @State var headerType: HeaderType?

    init(attribute: Attribute) {
        _attribute = State(initialValue: attribute)
        
        guard let output = ClassifierController.shared.classifierOutput else {
            _value1 = State(initialValue: nil)
            _value2 = State(initialValue: nil)
            _double = State(initialValue: nil)
            _string = State(initialValue: nil)
            _unit = State(initialValue: nil)
            _headerType = State(initialValue: nil)
            return
        }
        let value1 = output.nutrients.rows.first(where: { $0.attribute == attribute })?.value1
        let value2 = output.nutrients.rows.first(where: { $0.attribute == attribute })?.value2
        let double: Double?
        if attribute.expectsDouble {
            double = output.doubleFor(attribute)
        } else {
            double = nil
        }

        _value1 = State(initialValue: value1)
        _value2 = State(initialValue: value2)
        _double = State(initialValue: double)
        _string = State(initialValue: string)
        _unit = State(initialValue: unit)
        _headerType = State(initialValue: headerType)
    }
    
    var body: some View {
        NavigationView {
            Form {
                outputSection
            }
            .navigationTitle("Attribute")
            .navigationBarTitleDisplayMode(.large)
//            .toolbar { navigationToolbarContent }
            .toolbar { navigationTrailingToolbarContent }
            .toolbar { navigationLeadingToolbarContent }
            .toolbar { bottomToolbarContent }
        }
        .onDisappear {
            ClassifierController.shared.resignBoxFocus()
        }
    }
    
    @ViewBuilder
    var outputSection: some View {
        Section {
            HStack {
                Text("Name").foregroundColor(.secondary)
                Spacer()
                Text(attribute.description)
            }
            if let value1 = value1 {
                HStack {
                    Text("Value 1").foregroundColor(.secondary)
                    Spacer()
                    Text(value1.description)
                }
            }
            if let value2 = value2 {
                HStack {
                    Text("Value 2").foregroundColor(.secondary)
                    Spacer()
                    Text(value2.description)
                }
            }
            if let double = double {
                HStack {
                    Text("Double").foregroundColor(.secondary)
                    Spacer()
                    Text(double.clean)
                }
            }
            if let string = string {
                HStack {
                    Text("String").foregroundColor(.secondary)
                    Spacer()
                    Text(string)
                }
            }
            if let unit = unit {
                HStack {
                    Text("Unit").foregroundColor(.secondary)
                    Spacer()
                    Text(unit.description)
                }
            }
            if let headerType = headerType {
                HStack {
                    Text("Column Header Type").foregroundColor(.secondary)
                    Spacer()
                    Text(headerType.description)
                }
            }
        }
    }
    
    var navigationTrailingToolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            Button {
                moveToNextRow()
            } label: {
                Image(systemName: "chevron.right")
            }
            .disabled(nextRow == nil)
        }
    }
    
    func moveToNextRow() {
//        guard let nextRow = nextRow else { return }
//        row = nextRow
//        if let box = nextRow.box {
//            ClassifierController.shared.focus(on: box)
//        }
    }
    
    func moveToPreviousRow() {
//        guard let previousRow = previousRow else { return }
//        row = previousRow
//        if let box = previousRow.box {
//            ClassifierController.shared.focus(on: box)
//        }
    }
    
    var nextRow: Output.Nutrients.Row? {
        guard let output = ClassifierController.shared.classifierOutput,
              let rowIndex = rowIndex,
              rowIndex < output.nutrients.rows.count - 1
        else {
            return nil
        }
        return output.nutrients.rows[rowIndex + 1]
    }
    
    var rowIndex: Int? {
//        guard let output = ClassifierController.shared.classifierOutput,
//              let index = output.nutrients.rows.firstIndex(where: {
//                  //                  $0.attributeId == row.attributeId
//                  $0.attribute == row.attribute
//              })
//        else {
            return nil
//        }
//        return index
    }
    
    var previousRow: Output.Nutrients.Row? {
        guard let output = ClassifierController.shared.classifierOutput,
              let rowIndex = rowIndex,
              rowIndex > 0
        else {
            return nil
        }
        return output.nutrients.rows[rowIndex - 1]
    }
    
    var navigationLeadingToolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarLeading) {
            Button {
                moveToPreviousRow()
            } label: {
                Image(systemName: "chevron.left")
            }
            .disabled(previousRow == nil)
        }
    }
    
    func moveToNextRowOrDismiss() {
        if nextRow != nil {
            moveToNextRow()
        } else {
            ClassifierController.shared.resignBoxFocus()
            dismiss()
        }
    }
    
    var bottomToolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .bottomBar) {
            Button {
                ClassifierController.shared.outputAttributeStatuses[attribute] = .invalid
                moveToNextRowOrDismiss()
            } label: {
                Image(systemName: "xmark")
                    .foregroundColor(.red)
            }
            Spacer()
            Button {
                ClassifierController.shared.outputAttributeStatuses[attribute] = .valid
                moveToNextRowOrDismiss()
            } label: {
                Image(systemName: "checkmark")
                    .foregroundColor(.green)
            }
        }
    }    
}
