import UIKit

/**
 A type that represents information on how to produce an image.
 */
public protocol FlowImage {

    typealias ID = String
    var id: ID { get }

    /// You can call this method before using the image to prepare for display if needed.
    ///
    /// Calling this method gives the underlying implementation a chance to
    /// download any data from the internet or render it out in the memory, for example.
    func prepareForDisplay() async throws -> FlowImage

    /// After calling prepareForDisplay you can get the UIImage using this method.
    /// - Note: Use getUIImageFromCache() for automatic caching.
    func getUIImage() async throws -> UIImage

    /// To support hashing of AnyFlowImage
    func hash(into hasher: inout Hasher)
}

public extension FlowImage {
    /// Get a type-erasing instance that conforms to Equatable, Hashable, and Identifiable.
    func eraseToAnyFlowImage() -> AnyFlowImage {
        return AnyFlowImage(self)
    }

    func getUIImageFromCache(_ c: FlowCache? = nil, forceRecache: Bool = false) async throws -> UIImage {
        let cache = c ?? FlowCache.shared
        return try await cache.get(self, forceReCache: forceRecache)
    }

    /// If this flow image is cached, calling this method will remove the image from cache.
    func removeFromCache(_ c: FlowCache? = nil) {
        let cache = c ?? FlowCache.shared
        cache.remove(self)
    }
}
