import SwiftUI
import NutritionLabelClassifier

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
    
    var unusedServingAttributes: [Attribute] {
        Attribute.allCases.filter { $0.isServingAttribute && shouldAllowAdding($0) }
    }
    
    var unusedNutrientAttributes: [Attribute] {
        Attribute.allCases.filter { $0.isNutrientAttribute && shouldAllowAdding($0) }
    }
    
    var unusedColumnHeaderAttributes: [Attribute] {
        Attribute.allCases.filter { $0.isColumnAttribute && shouldAllowAdding($0) }
    }
}

extension ClassifierController {
    func deleteServingExpectation(at offsets: IndexSet) {
        guard let index = offsets.first else { return }
        delete(expectation: servingExpectations[index])
    }

    func deleteNutrientExpectation(at offsets: IndexSet) {
        guard let index = offsets.first else { return }
        delete(expectation: nutrientExpectations[index])
    }

    func deleteColumnHeaderExpectation(at offsets: IndexSet) {
        guard let index = offsets.first else { return }
        delete(expectation: columnHeaderExpectations[index])
    }

    func delete(expectation: Expectation) {
        guard let index = expectations.firstIndex(where: { $0.attribute == expectation.attribute }) else { return }
        withAnimation {
            let _ = expectations.remove(at: index)
        }
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
        if classifierController.unusedServingAttributes.count > 0 {
            Section("Serving Expectations") {
                ForEach(classifierController.servingExpectations, id: \.self) { expectation in
                    cell(for: expectation)
                }
                .onDelete(perform: classifierController.deleteServingExpectation)
                Menu {
                    ForEach(classifierController.unusedServingAttributes, id: \.self) { attribute in
                        Button(attribute.description) {
                            newAttribute = attribute
                        }
                    }
                } label: {
                    Label("Add Serving Expectation", systemImage: "plus")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.accentColor)
                }
//                .frame(maxWidth: .infinity)
                .buttonStyle(BorderlessButtonStyle())
            }
        }
    }
    
    @ViewBuilder
    var columnHeaderExpectationsSection: some View {
        if classifierController.unusedColumnHeaderAttributes.count > 0 {
            Section("Column Header Expectations") {
                ForEach(classifierController.columnHeaderExpectations, id: \.self) { expectation in
                    cell(for: expectation)
                }
                .onDelete(perform: classifierController.deleteColumnHeaderExpectation)
                Menu {
                    ForEach(classifierController.unusedColumnHeaderAttributes, id: \.self) { attribute in
                        Button(attribute.description) {
                            newAttribute = attribute
                        }
                    }
                } label: {
                    Label("Add Column Header Expectation", systemImage: "plus")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.accentColor)
                }
//                .frame(maxWidth: .infinity)
                .buttonStyle(BorderlessButtonStyle())
            }
        }
    }

    @ViewBuilder
    var nutrientExpectationsSection: some View {
        if classifierController.unusedNutrientAttributes.count > 0 {
            Section("Nutrient Expectations") {
                ForEach(classifierController.nutrientExpectations, id: \.self) { expectation in
                    cell(for: expectation)
                }
                .onDelete(perform: classifierController.deleteNutrientExpectation)
                Menu {
                    ForEach(classifierController.unusedNutrientAttributes, id: \.self) { attribute in
                        Button(attribute.description) {
                            newAttribute = attribute
                        }
                    }
                } label: {
                    Label("Add Nutrient Expectation", systemImage: "plus")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.accentColor)
                }
//                .frame(maxWidth: .infinity)
                .buttonStyle(BorderlessButtonStyle())
            }
        }
    }
}
