import SwiftUI
import UIKit

struct RecapSwipeAction {
    let title: String
    let foregroundColor: Color
    let backgroundColor: Color
    let handler: () -> Void

    static func cardActions(
        onEdit: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) -> [RecapSwipeAction] {
        [
            RecapSwipeAction(
                title: "수정",
                foregroundColor: Color.recapGray700,
                backgroundColor: Color.recapGray50,
                handler: onEdit
            ),
            RecapSwipeAction(
                title: "삭제",
                foregroundColor: Color.recapDestructiveText,
                backgroundColor: Color.recapDestructiveSoft,
                handler: onDelete
            )
        ]
    }
}

/// SwiftUI 카드 행의 모양은 유지하고, 목록 스크롤과 스와이프 중재는 UIKit이 담당한다.
///
/// 행마다 pan recognizer를 만들지 않고 collection view에 하나만 두어,
/// 세로 스크롤이 시작될 때 모든 행이 제스처 경쟁에 참여하는 비용을 피한다.
struct RecapSwipeCardCollection<Item: Identifiable>: UIViewRepresentable where Item.ID: Hashable & Sendable {
    typealias RowContent = (Item) -> AnyView
    typealias Actions = (Item) -> [RecapSwipeAction]

    let items: [Item]
    let header: AnyView
    let headerHeight: CGFloat
    let rowHeight: CGFloat
    let isLoading: Bool
    let horizontalInset: CGFloat
    let topInset: CGFloat
    let bottomInset: CGFloat
    let rowContent: RowContent
    let actions: Actions
    let onSelect: (Item) -> Void
    let onWillDisplay: (Item) -> Void

    init(
        items: [Item],
        header: AnyView,
        headerHeight: CGFloat,
        rowHeight: CGFloat = 108,
        isLoading: Bool,
        horizontalInset: CGFloat = 0,
        topInset: CGFloat = 0,
        bottomInset: CGFloat = 0,
        rowContent: @escaping RowContent,
        actions: @escaping Actions,
        onSelect: @escaping (Item) -> Void,
        onWillDisplay: @escaping (Item) -> Void
    ) {
        self.items = items
        self.header = header
        self.headerHeight = headerHeight
        self.rowHeight = rowHeight
        self.isLoading = isLoading
        self.horizontalInset = horizontalInset
        self.topInset = topInset
        self.bottomInset = bottomInset
        self.rowContent = rowContent
        self.actions = actions
        self.onSelect = onSelect
        self.onWillDisplay = onWillDisplay
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> UICollectionView {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = UIColor(Color.recapBackground)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.alwaysBounceVertical = true
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.register(
            RecapSwipeCollectionCell.self,
            forCellWithReuseIdentifier: RecapSwipeCollectionCell.reuseIdentifier
        )
        collectionView.register(
            UICollectionViewCell.self,
            forCellWithReuseIdentifier: Coordinator.plainCellReuseIdentifier
        )

        context.coordinator.configure(collectionView)
        return collectionView
    }

    func updateUIView(_ collectionView: UICollectionView, context: Context) {
        context.coordinator.update(
            items: items,
            header: header,
            headerHeight: headerHeight,
            rowHeight: rowHeight,
            isLoading: isLoading,
            horizontalInset: horizontalInset,
            topInset: topInset,
            bottomInset: bottomInset,
            rowContent: rowContent,
            actions: actions,
            onSelect: onSelect,
            onWillDisplay: onWillDisplay
        )
    }

    @MainActor
    final class Coordinator: NSObject,
        UICollectionViewDelegateFlowLayout,
        UIGestureRecognizerDelegate {

        fileprivate static var plainCellReuseIdentifier: String { "RecapSwipeCollectionPlainCell" }

        private enum Section: Hashable, Sendable {
            case main
        }

        private enum Element: Hashable, Sendable {
            case header
            case row(Item.ID)
            case loading
        }

        private weak var collectionView: UICollectionView?
        private var dataSource: UICollectionViewDiffableDataSource<Section, Element>?
        private var itemsByID: [Item.ID: Item] = [:]

        private var header = AnyView(EmptyView())
        private var headerHeight: CGFloat = 0
        private var rowHeight: CGFloat = 108
        private var horizontalInset: CGFloat = 0
        private var topInset: CGFloat = 0
        private var bottomInset: CGFloat = 0
        private var rowContent: RowContent = { _ in AnyView(EmptyView()) }
        private var actions: Actions = { _ in [] }
        private var onSelect: (Item) -> Void = { _ in }
        private var onWillDisplay: (Item) -> Void = { _ in }

        private var activeCell: RecapSwipeCollectionCell?
        private var activeItemID: Item.ID?
        private var openItemID: Item.ID?
        private var initialOffset: CGFloat = 0

        func configure(_ collectionView: UICollectionView) {
            self.collectionView = collectionView
            collectionView.delegate = self

            dataSource = UICollectionViewDiffableDataSource<Section, Element>(
                collectionView: collectionView
            ) { [weak self] collectionView, indexPath, element in
                guard let self else { return nil }
                return makeCell(in: collectionView, at: indexPath, for: element)
            }

            let horizontalPan = UIPanGestureRecognizer(target: self, action: #selector(handleHorizontalPan))
            horizontalPan.delegate = self
            horizontalPan.maximumNumberOfTouches = 1
            horizontalPan.cancelsTouchesInView = true
            collectionView.addGestureRecognizer(horizontalPan)
        }

        func update(
            items: [Item],
            header: AnyView,
            headerHeight: CGFloat,
            rowHeight: CGFloat,
            isLoading: Bool,
            horizontalInset: CGFloat,
            topInset: CGFloat,
            bottomInset: CGFloat,
            rowContent: @escaping RowContent,
            actions: @escaping Actions,
            onSelect: @escaping (Item) -> Void,
            onWillDisplay: @escaping (Item) -> Void
        ) {
            let layoutDidChange = self.headerHeight != headerHeight
                || self.rowHeight != rowHeight
                || self.horizontalInset != horizontalInset
                || self.topInset != topInset
                || self.bottomInset != bottomInset

            self.header = header
            self.headerHeight = headerHeight
            self.rowHeight = rowHeight
            self.horizontalInset = horizontalInset
            self.topInset = topInset
            self.bottomInset = bottomInset
            self.rowContent = rowContent
            self.actions = actions
            self.onSelect = onSelect
            self.onWillDisplay = onWillDisplay
            itemsByID = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })

            if layoutDidChange,
               let layout = collectionView?.collectionViewLayout as? UICollectionViewFlowLayout {
                layout.sectionInset = UIEdgeInsets(
                    top: 0,
                    left: horizontalInset,
                    bottom: 0,
                    right: horizontalInset
                )
            }
            if layoutDidChange {
                collectionView?.contentInset = UIEdgeInsets(
                    top: topInset,
                    left: 0,
                    bottom: bottomInset,
                    right: 0
                )
            }

            if let openItemID, itemsByID[openItemID] == nil {
                self.openItemID = nil
            }

            var snapshot = NSDiffableDataSourceSnapshot<Section, Element>()
            snapshot.appendSections([.main])
            snapshot.appendItems([.header])
            snapshot.appendItems(items.map { .row($0.id) })
            if isLoading {
                snapshot.appendItems([.loading])
            }

            guard let dataSource else { return }
            if dataSource.snapshot().itemIdentifiers == snapshot.itemIdentifiers {
                refreshVisibleCells()
            } else {
                dataSource.apply(snapshot, animatingDifferences: false)
            }
            if layoutDidChange {
                collectionView?.collectionViewLayout.invalidateLayout()
            }
        }

        private func refreshVisibleCells() {
            guard let collectionView else { return }
            for indexPath in collectionView.indexPathsForVisibleItems {
                guard let element = dataSource?.itemIdentifier(for: indexPath) else { continue }

                switch element {
                case .header:
                    collectionView.cellForItem(at: indexPath)?.contentConfiguration =
                        UIHostingConfiguration { header }.margins(.all, 0)
                case .loading:
                    break
                case .row(let itemID):
                    guard
                        let item = itemsByID[itemID],
                        let cell = collectionView.cellForItem(at: indexPath) as? RecapSwipeCollectionCell
                    else { continue }
                    cell.configure(
                        content: rowContent(item),
                        actions: actions(item),
                        isOpen: openItemID == itemID,
                        closeAfterAction: { [weak self] in
                            self?.closeOpenCell(animated: true)
                        }
                    )
                }
            }
        }

        private func makeCell(
            in collectionView: UICollectionView,
            at indexPath: IndexPath,
            for element: Element
        ) -> UICollectionViewCell {
            switch element {
            case .header:
                let cell = plainCell(in: collectionView, at: indexPath)
                cell.contentConfiguration = UIHostingConfiguration { header }
                    .margins(.all, 0)
                return cell

            case .loading:
                let cell = plainCell(in: collectionView, at: indexPath)
                cell.contentConfiguration = UIHostingConfiguration {
                    ProgressView()
                        .tint(Color.recapBlue300)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .margins(.all, 0)
                return cell

            case .row(let itemID):
                guard
                    let item = itemsByID[itemID],
                    let cell = collectionView.dequeueReusableCell(
                        withReuseIdentifier: RecapSwipeCollectionCell.reuseIdentifier,
                        for: indexPath
                    ) as? RecapSwipeCollectionCell
                else {
                    return UICollectionViewCell()
                }

                cell.configure(
                    content: rowContent(item),
                    actions: actions(item),
                    isOpen: openItemID == itemID,
                    closeAfterAction: { [weak self] in
                        self?.closeOpenCell(animated: true)
                    }
                )
                return cell
            }
        }

        private func plainCell(
            in collectionView: UICollectionView,
            at indexPath: IndexPath
        ) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: Self.plainCellReuseIdentifier,
                for: indexPath
            )
            cell.backgroundConfiguration = UIBackgroundConfiguration.clear()
            return cell
        }

        func collectionView(
            _ collectionView: UICollectionView,
            layout collectionViewLayout: UICollectionViewLayout,
            sizeForItemAt indexPath: IndexPath
        ) -> CGSize {
            guard let element = dataSource?.itemIdentifier(for: indexPath) else {
                return .zero
            }

            let height: CGFloat
            switch element {
            case .header: height = headerHeight
            case .row: height = rowHeight
            case .loading: height = 60
            }
            let sectionInset = (collectionViewLayout as? UICollectionViewFlowLayout)?.sectionInset ?? .zero
            let horizontalInsets = sectionInset.left + sectionInset.right
            return CGSize(width: collectionView.bounds.width - horizontalInsets, height: height)
        }

        func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            collectionView.deselectItem(at: indexPath, animated: false)
            guard case .row(let itemID) = dataSource?.itemIdentifier(for: indexPath) else { return }

            if openItemID != nil {
                closeOpenCell(animated: true)
                return
            }
            guard let item = itemsByID[itemID] else { return }
            onSelect(item)
        }

        func collectionView(
            _ collectionView: UICollectionView,
            willDisplay cell: UICollectionViewCell,
            forItemAt indexPath: IndexPath
        ) {
            guard
                case .row(let itemID) = dataSource?.itemIdentifier(for: indexPath),
                let item = itemsByID[itemID]
            else { return }

            (cell as? RecapSwipeCollectionCell)?.setOpen(openItemID == itemID, animated: false)
            onWillDisplay(item)
        }

        func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
            closeOpenCell(animated: true)
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard
                let pan = gestureRecognizer as? UIPanGestureRecognizer,
                let collectionView,
                abs(pan.velocity(in: collectionView).x) > abs(pan.velocity(in: collectionView).y)
            else {
                return false
            }

            let point = pan.location(in: collectionView)
            guard
                let indexPath = collectionView.indexPathForItem(at: point),
                case .row(let itemID) = dataSource?.itemIdentifier(for: indexPath),
                let item = itemsByID[itemID],
                !actions(item).isEmpty
            else {
                return false
            }
            return true
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            otherGestureRecognizer === collectionView?.panGestureRecognizer
        }

        @objc private func handleHorizontalPan(_ recognizer: UIPanGestureRecognizer) {
            guard let collectionView else { return }

            switch recognizer.state {
            case .began:
                beginSwipe(recognizer, in: collectionView)
            case .changed:
                updateSwipe(recognizer, in: collectionView)
            case .ended:
                endSwipe(recognizer, in: collectionView)
            case .cancelled, .failed:
                settleActiveCell(open: activeItemID == openItemID)
            default:
                break
            }
        }

        private func beginSwipe(_ recognizer: UIPanGestureRecognizer, in collectionView: UICollectionView) {
            let point = recognizer.location(in: collectionView)
            guard
                let indexPath = collectionView.indexPathForItem(at: point),
                case .row(let itemID) = dataSource?.itemIdentifier(for: indexPath),
                let cell = collectionView.cellForItem(at: indexPath) as? RecapSwipeCollectionCell
            else { return }

            if openItemID != itemID {
                closeOpenCell(animated: true)
            }
            activeCell = cell
            activeItemID = itemID
            initialOffset = openItemID == itemID ? -cell.revealWidth : 0
        }

        private func updateSwipe(_ recognizer: UIPanGestureRecognizer, in collectionView: UICollectionView) {
            guard let activeCell else { return }
            let proposedOffset = initialOffset + recognizer.translation(in: collectionView).x
            activeCell.setRevealOffset(min(0, max(-activeCell.revealWidth, proposedOffset)))
        }

        private func endSwipe(_ recognizer: UIPanGestureRecognizer, in collectionView: UICollectionView) {
            guard let activeCell, let activeItemID else { return }
            let velocityX = recognizer.velocity(in: collectionView).x
            let proposedOffset = initialOffset + recognizer.translation(in: collectionView).x
            let currentOffset = min(0, max(-activeCell.revealWidth, proposedOffset))
            activeCell.setRevealOffset(currentOffset)
            let shouldOpen: Bool
            if velocityX < -300 {
                shouldOpen = true
            } else if velocityX > 300 {
                shouldOpen = false
            } else {
                shouldOpen = currentOffset < -activeCell.revealWidth * 0.4
            }
            openItemID = shouldOpen ? activeItemID : nil
            settleActiveCell(open: shouldOpen)
        }

        private func settleActiveCell(open: Bool) {
            activeCell?.setOpen(open, animated: true)
            activeCell = nil
            activeItemID = nil
            initialOffset = 0
        }

        private func closeOpenCell(animated: Bool) {
            guard let openItemID else { return }
            self.openItemID = nil

            guard
                let indexPath = dataSource?.indexPath(for: .row(openItemID)),
                let cell = collectionView?.cellForItem(at: indexPath) as? RecapSwipeCollectionCell
            else { return }
            cell.setOpen(false, animated: animated)
        }
    }
}

@MainActor
private final class RecapSwipeCollectionCell: UICollectionViewCell {
    static let reuseIdentifier = "RecapSwipeCollectionCell"
    private static let actionWidth: CGFloat = 74

    private let actionStack = UIStackView()
    private let foregroundContainer = UIView()
    private var hostedContentView: (UIView & UIContentView)?
    private var actionButtons: [UIButton] = []
    private var actionHandlers: [() -> Void] = []
    private var closeAfterAction: () -> Void = {}

    var revealWidth: CGFloat {
        Self.actionWidth * CGFloat(actionHandlers.count)
    }

    var revealOffset: CGFloat {
        foregroundContainer.transform.tx
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureLayers()
        clipsToBounds = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        foregroundContainer.transform = .identity
        actionHandlers = []
        closeAfterAction = {}
        actionStack.accessibilityElementsHidden = true
    }

    func configure(
        content: AnyView,
        actions: [RecapSwipeAction],
        isOpen: Bool,
        closeAfterAction: @escaping () -> Void
    ) {
        self.closeAfterAction = closeAfterAction
        actionHandlers = actions.map(\.handler)
        configureActionButtons(actions)
        configureHostedContent(content)
        backgroundConfiguration = UIBackgroundConfiguration.clear()
        setOpen(isOpen, animated: false)
    }

    func setRevealOffset(_ offset: CGFloat) {
        foregroundContainer.transform = CGAffineTransform(translationX: offset, y: 0)
        actionStack.accessibilityElementsHidden = offset >= -0.5
    }

    func setOpen(_ isOpen: Bool, animated: Bool) {
        let changes = { [self] in
            setRevealOffset(isOpen ? -revealWidth : 0)
        }
        guard animated else {
            changes()
            return
        }
        UIViewPropertyAnimator.runningPropertyAnimator(
            withDuration: 0.25,
            delay: 0,
            options: [.curveEaseOut, .allowUserInteraction],
            animations: changes
        )
    }

    private func configureLayers() {
        contentView.backgroundColor = UIColor(Color.recapBackground)
        contentView.clipsToBounds = true
        actionStack.axis = .horizontal
        actionStack.spacing = 0
        actionStack.accessibilityElementsHidden = true
        actionStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(actionStack)

        foregroundContainer.backgroundColor = UIColor(Color.recapBackground)
        foregroundContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(foregroundContainer)

        NSLayoutConstraint.activate([
            actionStack.topAnchor.constraint(equalTo: contentView.topAnchor),
            actionStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            actionStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            foregroundContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            foregroundContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            foregroundContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            foregroundContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    private func configureHostedContent(_ content: AnyView) {
        let configuration = UIHostingConfiguration { content }
            .margins(.all, 0)

        if let hostedContentView {
            hostedContentView.configuration = configuration
            return
        }

        let hostedView = configuration.makeContentView()
        hostedView.translatesAutoresizingMaskIntoConstraints = false
        foregroundContainer.addSubview(hostedView)
        NSLayoutConstraint.activate([
            hostedView.topAnchor.constraint(equalTo: foregroundContainer.topAnchor),
            hostedView.leadingAnchor.constraint(equalTo: foregroundContainer.leadingAnchor),
            hostedView.trailingAnchor.constraint(equalTo: foregroundContainer.trailingAnchor),
            hostedView.bottomAnchor.constraint(equalTo: foregroundContainer.bottomAnchor)
        ])
        hostedContentView = hostedView
    }

    private func configureActionButtons(_ actions: [RecapSwipeAction]) {
        if actionButtons.count != actions.count {
            actionStack.arrangedSubviews.forEach {
                actionStack.removeArrangedSubview($0)
                $0.removeFromSuperview()
            }
            actionButtons = actions.indices.map { index in
                let button = UIButton(type: .custom)
                button.tag = index
                button.layer.cornerRadius = 0
                button.clipsToBounds = true
                button.translatesAutoresizingMaskIntoConstraints = false
                button.widthAnchor.constraint(equalToConstant: Self.actionWidth).isActive = true
                button.addTarget(self, action: #selector(handleActionButton(_:)), for: .touchUpInside)
                actionStack.addArrangedSubview(button)
                return button
            }
        }

        for (button, action) in zip(actionButtons, actions) {
            button.backgroundColor = UIColor(action.backgroundColor)
            button.accessibilityLabel = action.title

            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont(name: "Pretendard-SemiBold", size: 14)
                    ?? UIFont.systemFont(ofSize: 14, weight: .semibold),
                .foregroundColor: UIColor(action.foregroundColor),
                .kern: -0.28
            ]
            button.setAttributedTitle(
                NSAttributedString(string: action.title, attributes: attributes),
                for: .normal
            )
        }
    }

    @objc private func handleActionButton(_ sender: UIButton) {
        guard actionHandlers.indices.contains(sender.tag) else { return }
        actionHandlers[sender.tag]()
        closeAfterAction()
    }
}
