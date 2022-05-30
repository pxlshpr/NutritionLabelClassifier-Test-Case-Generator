import SwiftUI
import NutritionLabelClassifier

extension ClassifierController {
    var servingExpectations: [Expectation] {
        expectations.filter { $0.attribute.isServingAttribute }
    }
    
    var nutrientExpectations: [Expectation] {
        expectations.filter { $0.attribute.isNutrientAttribute }
    }
    
    var headerExpectations: [Expectation] {
        expectations.filter { $0.attribute.isHeaderAttribute }
    }
    
    var unusedServingAttributes: [Attribute] {
        Attribute.allCases.filter { $0.isServingAttribute && shouldAllowAdding($0) }
    }
    
    var unusedNutrientAttributes: [Attribute] {
        Attribute.allCases.filter { $0.isNutrientAttribute && shouldAllowAdding($0) }
    }
    
    var unusedColumnHeaderAttributes: [Attribute] {
        Attribute.allCases.filter {
            $0.isHeaderAttribute
            && shouldAllowAdding($0)
        }
    }
    
    var shouldShowServingExpectations: Bool {
        unusedServingAttributes.count > 0 || servingExpectations.count > 0
    }
    
    var shouldShowColumnHeaderExpectations: Bool {
        unusedColumnHeaderAttributes.count > 0 || headerExpectations.count > 0
    }
    
    var shouldShowNutrientExpectations: Bool {
        unusedNutrientAttributes.count > 0 || nutrientExpectations.count > 0
    }
    
    var availableColumnHeaderTypes: [HeaderType] {
        HeaderType.allCases.filter { type in
            guard let output = classifierOutput else {
                return false
            }
            if let header1Type = output.nutrients.header1Type, type == header1Type {
                return false
            }
            if let header2Type = output.nutrients.header2Type, type == header2Type {
                return false
            }
            return !expectations.contains(where: {
                if let headerType = $0.headerType, type == headerType {
                    return true
                }
                return false
            })
        }
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
        delete(expectation: headerExpectations[index])
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
                .multilineTextAlignment(.trailing)
        }
    }
    
    @ViewBuilder
    var servingExpectationsSection: some View {
        if classifierController.shouldShowServingExpectations {
            Section("Serving Expectations") {
                ForEach(classifierController.servingExpectations, id: \.self) { expectation in
                    cell(for: expectation)
                }
                .onDelete(perform: classifierController.deleteServingExpectation)
                if classifierController.unusedNutrientAttributes.count > 0 {
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
                    .buttonStyle(BorderlessButtonStyle())
                }
            }
        }
    }
    
    @ViewBuilder
    var columnHeaderExpectationsSection: some View {
        if classifierController.shouldShowColumnHeaderExpectations {
            Section("Column Header Expectations") {
                ForEach(classifierController.headerExpectations, id: \.self) { expectation in
                    cell(for: expectation)
                }
                .onDelete(perform: classifierController.deleteColumnHeaderExpectation)
                if classifierController.unusedColumnHeaderAttributes.count > 0 {
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
                    .buttonStyle(BorderlessButtonStyle())
                }
            }
        }
    }

    @ViewBuilder
    var nutrientExpectationsSection: some View {
        if classifierController.shouldShowNutrientExpectations {
            Section("Nutrient Expectations") {
                ForEach(classifierController.nutrientExpectations, id: \.self) { expectation in
                    cell(for: expectation)
                }
                .onDelete(perform: classifierController.deleteNutrientExpectation)
                if classifierController.unusedNutrientAttributes.count > 0 {
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
                    .buttonStyle(BorderlessButtonStyle())
                }
            }
        }
    }
}
