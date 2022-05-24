import Foundation

extension Notification.Name {
    static var resetZoomableScrollViewScale: Notification.Name { return .init("resetZoomableScrollViewScale") }
    static var scrollZoomableScrollViewToRect: Notification.Name { return .init("scrollZoomableScrollViewToRect") }
    
}

extension Notification {
    struct Keys {
        static let rect = "rect"
        static let boundingBox = "boundingBox"
        static let imageSize = "imageSize"
    }
}
