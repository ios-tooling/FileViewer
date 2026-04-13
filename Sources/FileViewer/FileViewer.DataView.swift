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

			let fullRows = data.count / bytesPerRow
			self.visibleRows = fullRows + (data.count % bytesPerRow == 0 ? 0 : 1)
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
							Text(rowData.hexString)
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
