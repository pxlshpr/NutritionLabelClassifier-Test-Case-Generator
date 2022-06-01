import TabularData
import NutritionLabelClassifier
import Foundation
import ZIPFoundation
import Zip
import UIKit

extension Data {
    func isEqualToImage(_ image: UIImage) -> Bool {
//        return jpegData(compressionQuality: 0.8) == image.jpegData(compressionQuality: 0.8)
//        return pngData() == image.pngData()
        do {
            return try compareImageData(tolerance: 80, expected: self, observed: image.jpegData(compressionQuality: 0.8)!)
        } catch {
            print("Error: \(error)")
            return false
        }
    }
}

extension ClassifierController {
    
    
    var testDataUrl: URL {
        URL.documents.appendingPathComponent("Test Data", isDirectory: true)
    }
    
    var  imagesDirectoryUrl: URL {
        testDataUrl.appendingPathComponent("Images", isDirectory: true)
    }
    
    var testCasesDirectoryUrl: URL {
        testDataUrl.appendingPathComponent("Test Cases", isDirectory: true)
    }
    
    var testCasesWithLanguageCorrectionDirectoryUrl: URL {
        testCasesDirectoryUrl
            .appendingPathComponent("With Language Correction", isDirectory: true)
    }
    
    var testCasesWithoutLanguageCorrectionDirectoryUrl: URL {
        testCasesDirectoryUrl
        .appendingPathComponent("Without Language Correction", isDirectory: true)
    }
    
    var expectationsDirectoryUrl: URL {
        testDataUrl.appendingPathComponent("Expectations", isDirectory: true)
    }
    
    
    func deleteTestDataFolder() {
        do {
            try FileManager.default.removeItem(at: testDataUrl)
        } catch {
            print("Error deleting Test Data Folder: \(error)")
        }
    }
    func appendTestCaseToExistingFile(at url: URL) {

        deleteTestDataFolder()
        
        do {
            /// Unzip existing file
            let destinationUrl = URL.documents.appendingPathComponent("Test Data", isDirectory: true)
            try Zip.unzipFile(url, destination: destinationUrl, overwrite: true, password: nil, progress: { (progress) -> () in
                print(progress)
            })
            print("Unzipped to: \(destinationUrl)")
        } catch {
            print("Error unzipping file: \(error)")
        }
        
        /// Now zip up the folders once again and give it to the user to save it elsewhere
        writeTestCaseFiles()
        createZipFile()
    }


    func createTestDataFolderStructure() {
        /// Clear Documents folder
        deleteTestDataFolder()

        do {
            /// Create Folders
            for url in [testDataUrl,
                        imagesDirectoryUrl,
                        testCasesDirectoryUrl,
                        testCasesWithLanguageCorrectionDirectoryUrl,
                        testCasesWithoutLanguageCorrectionDirectoryUrl,
                        expectationsDirectoryUrl] {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            }
        } catch {
            print("Error creating Test Data Folders")
        }
    }
    
    var testDataFileExists: Bool {
        var isDir: ObjCBool = true
        return FileManager.default.fileExists(atPath: testDataUrl.path, isDirectory: &isDir)
    }
    
    func createNewTestCaseFile() {
        if testDataFileExists {
            appendTestCaseToExistingFile(at: testDataZipFileUrl)
        } else {
            createTestDataFolderStructure()
            writeTestCaseFiles()
            createZipFile()
        }
    }
    
    func imageUrl(uuid: UUID) -> URL {
        imagesDirectoryUrl.appendingPathComponent("\(uuid).jpg")
    }
    
    func writeTestCaseFiles() {
        /// Create the `DataFrame`s for the `recognizedText`s (used as input by the test suite)
        let recognizedTextsWithLCDataFrame = recognizedTextsWithLC.dataFrame
        let recognizedTextsWithoutLCDataFrame = recognizedTextsWithoutLC.dataFrame

        /// Create the `DataFrame` for the expectations
        let expectationsDataFrame = expectationsDataFrame()

        /// Write the `DataFrame`'s as `csv` files, and the image as a `jpeg`, and compress them all into a `zip`
        let uuid = UUID()
        let recognizedTextsWithLCUrl = testCasesWithLanguageCorrectionDirectoryUrl.appendingPathComponent("\(uuid).csv")
        let recognizedTextsWithoutLCUrl = testCasesWithoutLanguageCorrectionDirectoryUrl.appendingPathComponent("\(uuid).csv")
        let expectationsUrl = expectationsDirectoryUrl.appendingPathComponent("\(uuid).csv")

        do {
            guard let image = pickedImage, let imageData = image.jpegData(compressionQuality: 0.8) else {
                return
            }
            try imageData.write(to: imageUrl(uuid: uuid))
            
            try expectationsDataFrame.writeCSV(to: expectationsUrl)
            try recognizedTextsWithLCDataFrame.writeCSV(to: recognizedTextsWithLCUrl)
            try recognizedTextsWithoutLCDataFrame.writeCSV(to: recognizedTextsWithoutLCUrl)
            print("Wrote to: \(expectationsUrl)")
        } catch {
            print("Error creating Test Case File: \(error)")
        }
    }
    
    var testDataZipFileUrl: URL {
        URL.documents.appendingPathComponent("NutritionClassifier-Test_Data.zip")
    }
    
    func shareZipFile() {
        isPresentingFilePickerForCreatedFile = true
    }
    
    func createZipFile() {
        do {
            /// Delete the existing Zip file if it exists
            if FileManager.default.fileExists(atPath: testDataZipFileUrl.path) {
                try FileManager.default.removeItem(at: testDataZipFileUrl)
            }

            /// Create the Zip File
            try FileManager.default.zipItem(at: self.testDataUrl, to: self.testDataZipFileUrl, shouldKeepParent: false)

            print("Test Data File created at: \(testDataZipFileUrl.absoluteString)")
        } catch {
            print("Error deleting existing Zip file: \(error)")
        }
    }
    
    static var documentsContents: [URL] {
        do {
            return try FileManager.default.contentsOfDirectory(at: URL.documents, includingPropertiesForKeys: nil)
        } catch {
            print(error)
        }
        return []
    }

    
    static var backupFileName: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "H"
        let amPm = (Int(dateFormatter.string(from: Date())) ?? 0) < 12 ? "am" : "pm"
        dateFormatter.dateFormat = "E d-MMM-yy h.mm"
        return "NutritionClassifier-TestCases-\(dateFormatter.string(from: Date()))\(amPm)"
    }

    func observation(for attribute: Attribute) -> Observation? {
        observations.first(where: { $0.attribute == attribute })
    }
    
    func observationIsValid(for attribute: Attribute) -> Bool {
        guard let observation = observation(for: attribute) else { return false }
        return observation.status == .valid
    }
    
    var containsServingObservations: Bool {
        observations.contains {
            $0.attribute == .servingAmount
            || $0.attribute == .servingUnit
            || $0.attribute == .servingUnitSize
            || $0.attribute == .servingEquivalentAmount
            || $0.attribute == .servingsPerContainerAmount
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
                guard observation(for: row.attribute)?.status == .valid else {
                    continue
                }
//                guard outputAttributeStatuses[row.attribute] == .valid else {
//                    continue
//                }
                attributeCells.append(row.attribute.rawValue)
                value1Cells.append(row.value1?.description)
                value2Cells.append(row.value2?.description)
                doubleCells.append(nil)
                stringCells.append(nil)
            }
        }
        
        func addDouble(_ double: Double, for attribute: Attribute) {
            attributeCells.append(attribute.rawValue)
            value1Cells.append(nil)
            value2Cells.append(nil)
            doubleCells.append(double.clean)
            stringCells.append(nil)
        }

        func addString(_ string: String, for attribute: Attribute) {
            attributeCells.append(attribute.rawValue)
            value1Cells.append(nil)
            value2Cells.append(nil)
            doubleCells.append(nil)
            stringCells.append(string)
        }

        /// servingAmount
        if observationIsValid(for: .servingAmount), let double = classifierOutput?.serving?.amount {
            addDouble(double, for: .servingAmount)
        }

        /// servingUnit
        if observationIsValid(for: .servingUnit), let unit = classifierOutput?.serving?.unit {
            addString(unit.description, for: .servingUnit)
        }

        /// servingUnitSize
        if observationIsValid(for: .servingUnitSize), let string = classifierOutput?.serving?.unitName {
            addString(string, for: .servingUnitSize)
        }

        /// servingEquivalentAmount
        if observationIsValid(for: .servingEquivalentAmount), let double = classifierOutput?.serving?.equivalentSize?.amount {
            addDouble(double, for: .servingEquivalentAmount)
        }

        /// servingEquivalentUnit
        if observationIsValid(for: .servingEquivalentUnit), let unit = classifierOutput?.serving?.equivalentSize?.unit {
            addString(unit.description, for: .servingEquivalentUnit)
        }

        /// servingEquivalentUnitSize
        if observationIsValid(for: .servingEquivalentUnitSize), let double = classifierOutput?.serving?.equivalentSize?.unitName {
            addString(double, for: .servingEquivalentUnitSize)
        }

        /// servingsPerContainerAmount
        if observationIsValid(for: .servingsPerContainerAmount), let double = classifierOutput?.serving?.perContainer?.amount {
            addDouble(double, for: .servingsPerContainerAmount)
        }

        /// servingsPerContainerName
        if observationIsValid(for: .servingsPerContainerName), let string = classifierOutput?.serving?.perContainer?.name {
            addString(string, for: .servingsPerContainerName)
        }

        if observationIsValid(for: .headerType1), let type = classifierOutput?.nutrients.headerText1?.type {
            addString(type.rawValue, for: .headerType1)
//            addDouble(Double(type.rawValue), for: .headerType1)
        }
        if observationIsValid(for: .headerType2), let type = classifierOutput?.nutrients.headerText2?.type {
            addString(type.rawValue, for: .headerType2)
//            addDouble(Double(type.rawValue), for: .headerType2)
        }
        
        if let serving = classifierOutput?.nutrients.headerText1?.serving ?? classifierOutput?.nutrients.headerText2?.serving {
            if observationIsValid(for: .headerServingAmount), let amount = serving.amount {
                addDouble(amount, for: .headerServingAmount)
            }
            if observationIsValid(for: .headerServingUnit), let unit = serving.unit {
                addString(unit.description, for: .headerServingUnit)
            }
            if observationIsValid(for: .headerServingUnitSize), let unitName = serving.unitName {
                addString(unitName, for: .headerServingUnitSize)
            }
            
            if let equivalentSize = serving.equivalentSize {
                if observationIsValid(for: .headerServingEquivalentAmount) {
                    addDouble(equivalentSize.amount, for: .headerServingEquivalentAmount)
                }
                if observationIsValid(for: .headerServingEquivalentUnit), let unit = equivalentSize.unit {
                    addString(unit.description, for: .headerServingEquivalentUnit)
                }
                if observationIsValid(for: .headerServingEquivalentUnitSize), let unitName = equivalentSize.unitName {
                    addString(unitName, for: .headerServingEquivalentUnitSize)
                }
            }
        }
        
        func addValues(value1: Value? = nil, value2: Value? = nil, for attribute: Attribute) {
            attributeCells.append(attribute.rawValue)
            value1Cells.append(value1?.description)
            value2Cells.append(value2?.description)
            doubleCells.append(nil)
            stringCells.append(nil)
        }

        /// Add all the added expectations
        for expectation in expectations {
            
            if let headerType = expectation.headerType {
                addString(headerType.rawValue, for: expectation.attribute)
//                addDouble(Double(headerType.rawValue), for: expectation.attribute)
                continue
            }

            attributeCells.append(expectation.attribute.rawValue)
            value1Cells.append(expectation.value1?.description)
            value2Cells.append(expectation.value2?.description)
            doubleCells.append(expectation.double?.clean)
            if let unit = expectation.unit {
                stringCells.append(unit.description)
            } else {
                stringCells.append(expectation.string)
            }
        }

        dataFrame.append(column: Column(name: "attributeString", contents: attributeCells))
        dataFrame.append(column: Column(name: "value1String", contents: value1Cells))
        dataFrame.append(column: Column(name: "value2String", contents: value2Cells))
        dataFrame.append(column: Column(name: "double", contents: doubleCells))
        dataFrame.append(column: Column(name: "string", contents: stringCells))
        
        return dataFrame
    }
}
