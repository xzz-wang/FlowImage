import UIKit

public protocol FlowImage {

    // swiftlint:disable type_name
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
    func eraseToAnyFlowImage() -> AnyFlowImage {
        return AnyFlowImage(self)
    }

    func getUIImageFromCache(forceRecache: Bool = false) async throws -> UIImage {
        try await self.getUIImageFromCache(FlowCache.shared, forceRecache: forceRecache)
    }

    func getUIImageFromCache(_ cache: FlowCache, forceRecache: Bool = false) async throws -> UIImage {
        try await cache.get(self, forceReCache: forceRecache)
    }
}