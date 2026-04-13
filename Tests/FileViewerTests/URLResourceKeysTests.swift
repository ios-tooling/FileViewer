import Testing
import Foundation
@testable import FileViewer

@Suite("URLResourceKey.propertiesOfInterest")
struct URLResourceKeysTests {

	@Test func propertiesOfInterestIsNotEmpty() {
		#expect(!URLResourceKey.propertiesOfInterest.isEmpty)
	}

	@Test func includesContentType() {
		#expect(URLResourceKey.propertiesOfInterest.contains(.contentTypeKey))
	}

	@Test func includesCreationDate() {
		#expect(URLResourceKey.propertiesOfInterest.contains(.creationDateKey))
	}

	@Test func includesModificationDate() {
		#expect(URLResourceKey.propertiesOfInterest.contains(.attributeModificationDateKey))
	}

	@Test func includesSizeKeys() {
		let keys = URLResourceKey.propertiesOfInterest
		#expect(keys.contains(.fileAllocatedSizeKey))
		#expect(keys.contains(.totalFileSizeKey))
		#expect(keys.contains(.totalFileAllocatedSizeKey))
	}

	@Test func includesPermissionKeys() {
		let keys = URLResourceKey.propertiesOfInterest
		#expect(keys.contains(.isReadableKey))
		#expect(keys.contains(.isWritableKey))
		#expect(keys.contains(.isExecutableKey))
	}

	@Test func includesUbiquitousItemKeys() {
		let keys = URLResourceKey.propertiesOfInterest
		#expect(keys.contains(.ubiquitousItemIsUploadedKey))
		#expect(keys.contains(.ubiquitousItemIsDownloadingKey))
	}

	@Test func includesLocalizedDescriptionKeys() {
		let keys = URLResourceKey.propertiesOfInterest
		#expect(keys.contains(.localizedNameKey))
		#expect(keys.contains(.localizedTypeDescriptionKey))
	}

	@Test func keysCanBeUsedAgainstActualURL() throws {
		// The keys should be valid for querying real URL resource values.
		try withTemporaryFile(content: Data("hello".utf8), name: "rsrc.txt") { url in
			let nsURL = url as NSURL
			var hadAtLeastOneSuccess = false
			for key in URLResourceKey.propertiesOfInterest {
				var value: AnyObject?
				do {
					try nsURL.getResourceValue(&value, forKey: key)
					hadAtLeastOneSuccess = true
				} catch {
					// Some keys may not apply to plain files; that's fine.
				}
			}
			#expect(hadAtLeastOneSuccess)
		}
	}
}
