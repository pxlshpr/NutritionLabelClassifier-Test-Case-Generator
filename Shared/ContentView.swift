import SwiftUI
import SwiftUISugar
import VisionSugar
import NutritionLabelClassifier
import BottomSheet
import SwiftHaptics
import SwiftHaptics

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

enum BoxType: Int, CaseIterable {
    case unrecognized
    case attribute
    case value1
    case value2
    case value1value2
    case attributeValue1
    case attributeValue2
    case attributeValue1Value2
    
    var description: String {
        switch self {
        case .unrecognized:
            return "Unrecognized"
        case .attribute:
            return "Attribute"
        case .value1:
            return "Value 1"
        case .value2:
            return "Value 2"
        case .value1value2:
            return "Value 1 & 2"
        case .attributeValue1:
            return "Attribute & Value 1"
        case .attributeValue2:
            return "Attribute & Value 2"
        case .attributeValue1Value2:
            return "Attribute & Value 1 & 2"
        }
    }
}

enum BoxStatus: Int, CaseIterable {
    case unmarked
    case valid
    case invalid
    case irrelevant
    
    var description: String {
        switch self {
        case .unmarked:
            return "Unmarked"
        case .valid:
            return "Valid"
        case .invalid:
            return "Invalid"
        case .irrelevant:
            return "Irrelevant"
        }
    }
}
struct ContentView: View {

    @StateObject var vm: ViewModel = ViewModel()
    @State var isPresentingImagePicker = false
    @State var selectedBox: Box? = nil
    
    @State var isShowingList: Bool = false
    @State var isHidingBoxes: Bool = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if let image = vm.pickedImage {
                    GeometryReader { proxy in
                        ZoomableScrollView {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .overlay(content: {
                                    if !isHidingBoxes {
                                        boxesLayer
                                            .transition(.opacity)
                                    }
                                })
                        }
                        .onAppear {
                            vm.contentSize = proxy.size
                        }
                        .onChange(of: isShowingList) { newValue in
                            isHidingBoxes = true
                            NotificationCenter.default.post(name: .resetZoomableScrollViewScale, object: nil)
                            guard let image = vm.pickedImage else { return }
                            vm.contentSize = proxy.size
                            vm.calculateBoxes(in: image)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                withAnimation {
                                    isHidingBoxes = false
                                }
                            }
                        }
                    }
                    if isShowingList {
                        Group {
                            Divider()
                            list
                            .listStyle(.plain)
                        }
                        .transition(.opacity)
                    }
                } else {
                    Button("Choose Image") {
                        isPresentingImagePicker = true
                    }
                }
            }
            .navigationTitle("Test Case Generator")
            .navigationBarTitleDisplayMode(.inline)
        }
        .toolbar { bottomToolbarContent }
        .bottomSheet(item: $selectedBox,
                     prefersGrabberVisible: true,
                     prefersScrollingExpandsWhenScrolledToEdge: false)
        {
            BoxDetailsView(box: $selectedBox, vm: vm)
        }
        .sheet(isPresented: $isPresentingImagePicker) {
            imagePickerView
        }
        .onAppear {
            setImagePickerDelegate()
        }
    }
    
    var list: some View {
        List {
            ForEach(vm.filteredBoxes) { box in
                Button {
                    guard let image = vm.pickedImage else { return }
                    let userInfo: [String: Any] = [
                        Notification.Keys.boundingBox: box.boundingBox,
                        Notification.Keys.imageSize: image.size,
                    ]
                    NotificationCenter.default.post(name: .scrollZoomableScrollViewToRect, object: nil, userInfo: userInfo)
                    selectedBox = box
                } label: {
                    Text(box.recognizedTextWithLC?.string ?? "")
                }
            }
        }
    }
    
    var filtersMenu: some View {
        Menu {
            ForEach(BoxStatus.allCases, id: \.self) { status in
                if vm.boxes.contains(where: { $0.status == status }) {
                    Button {
                        if vm.statusFilter == status {
                            vm.statusFilter = nil
                        } else {
                            vm.statusFilter = status
                        }
                    } label: {
                        if vm.statusFilter == status {
                            Label(status.description, systemImage: "checkmark")
                        } else {
                            Text(status.description)
                        }
                    }
                }
            }
            Divider()
            ForEach(BoxType.allCases, id: \.self) { type in
                if vm.boxes.contains(where: { $0.type == type }) {
                    Button {
                        if vm.typeFilter == type {
                            vm.typeFilter = nil
                        } else {
                            vm.typeFilter = type
                        }
                    } label: {
                        if vm.typeFilter == type {
                            Label(type.description, systemImage: "checkmark")
                        } else {
                            Text(type.description)
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle\(vm.statusFilter != nil || vm.typeFilter != nil ? ".fill" : "")")
        }
    }
    
    var bottomToolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .bottomBar) {
            Button {
                vm.boxes = []
                vm.pickedImage = nil
                self.isPresentingImagePicker = true
            } label: {
                Image(systemName: "photo")
            }
            Button {
                withAnimation {
                    isShowingList.toggle()
                }
            } label: {
                Image(systemName: isShowingList ? "list.bullet.circle.fill" : "list.bullet.circle")
            }
            filtersMenu
            Spacer()
            Button {
                
            } label: {
                Image(systemName: "square.and.arrow.up")
            }
        }
    }
    
    @ViewBuilder
    var boxesLayer: some View {
        ZStack(alignment: .topLeading) {
            ForEach(vm.filteredBoxes, id: \.self) { box in
                Button {
                    Haptics.feedback(style: .rigid)
                    selectedBox = box
                } label: {
                    boxView(for: box)
                }
                .offset(x: box.rect.minX, y: box.rect.minY)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    func boxView(for box: Box) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Group {
                    if let selectedBox = selectedBox {
                        if box == selectedBox {
                            Color.yellow
                        } else {
                            Color.white
                        }
                    } else {
                        box.color
                    }
                }
                    .cornerRadius(6.0)
                    .opacity(0.4)
                    .frame(width: box.rect.width, height: box.rect.height)
                Spacer()
            }
            Spacer()
        }
    }
    
    @ViewBuilder
    var imagePickerView: some View {
        if let imagePickerDelegate = vm.imagePickerDelegate {
            ImagePickerView(filter: .any(of: [.images, .livePhotos]), selectionLimit: 1, delegate: imagePickerDelegate)
                .edgesIgnoringSafeArea(.bottom)
        }
    }
    
    func setImagePickerDelegate() {
        vm.imagePickerDelegate = ImagePickerView.Delegate(isPresented: $isPresentingImagePicker, didCancel: { (phPickerViewController) in
        }, didSelect: { (result) in
            guard let image = result.images.first else {
                fatalError("Couldn't get picked image")
            }
            vm.didPickImage(image)
        }, didFail: { (imagePickerError) in
            let phPickerViewController = imagePickerError.picker
            let error = imagePickerError.error
            print("Did Fail with error: \(error) in \(phPickerViewController)")
        })
    }
}

import SwiftUI
import CoreMedia

public struct ZoomableScrollView<Content: View>: UIViewRepresentable {
    private var content: Content
    
    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    public func makeUIView(context: Context) -> UIScrollView {
        // set up the UIScrollView
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator  // for viewForZooming(in:)
        scrollView.maximumZoomScale = 20
        scrollView.minimumZoomScale = 1
        scrollView.bouncesZoom = true
        
        // create a UIHostingController to hold our SwiftUI content
        let hostedView = context.coordinator.hostingController.view!
        hostedView.translatesAutoresizingMaskIntoConstraints = true
        hostedView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        hostedView.frame = scrollView.bounds
        scrollView.addSubview(hostedView)
        
        NotificationCenter.default.addObserver(forName: .resetZoomableScrollViewScale, object: nil, queue: .main) { notification in
            scrollView.setZoomScale(1, animated: true)
        }
        
        NotificationCenter.default.addObserver(forName: .scrollZoomableScrollViewToRect, object: nil, queue: .main) { notification in
            guard let boundingBox = notification.userInfo?[Notification.Keys.boundingBox] as? CGRect,
                  let imageSize = notification.userInfo?[Notification.Keys.imageSize] as? CGSize
            else {
                return
            }

            /// We have a `boundingBox` (y-value to bottom), and the original `imageSize`
            
            /// First determine the current size and x or y-padding of the image given the current contentSize of the `scrollView`
            let paddingLeft: CGFloat?
            let paddingTop: CGFloat?
            let width: CGFloat
            let height: CGFloat
            
//            let scrollViewSize: CGSize = CGSize(width: 428, height: 376)
            let scrollViewSize: CGSize = scrollView.frame.size
//            let scrollViewSize: CGSize
//            if let view = scrollView.delegate?.viewForZooming?(in: scrollView) {
//                scrollViewSize = view.frame.size
//            } else {
//                scrollViewSize = scrollView.contentSize
//            }
            
            if imageSize.widthToHeightRatio < scrollView.frame.size.widthToHeightRatio {
                /// height would be the same as `scrollView.frame.size.height`
                height = scrollViewSize.height
                width = (imageSize.width * height) / imageSize.height
                paddingLeft = (scrollViewSize.width - width) / 2.0
                paddingTop = nil
            } else {
                /// width would be the same as `scrollView.frame.size.width`
                width = scrollViewSize.width
                height = (imageSize.height * width) / imageSize.width
                paddingLeft = nil
                paddingTop = (scrollViewSize.height - height) / 2.0
            }

            let newImageSize = CGSize(width: width, height: height)

            if let paddingLeft = paddingLeft {
                print("paddingLeft: \(paddingLeft)")
            } else {
                print("paddingLeft: nil")
            }
            if let paddingTop = paddingTop {
                print("paddingTop: \(paddingTop)")
            } else {
                print("paddingTop: nil")
            }
            print("newImageSize: \(newImageSize)")
            
            var newBox = boundingBox.rectForSize(newImageSize)
            if let paddingLeft = paddingLeft {
                newBox.origin.x += paddingLeft
            }
            if let paddingTop = paddingTop {
                newBox.origin.y += paddingTop
            }
            print("newBox: \(newBox)")
            /// If the box is longer than it is tall
            if newBox.size.widthToHeightRatio > 1 {
                /// Add 10% padding to its horizontal side
                let padding = newBox.size.width * 0.1
                newBox.origin.x -= (padding / 2.0)
                newBox.size.width += padding
            } else {
                /// Add 10% padding to its vertical side
                let padding = newBox.size.height * 0.1
                newBox.origin.y -= (padding / 2.0)
                newBox.size.height += padding
            }
            print("newBox (padded): \(newBox)")
            
            /// Now determine the box we want to zoom into, given the image's dimensions
            /// Now if the image's width/height ratio is less than the scrollView's
            ///     we'll have padding on the x-axis, so determine what this would be based on the scrollView's frame's ratio and the current zoom scale
            ///     Add this to the box's x-axis to determine its true rect within the scrollview
            /// Or if the image's width/height ratio is greater than the scrollView's
            ///     we'll have y-axis padding, determine this
            ///     Add this to box's y-axis to determine its true rect
            /// Now zoom to this rect
            
            
//            print("contentSize: \(scrollView.contentSize)")
//            print("contentOffset: \(scrollView.contentOffset)")
//            print("viewForZooming.frame.size: \(scrollView.delegate!.viewForZooming!(in: scrollView)!.frame.size)")

//            let zoomRect = CGRect(x: 147, y: 129, width: 134, height: 118)
            scrollView.zoom(to: newBox, animated: true)
        }

        return scrollView
    }
    
    public func makeCoordinator() -> Coordinator {
        return Coordinator(hostingController: UIHostingController(rootView: self.content))
    }
    
    public func updateUIView(_ uiView: UIScrollView, context: Context) {
        // update the hosting controller's SwiftUI content
        context.coordinator.hostingController.rootView = self.content
        assert(context.coordinator.hostingController.view.superview == uiView)
    }
    
    // MARK: - Coordinator
    public class Coordinator: NSObject, UIScrollViewDelegate {
        var hostingController: UIHostingController<Content>
        
        init(hostingController: UIHostingController<Content>) {
            self.hostingController = hostingController
        }
        
        public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return hostingController.view
        }
    }
}

extension UIScrollView {
    
    func zoomRectForScale(_ scale: CGFloat, withCenter center: CGPoint) -> CGRect {

        let newCenter = convert(center, from: self)
        let rect = CGRect(center: newCenter, size: CGSize(width: 50, height: 50))
        return rect
        var zoomRect: CGRect = .zero

        // the zoom rect is in the content view's coordinates.
        //    At a zoom scale of 1.0, it would be the size of the imageScrollView's bounds.
        //    As the zoom scale decreases, so more content is visible, the size of the rect grows.
        zoomRect.size.height = self.contentSize.height / scale
        zoomRect.size.width  = self.contentSize.width / scale

        // choose an origin so as to get the right center.
        zoomRect.origin.x = (center.x * (2 - self.minimumZoomScale) - (zoomRect.size.width  / 2.0))
        zoomRect.origin.y = (center.y * (2 - self.minimumZoomScale) - (zoomRect.size.height / 2.0))

        return zoomRect
    }
}

extension CGRect
{
    /** Creates a rectangle with the given center and dimensions
    - parameter center: The center of the new rectangle
    - parameter size: The dimensions of the new rectangle
     */
    init(center: CGPoint, size: CGSize)
    {
        self.init(x: center.x - size.width / 2, y: center.y - size.height / 2, width: size.width, height: size.height)
    }
    
    /** the coordinates of this rectangles center */
    var center: CGPoint
        {
        get { return CGPoint(x: centerX, y: centerY) }
        set { centerX = newValue.x; centerY = newValue.y }
    }
    
    /** the x-coordinate of this rectangles center
    - note: Acts as a settable midX
    - returns: The x-coordinate of the center
     */
    var centerX: CGFloat
        {
        get { return midX }
        set { origin.x = newValue - width * 0.5 }
    }
    
    /** the y-coordinate of this rectangles center
     - note: Acts as a settable midY
     - returns: The y-coordinate of the center
     */
    var centerY: CGFloat
        {
        get { return midY }
        set { origin.y = newValue - height * 0.5 }
    }
    
    // MARK: - "with" convenience functions
    
    /** Same-sized rectangle with a new center
    - parameter center: The new center, ignored if nil
    - returns: A new rectangle with the same size and a new center
     */
    func with(center: CGPoint?) -> CGRect
    {
        return CGRect(center: center ?? self.center, size: size)
    }
    
    /** Same-sized rectangle with a new center-x
    - parameter centerX: The new center-x, ignored if nil
    - returns: A new rectangle with the same size and a new center
     */
    func with(centerX: CGFloat?) -> CGRect
    {
        return CGRect(center: CGPoint(x: centerX ?? self.centerX, y: centerY), size: size)
    }

    /** Same-sized rectangle with a new center-y
    - parameter centerY: The new center-y, ignored if nil
    - returns: A new rectangle with the same size and a new center
     */
    func with(centerY: CGFloat?) -> CGRect
    {
        return CGRect(center: CGPoint(x: centerX, y: centerY ?? self.centerY), size: size)
    }
    
    /** Same-sized rectangle with a new center-x and center-y
    - parameter centerX: The new center-x, ignored if nil
    - parameter centerY: The new center-y, ignored if nil
    - returns: A new rectangle with the same size and a new center
     */
    func with(centerX: CGFloat?, centerY: CGFloat?) -> CGRect
    {
        return CGRect(center: CGPoint(x: centerX ?? self.centerX, y: centerY ?? self.centerY), size: size)
    }
}
