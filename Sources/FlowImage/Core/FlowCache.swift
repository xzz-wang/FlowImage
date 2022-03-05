//
//  FlowCache.swift
//  ClassHouse
//
//  Created by Xuezheng Wang on 2/5/22.
//

import Foundation
import UIKit

///
/// Used in Picture's getUIImageFromCache() to produce your image.
///
public actor FlowCache {
    public static let shared = FlowCache()

    /// Maybe in the future we can add an expire time to this.
    private struct CacheEntry {
        let image: FlowImage
    }

    private var tasks: [FlowImage.ID: Task<CacheEntry, Error>] = [:]

    public init() {}

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

    public func get(_ picture: FlowImage, forceReCache: Bool = false) async throws -> UIImage {
        if forceReCache || tasks[picture.id] == nil {
            cache(picture)
        }
        return try await tasks[picture.id]!.value.image.getUIImage()
    }

    public func clear() {
        tasks = [:]
    }
}
