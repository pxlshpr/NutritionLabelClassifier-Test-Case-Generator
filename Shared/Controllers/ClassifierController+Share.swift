import TabularData
import NutritionLabelClassifier
import Foundation

extension ClassifierController {
    func shareTextCase() {
        /// Create the `DataFrame`s for the `recognizedText`s (used as input by the test suite)
        let recognizedTextsWithLCDataFrame = recognizedTextsWithLC.dataFrame
        let recognizedTextsWithoutLCDataFrame = recognizedTextsWithoutLC.dataFrame

        /// Create the `DataFrame` for the expectations
        let expectationsDataFrame = expectationsDataFrame()

        /// Write the `DataFrame`'s as `csv` files, and the image as a `jpeg`, and compress them all into a `zip`
        
        /// Ask the user where they would like to share it to
        let recognizedTextsWithLCUrl = URL.documents.appendingPathComponent("100.csv")
        let recognizedTextsWithoutLCUrl = URL.documents.appendingPathComponent("100-without_language_correction.csv")
        let expectationsUrl = URL.documents.appendingPathComponent("100-nutrients.csv")
        
        do {
            try expectationsDataFrame.writeCSV(to: expectationsUrl)
            try recognizedTextsWithLCDataFrame.writeCSV(to: recognizedTextsWithLCUrl)
            try recognizedTextsWithoutLCDataFrame.writeCSV(to: recognizedTextsWithoutLCUrl)
            print("Wrote to: \(expectationsUrl)")
        } catch {
            print("Couldn't write DataFrame: \(error)")
        }
    }
    
    func expectationsDataFrame() -> DataFrame {
        /// Create the `DataFrame`
        var dataFrame = DataFrame()
        
        var attributeCells: [String] = []
        var value1Cells: [String?] = []
        var value2Cells: [String?] = []
        var doubleCells: [String?] = []
        var stringCells: [String?] = []
        
        /// Add each output element marked as `valid`
        if let rows = classifierOutput?.nutrients.rows {
            for row in rows {
                guard outputAttributeStatuses[row.attribute] == .valid else {
                    continue
                }
                attributeCells.append(row.attribute.rawValue)
                value1Cells.append(row.value1?.description)
                value2Cells.append(row.value2?.description)
                doubleCells.append(nil)
                stringCells.append(nil)
            }
        }
        
        /// Add all the added expectations
        for expectation in expectations {
            attributeCells.append(expectation.attribute.rawValue)
            value1Cells.append(expectation.value1?.description)
            value2Cells.append(expectation.value2?.description)
            doubleCells.append(expectation.double?.clean)
            stringCells.append(expectation.string)
        }

        dataFrame.append(column: Column(name: "attributeString", contents: attributeCells))
        dataFrame.append(column: Column(name: "value1String", contents: value1Cells))
        dataFrame.append(column: Column(name: "value2String", contents: value2Cells))
        dataFrame.append(column: Column(name: "double", contents: doubleCells))
        dataFrame.append(column: Column(name: "string", contents: stringCells))
        
        return dataFrame
    }
}
