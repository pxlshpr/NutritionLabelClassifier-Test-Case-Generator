import SwiftUI
import NutritionLabelClassifier

extension ListView {
    var expectationsList: some View {
        List {
            servingExpectationsSection
            columnHeaderExpectationsSection
            nutrientExpectationsSection
        }
        .listStyle(.plain)
    }

    @ViewBuilder
    var servingExpectationsSection: some View {
        if classifierController.hasMissingServingAttributes {
            Section("Serving Expectations") {
                //TODO: Filter out the serving expectations only, create helpers in classifierController
                ForEach(Array(classifierController.expectedAttributes.keys), id: \.self) { attribute in
                    Text(attribute.description)
                }
                Menu {
                    ForEach(Attribute.allCases.filter { $0.isServingAttribute }, id: \.self) { attribute in
                        Button(attribute.description) {
                            //TODO: Show form that gets user to input a value before adding it
                            //TODO: Show this animation once returning
                            withAnimation {
                                classifierController.add(attribute)
                            }
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
                Menu {
                    ForEach(Attribute.allCases.filter { $0.isColumnAttribute }, id: \.self) { attribute in
                        Button(attribute.description) {
                            classifierController.add(attribute)
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
                Menu {
                    ForEach(classifierController.missingNutrients, id: \.self) { attribute in
                        Button(attribute.description) {
                            classifierController.add(attribute)
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
