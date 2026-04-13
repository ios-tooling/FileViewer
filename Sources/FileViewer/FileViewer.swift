import SwiftUI
import UniformTypeIdentifiers

public struct FileViewer: View {
	let source: FileViewerSource
	@State private var formatDetails: FileViewerFormat?
	@AppStorage("file_viewer_tab") private var currentTab = Tab.metadata

	enum Tab: String { case metadata, contents, data, format }

	public init(source: FileViewerSource) {
		self.source = source
	}

	public init(url: URL) {
		self.init(source: .url(url))
	}

	public init(data: Data, name: String, type: UTType? = nil) {
		self.init(source: .data(data, name: name, type: type))
	}

	public var body: some View {
		TabView(selection: $currentTab) {
			MetadataView(source: source)
				.tabItem { Label("Metadata", systemImage: "list.clipboard") }
				.tag(Tab.metadata)

			ContentsView(source: source)
				.tabItem { Label("Contents", systemImage: "doc") }
				.tag(Tab.contents)

			DataView(source: source)
				.tabItem { Label("Data", systemImage: "doc.text.magnifyingglass") }
				.tag(Tab.data)

			if let formatter = fileViewerFormatter(for: source.pathExtension), let formatDetails {
				formatDetails.contentView
					.tabItem { Label(formatter.name, systemImage: "eye") }
					.tag(Tab.format)
			}
		}
		.navigationTitle(source.displayName)
		.onAppear { loadFormatter() }
	}

	private func loadFormatter() {
		guard let formatter = fileViewerFormatter(for: source.pathExtension) else { return }
		do {
			switch source {
			case .url(let url):
				formatDetails = try formatter.init(url: url)
			case .data(let data, let name, _):
				formatDetails = try formatter.init(data: data, name: name)
			}
		} catch {
			print("Unable to parse \(source.displayName) for \(formatter): \(error)")
		}
	}
}
