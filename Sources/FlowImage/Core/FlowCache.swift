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
        let image: FlowImage
    }

    private var tasks: [FlowImage.ID: Task<CacheEntry, Error>] = [:]
    private var memoryWarningSubscription: Cancellable?

    public init() {
        subscribeToMemoryWarning()
    }

    public func get(_ picture: FlowImage, forceReCache: Bool = false) async throws -> UIImage {
        if forceReCache || tasks[picture.id] == nil {
            cache(picture)
        }
        return try await tasks[picture.id]!.value.image.getUIImage()
    }

    public func clear() {
        for (_, task) in tasks {
            task.cancel()
        }
        tasks = [:]
    }

    /// Cache the image or replace the cached image.
    func cache(_ picture: FlowImage) {
        let newTask = Task { () -> CacheEntry in
            do {
                let preparedPic = try await picture.prepareForDisplay()
                return CacheEntry(image: preparedPic)
            } catch {
                tasks[picture.id] = nil
                throw error
            }
        }
        tasks[picture.id]?.cancel()
        tasks[picture.id] = newTask
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
