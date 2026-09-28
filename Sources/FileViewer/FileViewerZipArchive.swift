import Foundation
import Compression

/// A zip file's table of contents, with each member's bytes read on demand.
///
/// Reads the central directory for the member list, and inflates a member
/// only when it is opened, so listing a large archive costs its index, not
/// its contents. Stored and deflated members are supported; ZIP64 and
/// encrypted archives are not.
public struct FileViewerZipArchive: Sendable {
	public struct Entry: Sendable, Identifiable, Hashable {
		/// The member's path inside the archive, folders included.
		public let path: String
		/// Uncompressed size in bytes.
		public let size: Int
		let compressedSize: Int
		let method: Int
		let localHeaderOffset: Int

		public var id: String { path }
		public var name: String { (path as NSString).lastPathComponent }
		public var isDirectory: Bool { path.hasSuffix("/") }
	}

	public enum ZipError: Error, Equatable {
		case notAZip
		case truncated
		case unsupported(String)
		case inflateFailed
	}

	private let bytes: [UInt8]
	/// Every member, in the order the archive lists them.
	public let entries: [Entry]
	/// The members that are files, not folders.
	public var files: [Entry] { entries.filter { !$0.isDirectory } }

	/// Whether `data` starts like a zip: a local file header, or the end
	/// record of an empty archive.
	public static func isZip(_ data: Data) -> Bool {
		data.starts(with: [0x50, 0x4B, 0x03, 0x04]) || data.starts(with: [0x50, 0x4B, 0x05, 0x06])
	}

	/// The archive at `url`, or nil when the file is not a zip. Only its first
	/// bytes are read to decide, so a large file of another kind costs nothing.
	public init?(zipAt url: URL) {
		guard let handle = try? FileHandle(forReadingFrom: url) else { return nil }
		let head = (try? handle.read(upToCount: 4)) ?? Data()
		try? handle.close()
		guard Self.isZip(head), let data = try? Data(contentsOf: url), let archive = try? Self(data: data) else { return nil }
		self = archive
	}

	public init(data: Data) throws {
		guard Self.isZip(data) else { throw ZipError.notAZip }
		bytes = [UInt8](data)
		entries = try Self.readCentralDirectory(bytes)
	}

	/// The member's uncompressed bytes.
	public func data(for entry: Entry) throws -> Data {
		let header = entry.localHeaderOffset
		guard header + 30 <= bytes.count, le32(bytes, header) == 0x0403_4B50 else { throw ZipError.truncated }
		let start = header + 30 + le16(bytes, header + 26) + le16(bytes, header + 28)
		guard start + entry.compressedSize <= bytes.count else { throw ZipError.truncated }
		let stored = Data(bytes[start ..< start + entry.compressedSize])
		switch entry.method {
		case 0: return stored
		case 8: return try Self.inflate(stored, expected: entry.size)
		default: throw ZipError.unsupported("compression method \(entry.method)")
		}
	}

	private static func readCentralDirectory(_ bytes: [UInt8]) throws -> [Entry] {
		let end = try endRecord(bytes)
		var entries: [Entry] = []
		var at = le32(bytes, end + 16)
		for _ in 0 ..< le16(bytes, end + 10) {
			guard at + 46 <= bytes.count, le32(bytes, at) == 0x0201_4B50 else { throw ZipError.truncated }
			let flags = le16(bytes, at + 8), nameLength = le16(bytes, at + 28)
			let compressed = le32(bytes, at + 20), size = le32(bytes, at + 24), offset = le32(bytes, at + 42)
			if flags & 0x1 != 0 { throw ZipError.unsupported("encrypted members") }
			if [compressed, size, offset].contains(0xFFFF_FFFF) { throw ZipError.unsupported("ZIP64") }
			guard at + 46 + nameLength <= bytes.count else { throw ZipError.truncated }
			let path = String(decoding: bytes[at + 46 ..< at + 46 + nameLength], as: UTF8.self)
			entries.append(Entry(path: path, size: size, compressedSize: compressed, method: le16(bytes, at + 10), localHeaderOffset: offset))
			at += 46 + nameLength + le16(bytes, at + 30) + le16(bytes, at + 32)
		}
		return entries
	}

	/// The end-of-central-directory record: the last one, searched for from
	/// the end, since an archive comment may follow it.
	private static func endRecord(_ bytes: [UInt8]) throws -> Int {
		guard bytes.count >= 22 else { throw ZipError.truncated }
		let earliest = max(0, bytes.count - 22 - 0xFFFF)
		for at in stride(from: bytes.count - 22, through: earliest, by: -1) where le32(bytes, at) == 0x0605_4B50 {
			return at
		}
		throw ZipError.truncated
	}

	private static func inflate(_ data: Data, expected: Int) throws -> Data {
		guard expected > 0 else { return Data() }
		guard !data.isEmpty else { throw ZipError.inflateFailed }
		var output = Data(count: expected)
		let written = output.withUnsafeMutableBytes { destination in
			data.withUnsafeBytes { source in
				compression_decode_buffer(destination.bindMemory(to: UInt8.self).baseAddress!, expected,
				                          source.bindMemory(to: UInt8.self).baseAddress!, data.count, nil, COMPRESSION_ZLIB)
			}
		}
		guard written == expected else { throw ZipError.inflateFailed }
		return output
	}
}

private func le16(_ bytes: [UInt8], _ at: Int) -> Int { Int(bytes[at]) | Int(bytes[at + 1]) << 8 }
private func le32(_ bytes: [UInt8], _ at: Int) -> Int { le16(bytes, at) | le16(bytes, at + 2) << 16 }
