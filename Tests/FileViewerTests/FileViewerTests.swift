import Testing
import Foundation
import UniformTypeIdentifiers
@testable import FileViewer

@Suite("FileViewer (smoke)")
struct FileViewerSmokeTests {
	@Test func canConstructFromURL() {
		let url = URL(fileURLWithPath: "/tmp/example.json")
		let viewer = FileViewer(url: url)
		#expect(viewer.source.displayName == "example.json")
	}

	@Test func canConstructFromData() {
		let viewer = FileViewer(data: Data("hello".utf8), name: "greeting.txt")
		#expect(viewer.source.displayName == "greeting.txt")
		#expect(viewer.source.byteCount == 5)
	}

	@Test func canConstructWithExplicitType() {
		let viewer = FileViewer(data: Data(), name: "untyped", type: .json)
		#expect(viewer.source.fileType == .json)
	}
}
