import SwiftUI
import NutritionLabelClassifier

struct Expectation {
    let attribute: Attribute
    let value1: Value?
    let value2: Value?
    let double: Double?
    let string: String?
    let unit: NutritionUnit?
    
    init(attribute: Attribute, value1: Value? = nil, value2: Value? = nil, double: Double? = nil, string: String? = nil, unit: NutritionUnit? = nil) {
        self.attribute = attribute
        self.value1 = value1
        self.value2 = value2
        self.double = double
        self.string = string
        self.unit = unit
    }
}

extension Expectation: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(attribute)
        hasher.combine(value1)
        hasher.combine(value2)
        hasher.combine(double)
        hasher.combine(string)
        hasher.combine(unit)
    }
}

extension ClassifierController {
    var servingExpectations: [Expectation] {
        expectations.filter { $0.attribute.isServingAttribute }
    }
    
    var nutrientExpectations: [Expectation] {
        expectations.filter { $0.attribute.isNutrientAttribute }
    }
    
    var columnHeaderExpectations: [Expectation] {
        expectations.filter { $0.attribute.isColumnAttribute }
    }
}

extension Expectation {
    var valueDescription: String {
        var description: String = ""
        if value1 != nil || value2 != nil {
            description = "\(value1?.description ?? "") | \(value2?.description ?? "")"
        }
        return description
    }
}

extension ListView {
    var expectationsList: some View {
        List {
            servingExpectationsSection
            columnHeaderExpectationsSection
            nutrientExpectationsSection
        }
        .listStyle(.plain)
    }

    func cell(for expectation: Expectation) -> some View {
        HStack {
            Text(expectation.attribute.description)
                .foregroundColor(.secondary)
            Spacer()
            Text(expectation.valueDescription)
        }
    }
    
    @ViewBuilder
    var servingExpectationsSection: some View {
        if classifierController.hasMissingServingAttributes {
            Section("Serving Expectations") {
                ForEach(classifierController.servingExpectations, id: \.self) { expectation in
                    cell(for: expectation)
                }
                Menu {
                    ForEach(Attribute.allCases.filter { $0.isServingAttribute }, id: \.self) { attribute in
                        Button(attribute.description) {
                            newAttribute = attribute
                        }
                    }
                } label: {
                    Label("Add Serving Expectation", systemImage: "plus")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.accentColor)
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(BorderlessButtonStyle())
            }
        }
    }
    
    @ViewBuilder
    var columnHeaderExpectationsSection: some View {
        if !classifierController.hasBothColumnHeaders {
            Section("Column Header Expectations") {
                ForEach(classifierController.columnHeaderExpectations, id: \.self) { expectation in
                    cell(for: expectation)
                }
                Menu {
                    ForEach(Attribute.allCases.filter { $0.isColumnAttribute }, id: \.self) { attribute in
                        Button(attribute.description) {
                            newAttribute = attribute
                        }
                    }
                } label: {
                    Label("Add Column Header Expectation", systemImage: "plus")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.accentColor)
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(BorderlessButtonStyle())
            }
        }
    }

    @ViewBuilder
    var nutrientExpectationsSection: some View {
        if classifierController.hasMissingNutrients {
            Section("Nutrient Expectations") {
                ForEach(classifierController.nutrientExpectations, id: \.self) { expectation in
                    cell(for: expectation)
                }
                Menu {
                    ForEach(classifierController.missingNutrients, id: \.self) { attribute in
                        Button(attribute.description) {
                            newAttribute = attribute
                        }
                    }
                } label: {
                    Label("Add Nutrient Expectation", systemImage: "plus")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.accentColor)
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(BorderlessButtonStyle())
            }
        }
    }
}
