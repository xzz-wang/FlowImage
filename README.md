# FlowImage
A Swift/SwiftUI utility for caching and displaying images asynchronously. Built with Swift 5.5 and works with async/await.

### Install
To add FlowImage to your app, see: [Doc: Adding Package Dependencies to Your App](https://developer.apple.com/documentation/swift_packages/adding_package_dependencies_to_your_app)

# Usage
## FlowImage

FlowImage is a protocol for you to implement. A `FlowImage` should store all the necessary information to produce an image, and also defines how to produce it.
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
You may return a different `FlowImage` type if you want. As an example, during `prepareForDisplay()`, `URLFlowImage` will download
the image from the URL, and store the downloaded image in a `DownloadedFlowImage` instance before returning it.

### getUIImage() 
This is where you produce the `UIImage` class for display.

### hash(into hasher: inout Hasher)
This is here so that we can hash any `FlowImage` type if needed. `AnyFlowImage` conforms to `Hashable`.
- [Swift Standard Library: Hashable](https://developer.apple.com/documentation/swift/hashable)


## FlowCache
Work in progress...
