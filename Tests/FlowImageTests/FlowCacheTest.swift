//
//  FlowCacheTest.swift
//  
//
//  Created by Xuezheng Wang on 2/22/22.
//

import XCTest
import FlowImage

@MainActor
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

    /// Test we can call reset with noting in it.
    func testClearEmpty() throws {
        cache.clear()
    }

    /// Test that we can call reset with one image.
    func testClearOnePic() async throws {
        cache.clear()
        let flow1 = TestFlowImage(img1, id: "test_one_pic")
        let flow1Fail = TestFlowImage(img1, id: "test_one_pic", failGet: true)

        _ = try await flow1.getUIImageFromCache(cache) // Add flow1 to cache
        cache.clear() // Clear flow1 out of cache

        do {
            _ = try await flow1Fail.getUIImageFromCache(cache)
            XCTFail("We should throw error")
        } catch {
            XCTAssert(error as! FlowImageError == .failed)
        }
    }

    /// Make sure we can get the cached image with the same id.
    func testGet() async throws {
        cache.clear()
        let flow1 = TestFlowImage(img1, id: "test_get")
        let flow2 = TestFlowImage(img2, id: "test_get")

        _ = try await flow1.getUIImageFromCache(cache)
        let resultImg = try await flow2.getUIImageFromCache(cache)

        // Should have gotten img1 from cache instead of img2.
        XCTAssert(resultImg == img1, "Not getting the image from cache!")
    }

    /// Make sure we can get the cached image with the same id.
    func testGet2() async throws {
        cache.clear()
        let flow1 = TestFlowImage(img1, id: "test_get")
        let flow2 = TestFlowImage(img2, id: "test_get")
        let flow3 = TestFlowImage(img1, id: "test_get_notThisOne")

        _ = try await flow1.getUIImageFromCache(cache)
        _ = try await flow3.getUIImageFromCache(cache)
        let resultImg = try await cache.get(flow2)

        // Should have gotten img1 from cache instead of img2.
        XCTAssert(resultImg == img1, "Not getting the image from cache!")
    }

    /// forceRecache is doing what it's suppose to be.
    func testRecache() async throws {
        cache.clear()
        let flow1 = TestFlowImage(img1, id: "test_recache")
        let flow2 = TestFlowImage(img2, id: "test_recache")

        _ = try await flow1.getUIImageFromCache(cache)
        let resultImg = try await flow2.getUIImageFromCache(cache, forceRecache: true)

        XCTAssert(resultImg == img2, "Not force recaching!")
    }

    func testFailedPrepare() async {
        cache.clear()
        let flow1 = TestFlowImage(img1, failPrepare: true)
        do {
            _ = try await flow1.getUIImageFromCache(cache)
            XCTFail()
        } catch {
            XCTAssert(error as! FlowImageError == .failed)
        }
    }

    func testFailedGet() async {
        cache.clear()
        let flow1 = TestFlowImage(img1, failGet: true)
        do {
            _ = try await flow1.getUIImageFromCache(cache)
            XCTFail()
        } catch {
            XCTAssert(error as! FlowImageError == .failed)
        }
    }

    func testFailedPrepareAndRetryOnNextGet() async throws {
        cache.clear()

        let flow1 = TestFlowImage(img1, id: "pic", failPrepare: true)
        let flow1Success = TestFlowImage(img1, id: "pic")

        // First, faile the request once.
        do {
            _ = try await flow1.getUIImageFromCache(cache)
            XCTFail()
        } catch {
            XCTAssert(error as! FlowImageError == .failed)
        }

        // Second request
        do {
            _ = try await flow1Success.getUIImageFromCache(cache)
        } catch {
            XCTFail("The second try shouldn't throw error")
        }
    }

    // MARK: - Combine subscriber tests
    func testObserveChange() async throws {
        cache.clear()
        let flow1 = TestFlowImage(img1)

    }
}
