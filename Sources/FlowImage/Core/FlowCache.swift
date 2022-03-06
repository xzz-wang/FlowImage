//
//  FlowCache.swift
//  ClassHouse
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

    // MARK: - Cache Entry Class definition
    /// Maybe in the future we can add an expire time to this.
    private class CacheEntry {
        var image: Task<FlowImage, Error> {
            willSet {
                image.cancel()
            }
            didSet {
                subject.send()
            }
        }

        let didChangePublisher: Publisher // A shared wrap to the subject.
        private let subject: PassthroughSubject<Publisher.Output, Publisher.Failure>

        init(imageTask: Task<FlowImage, Error>) {
            self.image = imageTask

            self.subject = PassthroughSubject<Publisher.Output, Publisher.Failure>()
            self.didChangePublisher = subject
                .share()
                .eraseToAnyPublisher()
        }

        func getUIImage() async throws -> UIImage {
            return try await image.value.getUIImage()
        }

        deinit {
            image.cancel()
            subject.send(completion: .finished)
        }
    }

    // MARK: - FlowCache Properties
    /// A singleton instance that is commonly used as default when a FlowCache is needed.
    public static let shared = FlowCache()

    private var imageCache: [FlowImage.ID: CacheEntry] = [:]
    private var memoryWarningSubscription: Cancellable?

    // MARK: - Public Methods
    public init() {
        subscribeToMemoryWarning()
    }

    public func get(_ picture: FlowImage, forceReCache: Bool = false) async throws -> UIImage {
        if forceReCache || imageCache[picture.id] == nil {
            cache(picture)
        }
        return try await imageCache[picture.id]!.getUIImage()
    }

    public func getAndSubscribeTo(_ picture: FlowImage, forceReCache: Bool = false) async throws -> (UIImage, Publisher) {
        let image = try await get(picture, forceReCache: forceReCache)
        guard let publisher = imageCache[picture.id]?.didChangePublisher else {
            throw FlowImageError.unexpected
        }
        return (image, publisher)
    }

    public func clear() {
        imageCache = [:]
    }

    // MARK: - Internal Methods

    /// Cache the image or replace the cached image.
    func cache(_ picture: FlowImage) {
        // Create a new task to cache this new image
        let newImgTask = Task { () -> FlowImage in
            return try await picture.prepareForDisplay()
        }

        if let entry = imageCache[picture.id] {
            entry.image = newImgTask
        } else {
            imageCache[picture.id] = CacheEntry(imageTask: newImgTask)
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
