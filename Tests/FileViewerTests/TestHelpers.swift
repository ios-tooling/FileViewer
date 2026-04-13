import Foundation
@testable import FileViewer

/// Writes `content` to a temporary file with `name`, runs `work` with the URL,
/// then deletes the file. The file is also removed if `work` throws.
func withTemporaryFile<T>(
	content: Data,
	name: String,
	_ work: (URL) throws -> T
) rethrows -> T {
	let url = FileManager.default.temporaryDirectory
		.appendingPathComponent("FileViewerTests-\(UUID().uuidString)-\(name)")
	try? content.write(to: url)
	defer { try? FileManager.default.removeItem(at: url) }
	return try work(url)
}
