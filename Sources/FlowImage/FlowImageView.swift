//
//  ProfilePicture.swift
//  ClassHouse
//
//  Created by Xuezheng Wang on 1/26/22.
//

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
        Task {
            do {
                self.uiimage = try await image?.getUIImageFromCache(cache)
                viewState = .displaying
            } catch {
                viewState = .error
            }
        }
    }
}

public enum FlowImageViewState {
    case displaying
    case error
    case loading
}

