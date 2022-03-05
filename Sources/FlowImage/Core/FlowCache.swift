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
    /// A singleton instance that is commonly used as default when a FlowCache is needed.
    public static let shared = FlowCache()

    /// Maybe in the future we can add an expire time to this.
    private struct CacheEntry {
        let image: Task<FlowImage, Error>
        let didChangePublisher: PassthroughSubject<Void, Never>
    }

    private var imageCache: [FlowImage.ID: CacheEntry] = [:]
    private var memoryWarningSubscription: Cancellable?

    public init() {
        subscribeToMemoryWarning()
    }

    public func get(_ picture: FlowImage, forceReCache: Bool = false) async throws -> UIImage {
        if forceReCache || imageCache[picture.id] == nil {
            cache(picture)
        }
        return try await imageCache[picture.id]!.image.value.getUIImage()
    }

    public func clear() {
        var publishers: [PassthroughSubject<Void, Never>] = []
        for (_, cacheEntry) in imageCache {
            cacheEntry.image.cancel()
            publishers.append(cacheEntry.didChangePublisher)
        }
        imageCache = [:]

        publishers.forEach { $0.send() }
    }

    /// Cache the image or replace the cached image.
    func cache(_ picture: FlowImage) {
        // Create a new task to cache this new image
        let newImgTask = Task { () -> FlowImage in
            do {
                return try await picture.prepareForDisplay()
            } catch {
                imageCache[picture.id] = nil
                throw error
            }
        }

        let entry = imageCache[picture.id]

        // Cancel the image task if there's already an entry
        entry?.image.cancel()

        // Create new publisher if needed, then build new entry
        let publisher = entry?.didChangePublisher ?? PassthroughSubject<Void, Never>()
        let newEntry = CacheEntry(image: newImgTask, didChangePublisher: publisher)

        // Replace existing entry, then notify changes if needed.
        imageCache[picture.id] = newEntry
        entry?.didChangePublisher.send() // Notify changes if there
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
