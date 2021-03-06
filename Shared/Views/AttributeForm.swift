import SwiftUI
import NutritionLabelClassifier
import SwiftUISugar

struct AttributeForm: View {
    
    @Environment(\.dismiss) var dismiss
    
    @State var attribute: Attribute

    @State var headerType: SelectionOption
    @State var headerName: String = ""
    @State var showColumnNameField: Bool = false

    @State var nutritionUnit: SelectionOption = NutritionUnit.g
    @State var string: String = ""
    @State var doubleString: String = ""

    @State var value1String: String = ""
    @State var value1Unit: SelectionOption = NutritionUnit.g
    @State var value2String: String = ""
    @State var value2Unit: SelectionOption = NutritionUnit.g

    init(attribute: Attribute) {
        _attribute = State(initialValue: attribute)
        if let type = ClassifierController.shared.availableHeaderTypes.first {
            _headerType = State(initialValue: type)
            _showColumnNameField = State(initialValue: type != .per100g)
        } else {
            _headerType = State(initialValue: HeaderType.per100g)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack {
                        Text("Attribute")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(attribute.description)
                    }
                }
                fieldSection
            }
            .navigationTitle("Add Expectation")
            .toolbar { bottomToolbar }
        }
    }
    
    var bottomToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .bottomBar) {
            Button("Save") {
                saveAndDismiss()
            }
            .disabled(!isValid)
        }
    }
    
    func saveAndDismiss() {
        let expectation: Expectation?
        if attribute.isNutrientAttribute {
            let value1, value2: Value?
            if !value1String.isEmpty {
                guard let amount = Double(value1String),
                      let unit = value1Unit as? NutritionUnit
                else { return }
                value1 = Value(amount: amount, unit: unit)
            } else {
                value1 = nil
            }

            if !value2String.isEmpty {
                guard let amount = Double(value2String),
                      let unit = value2Unit as? NutritionUnit
                else { return }
                value2 = Value(amount: amount, unit: unit)
            } else {
                value2 = nil
            }

            expectation = Expectation(attribute: attribute, value1: value1, value2: value2)
        }
        else if attribute.expectsHeaderType {
            guard let type = headerType as? HeaderType else { return }
            expectation = Expectation(attribute: attribute,
                                      headerType: type)
        }
        else if attribute.expectsDouble {
            guard let double = Double(doubleString) else { return }
            expectation = Expectation(attribute: attribute, double: double)
        }
        else if attribute.expectsString {
            expectation = Expectation(attribute: attribute, string: string)
        }
        else if attribute.expectsNutritionUnit {
            guard let unit = nutritionUnit as? NutritionUnit else { return }
            expectation = Expectation(attribute: attribute, unit: unit)
        }
        else {
            expectation = nil
        }
        
        guard let expectation = expectation else {
            return
        }
        
        ClassifierController.shared.expectations.append(expectation)
        dismiss()
    }
    
    var isValid: Bool {
        if attribute.isNutrientAttribute {
            var isValid: Bool = !value1String.isEmpty || !value2String.isEmpty
            if !value1String.isEmpty {
                isValid = isValid && Double(value1String) != nil
            }
            if !value2String.isEmpty {
                isValid = isValid && Double(value2String) != nil
            }
            return isValid
        } else if attribute.isHeaderAttribute {
            return true
        } else if attribute.expectsDouble {
            return !doubleString.isEmpty && Double(doubleString) != nil
        } else if attribute.expectsString {
            return !string.isEmpty
        } else if attribute.expectsNutritionUnit {
            return true
        }
        return false
    }
    
    @ViewBuilder
    var fieldSection: some View {
        if attribute.isNutrientAttribute {
            valueFieldsSection
        }
        else if attribute.expectsHeaderType {
            columnFieldSection
        }
        else if attribute.expectsDouble {
            doubleFieldSection
        }
        else if attribute.expectsString {
            stringFieldSection
        }
        else if attribute.expectsNutritionUnit {
            nutritionUnitSection
        }
    }
    
    var valueFieldsSection: some View {
        Section {
            Field(label: "Value 1",
                  value: $value1String,
                  units: .constant(NutritionUnit.allCases),
                  selectedUnit: $value1Unit,
                  keyboardType: .decimalPad,
                  selectorStyle: .prominent,
                  contentProvider: self
            ) { selectedOption in
            }
            Field(label: "Value 2",
                  value: $value2String,
                  units: .constant(NutritionUnit.allCases),
                  selectedUnit: $value2Unit,
                  keyboardType: .decimalPad,
                  selectorStyle: .prominent,
                  contentProvider: self
            ) { selectedOption in
            }

        }
    }
    
    var columnFieldSection: some View {
        Section {
            Field(label: "Type",
                  units: .constant(ClassifierController.shared.availableHeaderTypes),
                  selectedUnit: $headerType,
                  selectorStyle: .prominent,
                  contentProvider: self)
            { selection in
//                guard let type = selection as? HeaderType else { return }
//                showColumnNameField = type != .per100g
            }
        }
    }

    var doubleFieldSection: some View {
        Section {
            Section {
                Field(label: "Number",
                      value: $doubleString,
                      keyboardType: .decimalPad
                )
            }
        }
    }

    var stringFieldSection: some View {
        Section {
            Field(label: "Text", value: $string)
                .autocapitalization(.none)
        }
    }
    
    var nutritionUnitSection: some View {
        Section {
            Field(label: "Unit",
                  units: .constant(NutritionUnit.allCases),
                  selectedUnit: $nutritionUnit,
                  selectorStyle: .prominent,
                  contentProvider: self)
            { selection in
                //                guard let unit = selection as? VolumeTeaspoonUserUnit else { return }
                //                Store.setDefaultVolumeTeaspoonUnit(unit)
                //                Haptics.feedback(style: .medium)
            }
        }
    }

}

extension AttributeForm: FieldContentProvider {
    func menuTitle(for option: SelectionOption, isPlural: Bool) -> String? {
        if let option = option as? CustomStringConvertible {
            return option.description
        } else {
            return option.optionId
        }
    }
    
    func title(for option: SelectionOption, isPlural: Bool) -> String? {
        if let option = option as? CustomStringConvertible {
            return option.description
        } else {
            return option.optionId
        }
    }
}

extension HeaderType: SelectionOption {
    public var optionId: String {
        "\(rawValue)"
    }
}
