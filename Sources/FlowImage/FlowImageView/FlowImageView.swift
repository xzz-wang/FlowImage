//
//  FlowImageView.swift
//  
//
//  Created by Xuezheng Wang on 1/26/22.
//

import Combine
import SwiftUI

public struct FlowImageView<Content: View>: View {
    public init(image: FlowImage?, cache: FlowCache? = nil, contentBuilder: @escaping (UIImage?, FlowImageViewState) -> Content) {
        self.image = image
        self.cache = cache ?? FlowCache.shared
        self.contentBuilder = contentBuilder
    }

    // MARK: - Inputs
    let image: FlowImage?
    let cache: FlowCache
    @ViewBuilder let contentBuilder: (UIImage?, FlowImageViewState) -> Content

    // MARK: - States
    @State private var uiimage: UIImage?
    @State private var viewState: FlowImageViewState = .loading
    @State private var canceler: Cancellable?

    // MARK: - View Body
    public var body: some View {
        contentBuilder(uiimage, self.viewState)
            .onChange(of: image?.eraseToAnyFlowImage()) { newImage in
                fetchImage(newImage, cache: cache)
            }
            .onAppear {
                fetchImage(image, cache: cache)
            }
    }

    private func fetchImage(_ image: FlowImage?, cache: FlowCache) {
        viewState = .loading
        self.canceler?.cancel()
        Task {
            do {
                if let image = image {
                    let (uiimage, publisher) = try await cache.getAndSubscribeTo(image)
                    self.uiimage = uiimage

                    // Subscribe to
                    self.canceler = publisher.sink { _ in
                        fetchImage(self.image, cache: cache)
                    } receiveValue: { _ in
                        fetchImage(self.image, cache: cache)
                    }
                } else {
                    self.uiimage = nil
                }
                viewState = .displaying
            } catch {
                uiimage = nil
                viewState = .error
            }
        }
    }
}
