import SwiftUI
import UniformTypeIdentifiers
import Suite
#if !os(watchOS)
import AVFoundation
#endif

extension UTType {
	var isAudio: Bool {
		conforms(to: .audio)
	}
}

extension FileViewer {
	struct MetadataView: View {
		let source: FileViewerSource

		var body: some View {
			switch source {
			case .url(let url): URLMetadataView(url: url)
			case .data(let data, let name, let type): DataMetadataView(data: data, name: name, explicitType: type)
			}
		}
	}

	struct DataMetadataView: View {
		let data: Data
		let name: String
		let explicitType: UTType?

		private var resolvedType: UTType {
			explicitType ?? UTType(filenameExtension: (name as NSString).pathExtension) ?? .data
		}

		var body: some View {
			List {
				LabeledMeta(label: "Name", data: name)
				LabeledMeta(label: "Type", data: resolvedType.identifier)
				LabeledMeta(label: "Size", data: Int64(data.count).bytesString)
				LabeledMeta(label: "Bytes", data: data.count.formatted() + " b")
			}
			.listStyle(.plain)
		}
	}

	struct URLMetadataView: View {
		let url: URL
		let resourceValues: [URLResourceKey: Any]
		@State private var audioDuration: TimeInterval?

		#if !os(watchOS)
		@State var player: AVPlayer?
		@StateObject var pokee = PokeableObject()

		func play() {
			if player == nil { player = AVPlayer(url: url) }

			if player?.isPlaying == true {
				player?.pause()
			} else {
				player?.play()
			}
			pokee.poke()
		}
		#endif

		init(url: URL) {
			self.url = url

			var values: [URLResourceKey: Any] = [:]
			let nsURL = url as NSURL
			for key in URLResourceKey.propertiesOfInterest {
				var object: AnyObject?
				do {
					try nsURL.getResourceValue(&object, forKey: key)
					if let object { values[key] = object }
				} catch {
					print("Failed to query \(key): \(error)")
				}
			}
			resourceValues = values
		}

		#if !os(watchOS)
		@ViewBuilder var controls: some View {
			if url.fileType?.isAudio == true {
				Button(action: { play() }) {
					Image(systemName: player?.isPlaying == true ? "pause.fill" : "play.fill")
						.font(.system(size: 22))
						.padding(10)
				}
			}
		}
		#endif

		var body: some View {
			List {
				#if !os(watchOS)
				controls
				#endif

				if let audioDuration {
					LabeledMeta(label: "Audio duration", data: audioDuration.durationString(style: .milliseconds, roundUp: false))
				}
				ForEach(URLResourceKey.propertiesOfInterest, id: \.rawValue) { key in
					if let object = resourceValues[key] {
						metaRow(for: key, object: object)
					}
				}
			}
			.listStyle(.plain)
			#if !os(watchOS)
			.task { audioDuration = try? await url.audioDuration }
			#endif
		}

		@ViewBuilder
		private func metaRow(for key: URLResourceKey, object: Any) -> some View {
			if let bool = object as? NSNumber, key.rawValue.contains("NSURLIs") {
				LabeledMeta(label: key.rawValue, data: bool.boolValue ? "true" : "false")
			} else if let date = object as? Date {
				LabeledMeta(label: key.rawValue, data: date.localTimeString())
			} else if let number = object as? NSNumber, key.rawValue.contains("Size") {
				LabeledMeta(label: key.rawValue, data: number.int64Value.bytesString)
				LabeledMeta(label: key.rawValue, data: number.int64Value.formatted() + "b")
			} else if let desc = object as? CustomStringConvertible {
				LabeledMeta(label: key.rawValue, data: desc.description)
			} else {
				LabeledMeta(label: key.rawValue, data: nil)
			}
		}
	}

	struct LabeledMeta: View {
		let label: String
		let data: String?

		var body: some View {
			HStack {
				Text(label)
					.font(.caption)
					.bold()

				Spacer()
				if let data {
					Text(data)
						.font(.system(size: 14))
						.multilineTextAlignment(.trailing)
				}
			}
		}
	}
}
