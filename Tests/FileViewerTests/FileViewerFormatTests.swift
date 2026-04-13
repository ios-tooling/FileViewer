import Testing
import Foundation
import SwiftUI
@testable import FileViewer

// MARK: - Mock format implementations

final class MockJSONFormat: FileViewerFormat {
	static let fileExtension = "json"
	static let name = "Mock JSON"
	init(url: URL) throws {}
	init(data: Data, name: String) throws {}
	var contentView: AnyView { AnyView(EmptyView()) }
}

final class MockTextFormat: FileViewerFormat {
	static let fileExtension = "txt"
	static let name = "Mock Text"
	init(url: URL) throws {}
	init(data: Data, name: String) throws {}
	var contentView: AnyView { AnyView(EmptyView()) }
}

final class FailingFormat: FileViewerFormat {
	static let fileExtension = "fail"
	static let name = "Always Fails"
	struct ParseError: Error {}
	init(url: URL) throws { throw ParseError() }
	init(data: Data, name: String) throws { throw ParseError() }
	var contentView: AnyView { AnyView(EmptyView()) }
}

// MARK: - Tests
// Serialized because the format registry is global mutable state.

@MainActor
@Suite("FileViewerFormat registry", .serialized)
struct FileViewerFormatTests {

	init() {
		fileViewerFormats.removeAll()
	}

	@Test func registryStartsEmpty() {
		#expect(fileViewerFormats.isEmpty)
	}

	@Test func registerAppendsFormat() {
		registerFileViewer(format: MockJSONFormat.self)
		#expect(fileViewerFormats.count == 1)
	}

	@Test func formatterLookupFindsRegisteredFormat() {
		registerFileViewer(format: MockJSONFormat.self)
		let found = fileViewerFormatter(for: "json")
		#expect(found != nil)
		#expect(found?.name == "Mock JSON")
	}

	@Test func formatterLookupReturnsNilForUnknownExtension() {
		registerFileViewer(format: MockJSONFormat.self)
		#expect(fileViewerFormatter(for: "unknown") == nil)
	}

	@Test func formatterLookupIsCaseInsensitive() {
		registerFileViewer(format: MockJSONFormat.self)
		#expect(fileViewerFormatter(for: "JSON") != nil)
		#expect(fileViewerFormatter(for: "Json") != nil)
		#expect(fileViewerFormatter(for: "jSoN") != nil)
	}

	@Test func multipleFormatsCoexist() {
		registerFileViewer(format: MockJSONFormat.self)
		registerFileViewer(format: MockTextFormat.self)
		#expect(fileViewerFormats.count == 2)
		#expect(fileViewerFormatter(for: "json")?.name == "Mock JSON")
		#expect(fileViewerFormatter(for: "txt")?.name == "Mock Text")
	}

	@Test func formatterLookupReturnsFirstMatchOnDuplicateRegistration() {
		registerFileViewer(format: MockJSONFormat.self)
		registerFileViewer(format: MockJSONFormat.self)
		#expect(fileViewerFormats.count == 2)
		#expect(fileViewerFormatter(for: "json") != nil)
	}

	@Test func formatterLookupReturnsNilWhenRegistryIsEmpty() {
		#expect(fileViewerFormatter(for: "anything") == nil)
	}

	@Test func formatInstancesCanBeConstructedFromBothInputTypes() throws {
		let urlInstance = try MockJSONFormat(url: URL(fileURLWithPath: "/tmp/x"))
		let dataInstance = try MockJSONFormat(data: Data(), name: "y")
		_ = urlInstance.contentView
		_ = dataInstance.contentView
	}

	@Test func failingFormatThrowsAsExpected() {
		#expect(throws: FailingFormat.ParseError.self) {
			_ = try FailingFormat(url: URL(fileURLWithPath: "/tmp/x"))
		}
		#expect(throws: FailingFormat.ParseError.self) {
			_ = try FailingFormat(data: Data(), name: "x")
		}
	}
}
