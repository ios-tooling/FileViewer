import SwiftUI
import Suite

extension FileViewer {
	struct DataView: View {
		let data: Data
		let bytesPerRow: Int
		let visibleRows: Int

		init(source: FileViewerSource) {
			self.data = source.data ?? Data()
			self.bytesPerRow = 12
			self.visibleRows = Self.visibleRows(byteCount: data.count, bytesPerRow: bytesPerRow)
		}

		static func visibleRows(byteCount: Int, bytesPerRow: Int) -> Int {
			guard bytesPerRow > 0 else { return 0 }
			let fullRows = byteCount / bytesPerRow
			return fullRows + (byteCount % bytesPerRow == 0 ? 0 : 1)
		}

		var body: some View {
			ScrollView {
				LazyVStack {
					ForEach(0..<visibleRows, id: \.self) { row in
						HStack {
							Text("\(row + 1)")
								.bold()
								.frame(width: 20)
								.minimumScaleFactor(0.5)

							let rowData = data.subdata(in: (row * bytesPerRow)..<(min((row + 1) * bytesPerRow, data.count)))
							Text(rowData.hexString.padding(toLength: bytesPerRow * 2, withPad: " ", startingAt: 0))
								.padding(.trailing, 5)

							Text(String(data: rowData, encoding: .ascii) ?? "")

							Spacer()
						}
					}
				}
				.multilineTextAlignment(.leading)
				.font(.system(size: 14).monospaced())
				.lineLimit(1)
			}
		}
	}
}
