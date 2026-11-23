import CoreGraphics
import Foundation
import Testing
@testable import UI

internal struct HUDPlacementTests {
    private let size = CGSize(width: 120, height: 36)
    private let screen = CGRect(x: 0, y: 0, width: 1_440, height: 900)

    @Test
    func centersHorizontallyOnTheScreen() {
        let display = DisplayGeometry(frame: screen, visibleFrame: screen)
        let frame = HUDPlacement.frame(size: size, on: display)
        #expect(frame.midX == screen.midX)
    }

    @Test
    func sitsTwentyPointsAboveTheDockTop() {
        let visible = CGRect(x: 0, y: 70, width: 1_440, height: 800)
        let frame = HUDPlacement.frame(
            size: size,
            on: DisplayGeometry(frame: screen, visibleFrame: visible),
        )
        #expect(frame.minY == 90)
    }

    @Test
    func sitsTwentyPointsAboveTheBottomWhenTheDockIsHidden() {
        let frame = HUDPlacement.frame(
            size: size,
            on: DisplayGeometry(frame: screen, visibleFrame: screen),
        )
        #expect(frame.minY == 20)
    }

    @Test
    func widerContentGrowsSymmetrically() {
        let display = DisplayGeometry(frame: screen, visibleFrame: screen)
        let narrow = HUDPlacement.frame(size: size, on: display)
        let wide = HUDPlacement.frame(size: CGSize(width: 320, height: 36), on: display)
        #expect(wide.midX == narrow.midX)
        #expect(wide.minX < narrow.minX)
    }

    @Test
    func staysInsideTheVisibleFrameOnASecondDisplay() {
        let second = CGRect(x: 1_440, y: 0, width: 1_920, height: 1_080)
        let display = DisplayGeometry(frame: second, visibleFrame: second)
        let frame = HUDPlacement.frame(size: size, on: display)
        #expect(frame.midX == second.midX)
        #expect(second.contains(frame))
    }

    @Test
    func choosesTheDisplayWithTheLargestWindowOverlap() {
        let primary = DisplayGeometry(frame: screen, visibleFrame: screen)
        let secondFrame = CGRect(x: 1_440, y: 0, width: 1_920, height: 1_080)
        let secondary = DisplayGeometry(frame: secondFrame, visibleFrame: secondFrame)
        let window = CGRect(x: 1_300, y: 100, width: 800, height: 600)
        #expect(HUDPlacement.display(for: window, among: [primary, secondary]) == secondary)
    }

    @Test
    func fallsBackToTheFirstDisplayWithoutAWindow() {
        let primary = DisplayGeometry(frame: screen, visibleFrame: screen)
        let other = DisplayGeometry(
            frame: screen.offsetBy(dx: 1_440, dy: 0),
            visibleFrame: screen,
        )
        #expect(HUDPlacement.display(for: nil, among: [primary, other]) == primary)
    }

    @Test
    func fallsBackToTheFirstDisplayWhenTheWindowIsOffscreen() {
        let primary = DisplayGeometry(frame: screen, visibleFrame: screen)
        let window = CGRect(x: 9_000, y: 9_000, width: 10, height: 10)
        #expect(HUDPlacement.display(for: window, among: [primary]) == primary)
    }
}
