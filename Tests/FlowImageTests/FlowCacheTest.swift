//
//  FlowCacheTest.swift
//  
//
//  Created by Xuezheng Wang on 2/22/22.
//

import XCTest
import FlowImage

class FlowCacheTest: XCTestCase {

    private var cache = FlowCache()

    private let img1 = UIImage(systemName: "person")!
    private let img2 = UIImage(systemName: "person.2")!
    private let img3 = UIImage(systemName: "person.3")!

    private class TestFlowImage: FlowImage {
        var id: ID

        private let img: UIImage
        private let failPrepare: Bool
        private let failGet: Bool


        init(_ uiimage: UIImage, id: ID? = nil, failPrepare: Bool = false, failGet: Bool = false) {
            self.img = uiimage
            self.id = id ?? "TestImage - \(img.hashValue)"
            self.failPrepare = failPrepare
            self.failGet = failGet
        }

        func prepareForDisplay() async throws -> FlowImage {
            if failPrepare {
                throw FlowImageError.failed
            }
            return self
        }

        func getUIImage() async throws -> UIImage {
            if failGet {
                throw FlowImageError.failed
            }
            return img
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(img)
        }
    }

    func testResetEmpty() throws {
        let exp = expectation(description: "reset() doesn't crash")
        Task {
            await cache.clear()
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
    }

    func testResetOnePic() async throws {
        await cache.clear()
        let flow1 = TestFlowImage(img1, id: "test_one_pic")
        let flow2 = TestFlowImage(img2, id: "test_one_pic")

        _ = try await flow1.getUIImageFromCache(cache)
        await cache.clear()
        let resultImg = try await flow2.getUIImageFromCache(cache)

        XCTAssert(resultImg == img2, "Reset working incorrectly")
    }

    func testGet() async throws {
        await cache.clear()
        let flow1 = TestFlowImage(img1, id: "test_get")
        let flow2 = TestFlowImage(img2, id: "test_get")

        _ = try await flow1.getUIImageFromCache(cache)
        let resultImg = try await flow2.getUIImageFromCache(cache)

        // Should have gotten img1 from cache instead of img2.
        XCTAssert(resultImg == img1, "Not getting the image from cache!")
    }

    func testGet2() async throws {
        await cache.clear()
        let flow1 = TestFlowImage(img1, id: "test_get")
        let flow2 = TestFlowImage(img2, id: "test_get")
        let flow3 = TestFlowImage(img1, id: "test_get_notThisOne")

        _ = try await flow1.getUIImageFromCache(cache)
        _ = try await flow3.getUIImageFromCache(cache)
        let resultImg = try await cache.get(flow2)

        // Should have gotten img1 from cache instead of img2.
        XCTAssert(resultImg == img1, "Not getting the image from cache!")
    }

    func testRecache() async throws {
        await cache.clear()
        let flow1 = TestFlowImage(img1, id: "test_recache")
        let flow2 = TestFlowImage(img2, id: "test_recache")

        _ = try await flow1.getUIImageFromCache(cache)
        let resultImg = try await flow2.getUIImageFromCache(cache, forceRecache: true)

        XCTAssert(resultImg == img2, "Not force recaching!")
    }

    func testFailedPrepare() async {
        await cache.clear()
        let flow1 = TestFlowImage(img1, failPrepare: true)
        do {
            _ = try await flow1.getUIImageFromCache(cache)
            XCTFail()
        } catch {
            XCTAssert(error as! FlowImageError == FlowImageError.failed)
        }
    }

    func testFailedGet() async {
        await cache.clear()
        let flow1 = TestFlowImage(img1, failGet: true)
        do {
            _ = try await flow1.getUIImageFromCache(cache)
            XCTFail()
        } catch {
            XCTAssert(error as! FlowImageError == FlowImageError.failed)
        }
    }
}
