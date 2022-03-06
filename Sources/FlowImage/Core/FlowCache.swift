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
        let didChangePublisher: Publisher // A shared wrap to the subject.
        private let subject: PassthroughSubject<Publisher.Output, Publisher.Failure>


        init(image: FlowImage) {
            self.image = image

            self.subject = PassthroughSubject<Publisher.Output, Publisher.Failure>()
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

    // MARK: - FlowCache Properties
    /// A singleton instance that is commonly used as default when a FlowCache is needed.
    public static let shared = FlowCache()

    private var imageCache: [FlowImage.ID: CacheEntry] = [:]
    private var memoryWarningSubscription: Cancellable?

    // MARK: - Public Methods
    public init() {
        subscribeToMemoryWarning()
    }

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

    public func clear() {
        imageCache = [:]
    }

    // MARK: - Internal Methods

    /// Cache the image or replace the cached image.
    func cache(_ picture: FlowImage) {
        if let entry = imageCache[picture.id] {
            entry.image = picture
        } else {
            imageCache[picture.id] = CacheEntry(image: picture)
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
