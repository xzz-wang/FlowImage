//
//  FlowCache.swift
//  
//
//  Created by Xuezheng Wang on 2/5/22.
//

import Combine
import Foundation
import UIKit

///
/// An actor that produces thread-safe caching of FlowImages.
///
@MainActor
public class FlowCache {
    /// Combine publisher types
    public typealias Publisher = AnyPublisher<Void, Never>

    // MARK: - FlowCache Properties
    /// A singleton instance that is commonly used as default when a FlowCache is needed.
    public static let shared = FlowCache()

    private var imageCache: [FlowImage.ID: FlowCacheEntry] = [:]
    private var memoryWarningSubscription: Cancellable?

    // MARK: - Public Methods
    public init() {
        subscribeToMemoryWarning()
    }

    /// Get this FlowImage's as UIImage.
    ///
    /// This will trigger caching if
    ///  1. This is the first time we call `get()` with this FlowImage's id.
    ///  2. `forceReCache` is set to `true`.
    ///  3. The last `get()` with this id failed.
    public func get(
        _ picture: FlowImage,
        forceReCache: Bool = false
    ) async throws -> UIImage {
        let entry = imageCache[picture.id]
        if forceReCache || entry == nil || entry!.failed {
            cache(picture)
        }
        return try await imageCache[picture.id]!.getUIImage()
    }

    /// Does the same thing as `get()`, while also returns a publisher to notify you of the changes.
    ///
    /// - Returns:
    /// Publisher: This publisher will emit
    /// whenever someone else forced a recache. It will send completion when this image is
    /// removed from the cache (due to memory constraint).
    public func getAndSubscribeTo(
        _ picture: FlowImage,
        forceReCache: Bool = false
    ) async throws -> (UIImage, Publisher) {
        let image = try await get(picture, forceReCache: forceReCache)
        guard let publisher = imageCache[picture.id]?.didChangePublisher else {
            throw FlowImageError.unexpected
        }
        return (image, publisher)
    }

    public func remove(_ flowImage: FlowImage) {
        imageCache.removeValue(forKey: flowImage.id)
    }

    /// Remove all the cached image from the cache.
    public func clear() {
        imageCache = [:]
    }

    // MARK: - Internal Methods

    /// Cache the image or replace the cached image.
    func cache(_ picture: FlowImage) {
        if let entry = imageCache[picture.id] {
            entry.image = picture
        } else {
            imageCache[picture.id] = FlowCacheEntry(image: picture)
        }
    }

    // MARK: - Private functions

    /// Subscribe to publisher for handling low memory
    /// Note: Currently, the cache will clear itself when the memory is low.
    private func subscribeToMemoryWarning() {
        let warningNotification = UIApplication.didReceiveMemoryWarningNotification
        let warningPublisher = NotificationCenter.default.publisher(for: warningNotification)
        memoryWarningSubscription = warningPublisher
            .sink { notification in
                self.clear()
            }
    }
}

// MARK: - Cache Entry Class definition
/// An object that manages the caching of each FlowImage.
private class FlowCacheEntry {
    var image: FlowImage {
        didSet {
            imageResult.cancel()
            setImageTask(image)
        }
    }

    private(set) var imageResult: Task<FlowImage, Error>! {
        didSet {
            subject.send()
        }
    }

    var failed: Bool = false
    let didChangePublisher: FlowCache.Publisher // A shared wrap to the subject.
    private let subject: PassthroughSubject<FlowCache.Publisher.Output, FlowCache.Publisher.Failure>


    init(image: FlowImage) {
        self.image = image

        self.subject = PassthroughSubject<FlowCache.Publisher.Output, FlowCache.Publisher.Failure>()
        self.didChangePublisher = subject
            .share()
            .eraseToAnyPublisher()

        setImageTask(self.image)
    }

    func getUIImage() async throws -> UIImage {
        return try await imageResult.value.getUIImage()
    }

    private func setImageTask(_ image: FlowImage) {
        failed = false
        imageResult = Task {
            do {
                return try await image.prepareForDisplay()
            } catch {
                failed = true
                throw error
            }
        }
    }

    deinit {
        imageResult.cancel()
        subject.send(completion: .finished)
    }
}
