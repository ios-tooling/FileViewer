import Testing
import Foundation
import UniformTypeIdentifiers
@testable import FileViewer

@Suite("UTType extensions")
struct UTTypeExtensionsTests {

	// MARK: - isMovie

	@Test func movieUTTypeIsMovie() {
		#expect(UTType.movie.isMovie)
	}

	@Test func mpeg4MovieIsMovie() {
		#expect(UTType.mpeg4Movie.isMovie)
	}

	@Test func quickTimeMovieIsMovie() {
		#expect(UTType.quickTimeMovie.isMovie)
	}

	@Test func textIsNotMovie() {
		#expect(!UTType.text.isMovie)
	}

	@Test func jsonIsNotMovie() {
		#expect(!UTType.json.isMovie)
	}

	@Test func plainImageIsNotMovie() {
		#expect(!UTType.image.isMovie)
	}

	@Test func mp3IsNotMovieEvenThoughItsMedia() {
		#expect(!UTType.mp3.isMovie)
	}

	// MARK: - isAudio

	@Test func audioUTTypeIsAudio() {
		#expect(UTType.audio.isAudio)
	}

	@Test func mp3IsAudio() {
		#expect(UTType.mp3.isAudio)
	}

	@Test func wavIsAudio() {
		#expect(UTType.wav.isAudio)
	}

	@Test func textIsNotAudio() {
		#expect(!UTType.text.isAudio)
	}

	@Test func jsonIsNotAudio() {
		#expect(!UTType.json.isAudio)
	}

	@Test func movieIsNotAudio() {
		#expect(!UTType.movie.isAudio)
	}

	@Test func imageIsNotAudio() {
		#expect(!UTType.image.isAudio)
	}
}
