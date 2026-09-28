import SwiftUI
import Suite

extension FileViewer {
	/// The Metadata tab's row for a zip file: how many files it holds, and the
	/// way into them.
	struct ZipContentsRow: View {
		let archive: FileViewerZipArchive
		let name: String

		var body: some View {
			NavigationLink {
				ZipContentsScreen(archive: archive, name: name)
			} label: {
				LabeledMeta(label: "Contents", data: archive.files.count == 1 ? "1 file" : "\(archive.files.count) files")
			}
		}
	}

	/// The files inside a zip, each opening in a file viewer of its own.
	struct ZipContentsScreen: View {
		let archive: FileViewerZipArchive
		let name: String

		var body: some View {
			List(archive.files) { entry in
				NavigationLink {
					ZipEntryScreen(archive: archive, entry: entry)
				} label: {
					ZipEntryRow(entry: entry)
				}
			}
			.listStyle(.plain)
			.overlay {
				if archive.files.isEmpty { Text("This archive is empty.").foregroundStyle(.secondary) }
			}
			.navigationTitle(name)
		}
	}

	struct ZipEntryRow: View {
		let entry: FileViewerZipArchive.Entry

		var body: some View {
			HStack {
				Text(entry.path)
					.font(.system(size: 14))
				Spacer()
				Text(Int64(entry.size).bytesString)
					.font(.caption)
					.foregroundStyle(.secondary)
			}
		}
	}

	/// One member, read out of the archive and shown like any other file.
	struct ZipEntryScreen: View {
		let archive: FileViewerZipArchive
		let entry: FileViewerZipArchive.Entry
		@State private var contents: Result<Data, any Error>?

		var body: some View {
			Group {
				switch contents {
				case nil:
					ProgressView()
				case .success(let data):
					FileViewer(data: data, name: entry.name)
				case .failure(let error):
					Text("Unable to read \(entry.name): \(String(describing: error))")
						.foregroundStyle(.secondary)
						.padding()
				}
			}
			.navigationTitle(entry.name)
			.task(id: entry) { contents = Result { try archive.data(for: entry) } }
		}
	}
}
