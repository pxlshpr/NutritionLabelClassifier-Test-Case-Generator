import SwiftUI
import NutritionLabelClassifier

extension ListView {
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
    var headerExpectationsSection: some View {
        if classifierController.shouldShowHeaderExpectations {
            Section("Column Header Expectations") {
                ForEach(classifierController.headerExpectations, id: \.self) { expectation in
                    cell(for: expectation)
                }
                .onDelete(perform: classifierController.deleteHeaderExpectation)
                if classifierController.unusedHeaderAttributes.count > 0 {
                    Menu {
                        ForEach(classifierController.unusedHeaderAttributes, id: \.self) { attribute in
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
