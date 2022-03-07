# FlowImage
A Swift/SwiftUI utility for caching and displaying images asynchronously. Built with Swift 5.5 and works with async/await.

### Install
To add FlowImage to your app, see: [Doc: Adding Package Dependencies to Your App](https://developer.apple.com/documentation/swift_packages/adding_package_dependencies_to_your_app)

# Usage
## Level 1: Use URLFlowImage to handle asynchronous loading of images.
We've provided a `URLFlowImage` that can be used to load images from an URL. Directly call `getUIImage()` on 
`URLFlowImage` instances can give you a simple async image loading. See [example](FlowImageSampleApp/FlowImageSampleApp/Level1View.swift).
```Swift
let image: UIImage? = nil
image = try? await yourURLFlowImage.getUIImage() // You can execute this in your view's .task{}
```

## Level 2: Use FlowImage with FlowImageView to manage states.
It's annoying to handle the state of loading your image and display it correctly. Introducing FlowImageView. It has the following
features:
- **Automatic caching**: if you are using this image multiple times, `prepareForDisplay()` of that FlowImage will only be called once! If you are using `URLFlowImage`, it means that we will only download the image once. 
- **Automatic state management**: In the body of `FlowImageView`, we give you a value of type `FlowImageViewState`([link](Sources/FlowImage/FlowImageView/FlowImageViewState.swift)) so that you know what's going on. 

Example [(Link to sample App)](FlowImageSampleApp/FlowImageSampleApp/Level2View.swift):
```Swift
// Inside your view
FlowImageView(image: image) { uiimage, state in
    // First parameter (UIImage?): produced uiimage.
    // Second parameter: the current state of the image.
    ZStack {
        if state == .displaying {
            if let image = uiimage {
                // Being in here means we have a proper image to display
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)

            } else {
                // If the image is nil and we are displaying, it means the
                // FlowImage that's passed in is nil.
                Text("No Image")
            }
        } else if state == .error {
            // If state == .error, it means an error occurred, and image
            // value is set to nil.
            Text("There was an error!")

        } else if state == .loading {
            if let image = uiimage {
                // If image is not nil when loading, it will be the image
                // before we started loading.
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .colorMultiply(.init(red: 0.5, green: 0.5, blue: 0.5))

            }

            // We overlay a progress view if we are loading.
            ProgressView()
                .progressViewStyle(.circular)
        }
    }
}
```

## Level 3: Implementing your own FlowImage
The image can be stored anywhere. In another project, the images are stored on 
Firestore. You can create your own FlowImage class that conforms to the protocol,
and it will be seamlessly integrated with the result of the package.


## Implementing an instance of FlowImage

FlowImage is a protocol for you to implement. Once implemented, it will come with 
a lot of great utilities. A `FlowImage` should store all the necessary information 
to produce an image, and also defines how to produce it.
It only requires 1 property and 3 methods:
```Swift
protocol FlowImage {
    var id: ID { get }

    func prepareForDisplay() async throws -> FlowImage
    func getUIImage() async throws -> UIImage
    func hash(into hasher: inout Hasher)
}
```
### var id: ID
`FlowImage.ID` is an alias for type `String`. You will need to provide an unique string so that other utilities (like `FlowCache`) can distinguish
between different images.


### prepareForDisplay()
This is where you do any preparation before displaying. After the preparation is done, return another `FlowImage` with prepared data.
Usually you would want to return a `DownloadedFlowImage` which holds an `UIImage` reference. You may return a different `FlowImage` 
type if you want. As an example, during `prepareForDisplay()`, `URLFlowImage` will download the image from the URL, and store the 
downloaded image in a `DownloadedFlowImage` instance before returning it.

### getUIImage() 
This is where you produce the `UIImage` class for display. `getUIImage()` method should work without calling `prepareForDisplay()` first, so that 
it can work independent from a cache.

### hash(into hasher: inout Hasher)
This is here so that we can hash any `FlowImage` type if needed. `AnyFlowImage` conforms to `Hashable`.
- [Swift Standard Library: Hashable](https://developer.apple.com/documentation/swift/hashable)


## FlowCache
Work in progress...
