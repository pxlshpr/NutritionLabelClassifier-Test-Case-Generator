import UIKit

/// Value in range 0...100 %
typealias Percentage = Float

enum CompareError: Error {
    case unableToGetUIImageFromData
    case unableToGetCGImageFromData
    case unableToGetColorSpaceFromCGImage
    case imagesHasDifferentSizes
    case unableToInitializeContext
}

// See: https://github.com/facebookarchive/ios-snapshot-test-case/blob/master/FBSnapshotTestCase/Categories/UIImage%2BCompare.m
func compareImageData(tolerance: Percentage, expected: Data, observed: Data) throws -> Bool {
    guard let expectedUIImage = UIImage(data: expected), let observedUIImage = UIImage(data: observed) else {
        throw CompareError.unableToGetUIImageFromData
    }
    guard let expectedCGImage = expectedUIImage.cgImage, let observedCGImage = observedUIImage.cgImage else {
        throw CompareError.unableToGetCGImageFromData
    }
    guard let expectedColorSpace = expectedCGImage.colorSpace, let observedColorSpace = observedCGImage.colorSpace else {
        throw CompareError.unableToGetColorSpaceFromCGImage
    }
    if expectedCGImage.width != observedCGImage.width || expectedCGImage.height != observedCGImage.height {
        throw CompareError.imagesHasDifferentSizes
    }
    let imageSize = CGSize(width: expectedCGImage.width, height: expectedCGImage.height)
    let numberOfPixels = Int(imageSize.width * imageSize.height)

    // Checking that our `UInt32` buffer has same number of bytes as image has.
    let bytesPerRow = min(expectedCGImage.bytesPerRow, observedCGImage.bytesPerRow)
    assert(MemoryLayout<UInt32>.stride == bytesPerRow / Int(imageSize.width))

    let expectedPixels = UnsafeMutablePointer<UInt32>.allocate(capacity: numberOfPixels)
    let observedPixels = UnsafeMutablePointer<UInt32>.allocate(capacity: numberOfPixels)

    let expectedPixelsRaw = UnsafeMutableRawPointer(expectedPixels)
    let observedPixelsRaw = UnsafeMutableRawPointer(observedPixels)

    let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
    guard let expectedContext = CGContext(data: expectedPixelsRaw, width: Int(imageSize.width), height: Int(imageSize.height),
                                          bitsPerComponent: expectedCGImage.bitsPerComponent, bytesPerRow: bytesPerRow,
                                          space: expectedColorSpace, bitmapInfo: bitmapInfo.rawValue) else {
        expectedPixels.deallocate()
        observedPixels.deallocate()
        throw CompareError.unableToInitializeContext
    }
    guard let observedContext = CGContext(data: observedPixelsRaw, width: Int(imageSize.width), height: Int(imageSize.height),
                                          bitsPerComponent: observedCGImage.bitsPerComponent, bytesPerRow: bytesPerRow,
                                          space: observedColorSpace, bitmapInfo: bitmapInfo.rawValue) else {
        expectedPixels.deallocate()
        observedPixels.deallocate()
        throw CompareError.unableToInitializeContext
    }

    expectedContext.draw(expectedCGImage, in: CGRect(origin: .zero, size: imageSize))
    observedContext.draw(observedCGImage, in: CGRect(origin: .zero, size: imageSize))

    let expectedBuffer = UnsafeBufferPointer(start: expectedPixels, count: numberOfPixels)
    let observedBuffer = UnsafeBufferPointer(start: observedPixels, count: numberOfPixels)

    var isEqual = true
    if tolerance == 0 {
        isEqual = expectedBuffer.elementsEqual(observedBuffer)
    } else {
        // Go through each pixel in turn and see if it is different
        var numDiffPixels = 0
        for pixel in 0 ..< numberOfPixels where expectedBuffer[pixel] != observedBuffer[pixel] {
            // If this pixel is different, increment the pixel diff count and see if we have hit our limit.
            numDiffPixels += 1
            let percentage = 100 * Float(numDiffPixels) / Float(numberOfPixels)
            if percentage > tolerance {
                isEqual = false
                break
            }
        }
    }

    expectedPixels.deallocate()
    observedPixels.deallocate()

    return isEqual
}
