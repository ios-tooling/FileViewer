import Testing
import Foundation
import Compression
@testable import FileViewer

@Suite("Zip archive contents")
struct ZipArchiveTests {
	private let readme = Data("Hello from inside the zip.\n".utf8)
	private let big = Data(String(repeating: "crossword ", count: 400).utf8)

	@Test func listsMembersInOrderWithTheirSizes() throws {
		let archive = try FileViewerZipArchive(data: makeZip([("README.txt", readme, false), ("docs/", Data(), false), ("docs/puzzle.xml", big, true)]))
		#expect(archive.entries.map(\.path) == ["README.txt", "docs/", "docs/puzzle.xml"])
		#expect(archive.files.map(\.path) == ["README.txt", "docs/puzzle.xml"], "folders are not files")
		#expect(archive.files.map(\.size) == [readme.count, big.count])
		#expect(archive.files.last?.name == "puzzle.xml")
	}

	@Test func readsStoredAndDeflatedMembers() throws {
		let archive = try FileViewerZipArchive(data: makeZip([("README.txt", readme, false), ("puzzle.xml", big, true)]))
		#expect(try archive.data(for: archive.files[0]) == readme)
		#expect(try archive.data(for: archive.files[1]) == big)
	}

	@Test func anEmptyArchiveHasNoFiles() throws {
		let archive = try FileViewerZipArchive(data: makeZip([]))
		#expect(archive.files.isEmpty)
	}

	@Test func somethingElseIsNotAZip() {
		#expect(!FileViewerZipArchive.isZip(Data("{\"json\": true}".utf8)))
		#expect(throws: FileViewerZipArchive.ZipError.notAZip) { try FileViewerZipArchive(data: Data("plain text".utf8)) }
	}

	@Test func aCutOffArchiveIsRefused() throws {
		let whole = makeZip([("README.txt", readme, false)])
		#expect(throws: FileViewerZipArchive.ZipError.self) { try FileViewerZipArchive(data: whole.prefix(whole.count - 10)) }
	}

	@Test func aZipFileOnDiskIsFoundByItsBytesNotItsName() throws {
		let zip = makeZip([("README.txt", readme, false)])
		try withTemporaryFile(content: zip, name: "puzzle.jpz") { url in
			#expect(FileViewerZipArchive(zipAt: url)?.files.map(\.path) == ["README.txt"])
		}
		try withTemporaryFile(content: readme, name: "notes.zip") { url in
			#expect(FileViewerZipArchive(zipAt: url) == nil)
		}
	}
}

/// A zip of `members` — (path, bytes, deflate?) — laid out the way zip
/// tools write one: local headers and data, then the central directory, then
/// its end record. CRCs are left zero; the reader does not check them.
func makeZip(_ members: [(path: String, data: Data, deflate: Bool)]) -> Data {
	var body = Data(), directory = Data()
	func u16(_ value: Int) -> Data { withUnsafeBytes(of: UInt16(value).littleEndian) { Data($0) } }
	func u32(_ value: Int) -> Data { withUnsafeBytes(of: UInt32(value).littleEndian) { Data($0) } }
	for member in members {
		let stored = member.deflate ? deflate(member.data) : member.data
		let method = member.deflate ? 8 : 0
		let name = Data(member.path.utf8)
		let offset = body.count
		let local: [Data] = [u32(0x0403_4B50), u16(20), u16(0), u16(method), u32(0), u32(0),
		                     u32(stored.count), u32(member.data.count), u16(name.count), u16(0), name, stored]
		let central: [Data] = [u32(0x0201_4B50), u16(20), u16(20), u16(0), u16(method), u32(0), u32(0),
		                       u32(stored.count), u32(member.data.count), u16(name.count), u16(0), u16(0),
		                       u16(0), u16(0), u32(0), u32(offset), name]
		body.append(contentsOf: local.reduce(Data(), +))
		directory.append(contentsOf: central.reduce(Data(), +))
	}
	let end: [Data] = [u32(0x0605_4B50), u16(0), u16(0), u16(members.count), u16(members.count),
	                   u32(directory.count), u32(body.count), u16(0)]
	return body + directory + end.reduce(Data(), +)
}

private func deflate(_ data: Data) -> Data {
	var output = Data(count: data.count + 1024)
	let written = output.withUnsafeMutableBytes { destination in
		data.withUnsafeBytes { source in
			compression_encode_buffer(destination.bindMemory(to: UInt8.self).baseAddress!, destination.count,
			                          source.bindMemory(to: UInt8.self).baseAddress!, data.count, nil, COMPRESSION_ZLIB)
		}
	}
	return output.prefix(written)
}
