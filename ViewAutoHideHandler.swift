protocol ViewAutoHideHandlerDelegate: class {
    func updateViewTopConstraint(offset: CGFloat)
    func setContentOffset(_ point: CGPoint)
}

class ViewAutoHideHandler: NSObject {

    private var lastYContentOffset: CGFloat = 0
    fileprivate var yContentOffset: CGFloat = 0 {
        willSet {
            scrollDirectionIsUp = (newValue - yContentOffset) > 0
        }
    }
    private var scrollDirectionIsUp = true

    fileprivate let viewHeight: CGFloat
    fileprivate var viewTopOffset: CGFloat = 0

    weak var delegate: ViewAutoHideHandlerDelegate?

    init(viewHeight: CGFloat) {
        self.viewHeight = viewHeight
    }

    fileprivate func didScroll(newYContentOffset: CGFloat, oldYContentOffset: CGFloat, contentHeight: CGFloat) {
        if shouldUpdateTopOffset(newYContentOffset: newYContentOffset) {
            updateTopConstraint(newYContentOffset: newYContentOffset, oldYContentOffset: oldYContentOffset, contentHeight: contentHeight)

            updateLastYContentOffset(yContentOffset: oldYContentOffset)
        }
    }

    fileprivate func finalizeAnimations(for yContentOffset: CGFloat) {
        if isViewInTransition(for: yContentOffset) {
            let chipsClosedYOffset = self.yContentOffset + viewTopOffset + (scrollDirectionIsUp ? viewHeight : 0)

            delegate?.setContentOffset(CGPoint(x: 0, y: chipsClosedYOffset))
        }
    }

    private func isViewInTransition(for viewTopOffset: CGFloat) -> Bool {
        return viewTopOffset > -viewHeight && viewTopOffset < 0
    }

    private func shouldUpdateTopOffset(newYContentOffset: CGFloat) -> Bool {
        // View not in closed/open state
        return isViewInTransition(for: viewTopOffset)
            // View moved far enaugh
            || abs(lastYContentOffset - newYContentOffset) > 200
            // View at top
            || (newYContentOffset >= 0 && newYContentOffset <= viewHeight && !scrollDirectionIsUp)
    }

    private func updateTopConstraint(newYContentOffset: CGFloat, oldYContentOffset: CGFloat, contentHeight: CGFloat) {
        if newYContentOffset <= 0 {
            viewTopOffset = 0
        } else {
            viewTopOffset = min(max(viewTopOffset + oldYContentOffset - newYContentOffset, -viewHeight), 0)
        }

        delegate?.updateViewTopConstraint(offset: viewTopOffset)
    }

    private func updateLastYContentOffset(yContentOffset: CGFloat) {
        if !isViewInTransition(for: viewTopOffset) {
            lastYContentOffset = yContentOffset
        }
    }
}

extension ViewAutoHideHandler: AdCollectionEventHandler {
    func scrollViewDidScroll(yContentOffset: CGFloat, contentHeight: CGFloat) {
        didScroll(newYContentOffset: yContentOffset, oldYContentOffset: self.yContentOffset, contentHeight: contentHeight)

        self.yContentOffset = yContentOffset
    }

    func willEndDragging(at yContentOffset: CGFloat) {
        let viewFinalTopOffset = viewTopOffset + self.yContentOffset - yContentOffset

        finalizeAnimations(for: viewFinalTopOffset)
    }
}
