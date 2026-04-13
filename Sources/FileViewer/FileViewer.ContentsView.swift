import SwiftUI
import UniformTypeIdentifiers
import Suite
#if !os(watchOS)
import AVKit
#endif

extension UTType {
	var isMovie: Bool {
		conforms(to: .movie) || conforms(to: .audiovisualContent) && !isAudio
	}
}

extension FileViewer {
	struct ContentsView: View {
		let source: FileViewerSource
		let fileType: UTType

		#if !os(watchOS)
		@State var player: AVPlayer?
		@State var temporaryMovieURL: URL?
		#endif

		init(source: FileViewerSource) {
			self.source = source
			self.fileType = source.fileType

			#if !os(watchOS)
			if fileType.isMovie, let playbackURL = Self.playbackURL(for: source) {
				_player = State(initialValue: AVPlayer(url: playbackURL.url))
				_temporaryMovieURL = State(initialValue: playbackURL.temporary)
			}
			#endif
		}

		var body: some View {
			#if !os(watchOS)
			if fileType.isMovie, let player {
				VideoPlayer(player: player)
					.onAppear { player.play() }
					.onDisappear {
						player.pause()
						if let temporaryMovieURL { try? FileManager.default.removeItem(at: temporaryMovieURL) }
					}
			} else {
				scrollableContents
			}
			#else
			scrollableContents
			#endif
		}

		private var scrollableContents: some View {
			ScrollView {
				VStack {
					switch fileType {
					case .json:
						Text(source.data?.prettyPrintedJSON ?? "Unable to display")

					case .text, .xml, .xmlPropertyList:
						Text(stringContent ?? "Unable to display")

					default:
						Text(fileType.description)
						Text(propertyListContent ?? "Unable to display")
					}
				}
				.multilineTextAlignment(.leading)
				.font(.system(size: 14).monospaced())
			}
		}

		private var stringContent: String? {
			guard let data = source.data else { return nil }
			return String(data: data, encoding: .utf8)
		}

		private var propertyListContent: String? {
			guard let data = source.data else { return nil }
			let json = data.jsonDictionary ?? data.propertyList?.jsonDictionary
			return json?.prettyPrinted
		}

		#if !os(watchOS)
		private static func playbackURL(for source: FileViewerSource) -> (url: URL, temporary: URL?)? {
			switch source {
			case .url(let url):
				return (url, nil)
			case .data(let data, let name, _):
				let ext = (name as NSString).pathExtension
				let filename = ext.isEmpty ? "movie-\(UUID().uuidString)" : "movie-\(UUID().uuidString).\(ext)"
				let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
				do {
					try data.write(to: tempURL)
					return (tempURL, tempURL)
				} catch {
					return nil
				}
			}
		}
		#endif
	}
}
