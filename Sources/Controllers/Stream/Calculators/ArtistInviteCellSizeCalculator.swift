////
///  ArtistInviteCellSizeCalculator.swift
//

class ArtistInviteCellSizeCalculator: NSObject {
    let webView: UIWebView
    private typealias CellJob = (cellItems: [StreamCellItem], width: CGFloat, hasCurrentUser: Bool, completion: Block)
    private var cellJobs: [CellJob] = []
    private var job: CellJob?
    private var completion: Block = {}

    init(webView: UIWebView = ElloWebView()) {
        self.webView = webView
        super.init()
        self.webView.delegate = self
    }

// MARK: Public

    func processCells(_ cellItems: [StreamCellItem], withWidth width: CGFloat, hasCurrentUser: Bool, completion: @escaping Block) {
        guard cellItems.count > 0 else {
            completion()
            return
        }

        let job: CellJob = (cellItems: cellItems, width: width, hasCurrentUser: hasCurrentUser, completion: completion)
        cellJobs.append(job)
        if cellJobs.count == 1 {
            processJob(job)
        }
    }

// MARK: Private

    private func processJob(_ job: CellJob) {
        self.completion = {
            if self.cellJobs.count > 0 {
                self.cellJobs.remove(at: 0)
            }
            job.completion()
            if let nextJob = self.cellJobs.safeValue(0) {
                self.processJob(nextJob)
            }
        }

        self.job = job
        var webWidth = job.width
        webWidth -= ArtistInviteBubbleCell.Size.bubbleMargins.sides
        webWidth -= ArtistInviteBubbleCell.Size.descriptionMargins.sides
        webView.frame = webView.frame.with(width: webWidth)

        loadNext()
    }

    private func loadNext() {
        guard let job = job else { return }
        guard let cellItem = job.cellItems.first else {
            completion()
            return
        }

        guard let artistInvite = cellItem.jsonable as? ArtistInvite else {
            skipCellItem()
            return
        }

        switch cellItem.type {
        case .artistInviteBubble:
            loadBubbleHTML(cellItem, artistInvite)
        case .artistInviteHeader:
            assignHeight(webHeight: 0)
        case .artistInviteControls:
            loadControlsHTML(cellItem, artistInvite)
        case .artistInviteGuide:
            loadGuideHTML(cellItem, artistInvite)
        default:
            skipCellItem()
        }
    }

    private func loadBubbleHTML(_ cellItem: StreamCellItem, _ artistInvite: ArtistInvite) {
        let text = artistInvite.shortDescription
        let html = StreamTextCellHTML.artistInviteHTML(text)
        webView.loadHTMLString(html, baseURL: URL(string: "/"))
    }

    private func loadControlsHTML(_ cellItem: StreamCellItem, _ artistInvite: ArtistInvite) {
        let text = artistInvite.longDescription
        let html = StreamTextCellHTML.postHTML(text)
        webView.loadHTMLString(html, baseURL: URL(string: "/"))
    }

    private func loadGuideHTML(_ cellItem: StreamCellItem, _ artistInvite: ArtistInvite) {
        guard let guide = cellItem.type.data as? ArtistInvite.Guide else {
            skipCellItem()
            return
        }
        let text = guide.html
        let html = StreamTextCellHTML.artistInviteGuideHTML(text)
        webView.loadHTMLString(html, baseURL: URL(string: "/"))
    }

    @discardableResult
    private func removeFirstItem() -> StreamCellItem? {
        guard var job = job, !job.cellItems.isEmpty else { return nil }
        let cellItem = job.cellItems.remove(at: 0)
        self.job = job  // job is a struct, so we need to reassign it after modifying it
        return cellItem
    }

    private func skipCellItem() {
        removeFirstItem()
        loadNext()
    }

    private func assignHeight(webHeight: CGFloat) {
        defer {
            loadNext()
        }

        guard
            let job = job,
            let cellItem = removeFirstItem()
        else { return }

        let calculatedHeight: CGFloat?
        switch cellItem.type {
        case .artistInviteBubble:
            calculatedHeight = calculateBubbleHeight(cellItem, webHeight)
        case .artistInviteHeader:
            calculatedHeight = calculateHeaderHeight(cellItem)
        case .artistInviteControls:
            calculatedHeight = calculateControlsHeight(cellItem, webHeight, hasCurrentUser: job.hasCurrentUser)
        case .artistInviteGuide:
            calculatedHeight = calculateGuideHeight(cellItem, webHeight)
        default:
            calculatedHeight = nil
        }

        if let height = calculatedHeight {
            cellItem.calculatedCellHeights.webContent = height
            cellItem.calculatedCellHeights.oneColumn = height
            cellItem.calculatedCellHeights.multiColumn = height
        }
    }

    private func calculateBubbleHeight(_ cellItem: StreamCellItem, _ webHeight: CGFloat) -> CGFloat {
        var totalHeight = webHeight
        totalHeight += ArtistInviteBubbleCell.Size.bubbleMargins.top
        totalHeight += ArtistInviteBubbleCell.Size.headerImageHeight
        if let width = job?.width,
            let artistInvite = cellItem.jsonable as? ArtistInvite
        {
            totalHeight += ArtistInviteBubbleCell.calculateDynamicHeights(title: artistInvite.title, inviteType: artistInvite.inviteType, cellWidth: width)
        }
        totalHeight += ArtistInviteBubbleCell.Size.infoTotalHeight
        totalHeight += (webHeight > 0 ? ArtistInviteBubbleCell.Size.descriptionMargins.bottom : 0)
        totalHeight += ArtistInviteBubbleCell.Size.bubbleMargins.bottom
        return totalHeight
    }

    private func calculateHeaderHeight(_ cellItem: StreamCellItem) -> CGFloat {
        var totalHeight: CGFloat = 0
        totalHeight += ArtistInviteHeaderCell.Size.headerImageHeight
        totalHeight += ArtistInviteHeaderCell.Size.remainingTextHeight
        if let width = job?.width,
            let artistInvite = cellItem.jsonable as? ArtistInvite
        {
            totalHeight += ArtistInviteHeaderCell.calculateDynamicHeights(title: artistInvite.title, inviteType: artistInvite.inviteType, cellWidth: width)
        }
        return totalHeight
    }

    private func calculateControlsHeight(_ cellItem: StreamCellItem, _ webHeight: CGFloat, hasCurrentUser: Bool) -> CGFloat {
        let isOpen: Bool
        if let artistInvite = cellItem.jsonable as? ArtistInvite {
            isOpen = artistInvite.status == .open
        }
        else {
            isOpen = false
        }

        var totalHeight = webHeight
        if hasCurrentUser && isOpen {
            totalHeight += ArtistInviteControlsCell.Size.controlsHeight
        }
        else {
            totalHeight += ArtistInviteControlsCell.Size.loggedOutControlsHeight
        }
        return totalHeight
    }

    private func calculateGuideHeight(_ cellItem: StreamCellItem, _ webHeight: CGFloat) -> CGFloat {
        return ArtistInviteGuideCell.Size.otherHeights + webHeight
    }
}

extension ArtistInviteCellSizeCalculator: UIWebViewDelegate {
    func webViewDidFinishLoad(_ webView: UIWebView) {
        let textHeight = webView.windowContentSize()?.height
        assignHeight(webHeight: textHeight ?? 0)
    }
}
