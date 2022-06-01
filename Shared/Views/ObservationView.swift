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

struct ObservationView: View {
    
    @Environment(\.dismiss) var dismiss
    
    @State var observation: Observation
        
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
                Text(observation.attribute.description)
            }
            if let value1 = observation.value1 {
                HStack {
                    Text("Value 1").foregroundColor(.secondary)
                    Spacer()
                    Text(value1.description)
                }
            }
            if let value2 = observation.value2 {
                HStack {
                    Text("Value 2").foregroundColor(.secondary)
                    Spacer()
                    Text(value2.description)
                }
            }
            if let double = observation.double {
                HStack {
                    Text("Double").foregroundColor(.secondary)
                    Spacer()
                    Text(double.clean)
                }
            }
            if let string = observation.string {
                HStack {
                    Text("String").foregroundColor(.secondary)
                    Spacer()
                    Text(string)
                }
            }
            if let unit = observation.unit {
                HStack {
                    Text("Unit").foregroundColor(.secondary)
                    Spacer()
                    Text(unit.description)
                }
            }
            if let headerType = observation.headerType {
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
                moveToNextObservation()
            } label: {
                Image(systemName: "chevron.right")
            }
            .disabled(nextObservation == nil)
        }
    }
    
    func moveToNextObservation() {
        guard let nextObservation = nextObservation else { return }
        observation = nextObservation
        ClassifierController.shared.focus(on: observation)
    }
    
    func moveToPreviousObservation() {
        guard let previousObservation = previousObservation else { return }
        observation = previousObservation
        ClassifierController.shared.focus(on: observation)
    }
    
    var nextObservation: Observation? {
        guard let index = observationIndex, index < observations.count - 1 else {
            return nil
        }
        return observations[index + 1]
    }

    var previousObservation: Observation? {
        guard let index = observationIndex, index > 0 else {
            return nil
        }
        return observations[index - 1]
    }
    
    var observations: [Observation] {
        ClassifierController.shared.observations
    }
    
    var observationIndex: Int? {
        ClassifierController.shared.observations.firstIndex(where: {
            $0.attribute == observation.attribute
        })
    }
    
    var navigationLeadingToolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarLeading) {
            Button {
                moveToPreviousObservation()
            } label: {
                Image(systemName: "chevron.left")
            }
            .disabled(previousObservation == nil)
        }
    }
    
    func moveToNextRowOrDismiss() {
        if nextObservation != nil {
            moveToNextObservation()
        } else {
            ClassifierController.shared.resignBoxFocus()
            dismiss()
        }
    }
    
    var bottomToolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .bottomBar) {
            Button {
                guard let index = ClassifierController.shared.observations.firstIndex(where: { $0.attribute == observation.attribute}) else {
                    return
                }
                ClassifierController.shared.observations[index].status = .invalid
                ClassifierController.shared.observations[index].boxes.forEach { $0.status = .invalid }

                observation.status = .invalid
                moveToNextRowOrDismiss()
            } label: {
                Image(systemName: "xmark")
                    .foregroundColor(.red)
            }
            Spacer()
            Button {
                guard let index = ClassifierController.shared.observations.firstIndex(where: { $0.attribute == observation.attribute}) else {
                    return
                }
                ClassifierController.shared.observations[index].status = .valid
                ClassifierController.shared.observations[index].boxes.forEach { $0.status = .valid }

                observation.status = .valid
                moveToNextRowOrDismiss()
            } label: {
                Image(systemName: "checkmark")
                    .foregroundColor(.green)
            }
        }
    }    
}
