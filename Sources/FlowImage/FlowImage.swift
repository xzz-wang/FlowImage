import UIKit

public protocol FlowImage {

    // swiftlint:disable type_name
    typealias ID = String
    var id: ID { get }

    /// You can call this method before using the image to prepare for display if needed.
    ///
    /// Calling this method gives the underlying implementation a chance to
    /// download any data from the internet or render it out in the memory.
    func prepareForDisplay() async throws -> FlowImage

    /// After calling prepareForDisplay you can get the UIImage using this method.
    /// - Note: Please use getUIImageFromCache() for automatic caching.
    func getUIImage() async throws -> UIImage
}

extension FlowImage {
    func toEquatable() -> AnyFlowImage {
        return AnyFlowImage(self)
    }

//    func getUIImageFromCache() async throws -> UIImage {
//        try await PictureCache.instance.get(self)
//    }
}
