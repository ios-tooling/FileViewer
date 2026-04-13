import Testing
import Foundation
import UniformTypeIdentifiers
@testable import FileViewer

@Suite("FileViewerSource")
struct FileViewerSourceTests {

	// MARK: - displayName

	@Test func displayNameForDataSourceIsTheGivenName() {
		let source = FileViewerSource.data(Data(), name: "photo.heic")
		#expect(source.displayName == "photo.heic")
	}

	@Test func displayNameForURLSourceIsLastPathComponent() {
		let source = FileViewerSource.url(URL(fileURLWithPath: "/tmp/nested/dir/file.png"))
		#expect(source.displayName == "file.png")
	}

	// MARK: - fileType

	@Test func fileTypeUsesExplicitTypeWhenProvided() {
		let source = FileViewerSource.data(Data(), name: "anything.xml", type: .json)
		#expect(source.fileType == .json)
	}

	@Test func fileTypeForDataSourceDerivesFromFilenameExtension() {
		let source = FileViewerSource.data(Data(), name: "document.json")
		#expect(source.fileType == .json)
	}

	@Test func fileTypeFallsBackToDataWhenNoTypeOrExtension() {
		let source = FileViewerSource.data(Data(), name: "noextension")
		#expect(source.fileType == .data)
	}

	@Test func fileTypeForURLSourceDerivesFromExtension() {
		let source = FileViewerSource.url(URL(fileURLWithPath: "/tmp/archive.zip"))
		#expect(source.fileType.conforms(to: .data))
	}

	// MARK: - data

	@Test func dataAccessorReturnsStoredDataForDataSource() {
		let payload = Data([0x01, 0x02, 0x03])
		let source = FileViewerSource.data(payload, name: "blob")
		#expect(source.data == payload)
	}

	@Test func dataAccessorReadsFromDiskForURLSource() throws {
		let payload = Data("file contents".utf8)
		try withTemporaryFile(content: payload, name: "read-test.txt") { url in
			let source = FileViewerSource.url(url)
			#expect(source.data == payload)
		}
	}

	@Test func dataAccessorReturnsNilForMissingURL() {
		let source = FileViewerSource.url(URL(fileURLWithPath: "/definitely/does/not/exist-\(UUID().uuidString)"))
		#expect(source.data == nil)
	}

	// MARK: - url

	@Test func urlAccessorReturnsNilForDataSource() {
		let source = FileViewerSource.data(Data(), name: "a.txt")
		#expect(source.url == nil)
	}

	@Test func urlAccessorReturnsTheURLForURLSource() {
		let url = URL(fileURLWithPath: "/tmp/x.dat")
		let source = FileViewerSource.url(url)
		#expect(source.url == url)
	}

	// MARK: - byteCount

	@Test func byteCountForDataSourceMatchesDataSize() {
		let source = FileViewerSource.data(Data(count: 42), name: "forty-two")
		#expect(source.byteCount == 42)
	}

	@Test func byteCountForURLSourceMatchesFileSize() throws {
		let payload = Data(count: 128)
		try withTemporaryFile(content: payload, name: "sized.bin") { url in
			let source = FileViewerSource.url(url)
			#expect(source.byteCount == 128)
		}
	}

	@Test func byteCountForEmptyData() {
		let source = FileViewerSource.data(Data(), name: "empty")
		#expect(source.byteCount == 0)
	}

	// MARK: - pathExtension

	@Test func pathExtensionForDataSource() {
		let source = FileViewerSource.data(Data(), name: "archive.TAR.gz")
		#expect(source.pathExtension == "gz")
	}

	@Test func pathExtensionForDataSourceWithNoExtension() {
		let source = FileViewerSource.data(Data(), name: "README")
		#expect(source.pathExtension == "")
	}

	@Test func pathExtensionForURLSource() {
		let source = FileViewerSource.url(URL(fileURLWithPath: "/tmp/pic.JPG"))
		#expect(source.pathExtension == "JPG")
	}
}
