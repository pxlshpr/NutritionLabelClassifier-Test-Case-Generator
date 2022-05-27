import SwiftUI
import NutritionLabelClassifier

struct OutputRow: View {
    
    @Environment(\.dismiss) var dismiss
    
    @State var row: Output.Nutrients.Row? = nil
    @State var expectedAttribute: Attribute? = nil
    @State var attributeChoices: [Attribute]? = nil

    var body: some View {
        NavigationView {
            Form {
                outputSection
                newAttributeSection
            }
            .navigationTitle(title)
            .toolbar { navigationTrailingToolbarContent }
            .toolbar { navigationLeadingToolbarContent }
            .toolbar { bottomToolbarContent }
        }
    }

    @ViewBuilder
    var newAttributeSection: some View {
        if row == nil {
            Section("Expected Attribute") {
                Text("let's do this")
            }
        }
    }
    
    @ViewBuilder
    var outputSection: some View {
        if let row = row {
            Section("Classifier Output") {
                HStack {
                    Text("Attribute")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(row.attribute.description)
                }
                if let value1 = row.value1 {
                    HStack {
                        Text("Value 1")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(value1.description)
                    }
                }
                if let value2 = row.value2 {
                    HStack {
                        Text("Value 2")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(value2.description)
                    }
                }
            }
        }
    }
    
    var title: String {
        if let attribute = row?.attribute {
            return attribute.description
        } else {
            return expectedAttribute?.description ?? "Select an Attribute"
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
        guard let nextRow = nextRow else { return }
        row = nextRow
        if let box = nextRow.box {
            ClassifierController.shared.focus(on: box)
        }
    }

    func moveToPreviousRow() {
        guard let previousRow = previousRow else { return }
        row = previousRow
        if let box = previousRow.box {
            ClassifierController.shared.focus(on: box)
        }
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
        guard let output = ClassifierController.shared.classifierOutput,
              let row = row,
              let index = output.nutrients.rows.firstIndex(where: { $0.attributeId == row.attributeId })
        else {
            return nil
        }
        return index
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
            dismiss()
        }
    }
    
    var bottomToolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .bottomBar) {
            Button {
                if let row = row {
                    ClassifierController.shared.attributeStatuses[row.attribute] = .valid
                }
                moveToNextRowOrDismiss()
            } label: {
                Image(systemName: "checkmark")
                    .foregroundColor(.green)
            }
            Spacer()
            Button {
                if let row = row {
                    ClassifierController.shared.attributeStatuses[row.attribute] = .invalid
                }
                moveToNextRowOrDismiss()
            } label: {
                Image(systemName: "xmark")
                    .foregroundColor(.red)
            }
        }
    }

}
