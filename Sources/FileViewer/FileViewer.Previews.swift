#if DEBUG
import SwiftUI
import Foundation
import UniformTypeIdentifiers

// MARK: - Sample data

private let sampleJSON: Data = """
{
	"title": "Sample Document",
	"version": 3,
	"tags": ["preview", "demo", "fileviewer"],
	"active": true,
	"metrics": {
		"downloads": 12045,
		"rating": 4.7
	}
}
""".data(using: .utf8) ?? Data()

private let sampleText: Data = """
Hello, world!

This is a plain text sample used by the FileViewer previews.
It contains a few lines so you can see how the Contents tab renders
unstructured text.
""".data(using: .utf8) ?? Data()

private let samplePlist: Data = {
	let dict: [String: Any] = [
		"identifier": "com.example.preview",
		"count": 42,
		"enabled": true,
		"items": ["one", "two", "three"],
	]
	return (try? PropertyListSerialization.data(fromPropertyList: dict, format: .xml, options: 0)) ?? Data()
}()

private let sampleBinary: Data = Data((0..<128).map { UInt8($0) })

// MARK: - Temp-file helpers for URL previews

private func previewTempFile(data: Data, name: String) -> URL {
	let url = FileManager.default.temporaryDirectory
		.appendingPathComponent("FileViewerPreview-\(name)")
	try? data.write(to: url)
	return url
}

// MARK: - FileViewer (top-level) previews

#Preview("FileViewer • Data / JSON") {
	FileViewer(data: sampleJSON, name: "config.json")
}

#Preview("FileViewer • Data / Text") {
	FileViewer(data: sampleText, name: "notes.txt")
}

#Preview("FileViewer • Data / Binary") {
	FileViewer(data: sampleBinary, name: "payload.bin")
}

#Preview("FileViewer • URL / Plist") {
	FileViewer(url: previewTempFile(data: samplePlist, name: "settings.plist"))
}

// MARK: - ContentsView previews

#Preview("ContentsView • JSON") {
	FileViewer.ContentsView(source: .data(sampleJSON, name: "config.json"))
}

#Preview("ContentsView • Text") {
	FileViewer.ContentsView(source: .data(sampleText, name: "notes.txt"))
}

#Preview("ContentsView • Binary fallback") {
	FileViewer.ContentsView(source: .data(sampleBinary, name: "payload.bin"))
}

// MARK: - DataView previews

#Preview("DataView • 128 bytes") {
	FileViewer.DataView(source: .data(sampleBinary, name: "payload.bin"))
}

#Preview("DataView • Empty") {
	FileViewer.DataView(source: .data(Data(), name: "empty.bin"))
}

#Preview("DataView • Single partial row") {
	FileViewer.DataView(source: .data(Data([0x48, 0x69, 0x21]), name: "tiny.bin"))
}

// MARK: - MetadataView previews

#Preview("MetadataView • Data source") {
	FileViewer.MetadataView(source: .data(sampleJSON, name: "config.json", type: .json))
}

#Preview("MetadataView • URL source") {
	FileViewer.MetadataView(source: .url(previewTempFile(data: sampleText, name: "notes.txt")))
}

// MARK: - LabeledMeta preview

#Preview("LabeledMeta") {
	List {
		FileViewer.LabeledMeta(label: "Name", data: "example.json")
		FileViewer.LabeledMeta(label: "Size", data: "1.2 KB")
		FileViewer.LabeledMeta(label: "Empty value", data: nil)
	}
	.listStyle(.plain)
}
#endif
