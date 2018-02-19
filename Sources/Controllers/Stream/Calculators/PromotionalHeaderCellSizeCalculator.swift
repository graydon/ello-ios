////
///  PromotionalHeaderCellSizeCalculator.swift
//


class PromotionalHeaderCellSizeCalculator: NSObject {
    struct Size {
        static let minIpadHeight: CGFloat = 300
        static let minPhoneHeight: CGFloat = 150
    }

    let webView: UIWebView

    private typealias CellJob = (cellItems: [StreamCellItem], width: CGFloat, completion: Block)
    private var cellJobs: [CellJob] = []
    private var cellWidth: CGFloat = 0.0
    private var cellItems: [StreamCellItem] = []
    private var cellItem: StreamCellItem?
    private var completion: Block = {}

    init(webView: UIWebView = ElloWebView()) {
        self.webView = webView
        super.init()
        self.webView.delegate = self
    }

    func processCells(_ cellItems: [StreamCellItem], withWidth width: CGFloat, completion: @escaping Block) {
        guard cellItems.count > 0 else {
            completion()
            return
        }

        let job: CellJob = (cellItems: cellItems, width: width, completion: completion)
        cellJobs.append(job)
        if cellJobs.count == 1 {
            processJob(job)
        }
    }

    static func calculatePageHeaderHeight(_ pageHeader: PageHeader, htmlHeight: CGFloat?, cellWidth: CGFloat) -> CGFloat {
        let config = PromotionalHeaderCell.Config(pageHeader: pageHeader)
        return PromotionalHeaderCellSizeCalculator.calculateHeight(config, htmlHeight: htmlHeight, cellWidth: cellWidth)
    }

    static func calculateHeight(_ config: PromotionalHeaderCell.Config, htmlHeight: CGFloat?, cellWidth: CGFloat) -> CGFloat {
        var calcHeight: CGFloat = 0
        let textWidth = cellWidth - 2 * PromotionalHeaderCell.Size.defaultMargin
        let boundingSize = CGSize(width: textWidth, height: CGFloat.greatestFiniteMagnitude)

        let attributedTitle = config.attributedTitle
        calcHeight += PromotionalHeaderCell.Size.topMargin
        calcHeight += attributedTitle.heightForWidth(textWidth)

        if let htmlHeight = htmlHeight, config.hasHtml {
            calcHeight += htmlHeight
        }
        else if let attributedBody = config.attributedBody, !config.hasHtml {
            calcHeight += PromotionalHeaderCell.Size.bodySpacing
            calcHeight += attributedBody.heightForWidth(textWidth)
        }

        var ctaSize: CGSize = .zero
        var postedBySize: CGSize = .zero
        if let attributedCallToAction = config.attributedCallToAction {
            ctaSize = attributedCallToAction.boundingRect(with: boundingSize, options: [], context: nil).size.integral
        }

        if let attributedPostedBy = config.attributedPostedBy {
            postedBySize = attributedPostedBy.boundingRect(with: boundingSize, options: [], context: nil).size.integral
        }

        calcHeight += PromotionalHeaderCell.Size.bodySpacing
        if ctaSize.width + postedBySize.width > textWidth {
            calcHeight += ctaSize.height + PromotionalHeaderCell.Size.stackedMargin + postedBySize.height
        }
        else {
            calcHeight += max(ctaSize.height, postedBySize.height)
        }

        calcHeight += PromotionalHeaderCell.Size.defaultMargin
        return calcHeight
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
        self.cellItems = job.cellItems
        self.cellWidth = job.width
        var webWidth = job.width
        webWidth -= 2 * PromotionalHeaderCell.Size.defaultMargin
        webView.frame = webView.frame.with(width: webWidth)
        loadNext()
    }

    private func loadNext() {
        guard !self.cellItems.isEmpty else {
            self.cellItem = nil
            completion()
            return
        }

        let item = cellItems.remove(at: 0)
        self.cellItem = item

        let minHeight: CGFloat
        if Globals.isIpad {
            minHeight = Size.minIpadHeight
        }
        else {
            minHeight = Size.minPhoneHeight
        }

        var calcHeight: CGFloat?
        if let pageHeader = item.jsonable as? PageHeader {
            if pageHeader.kind == .category {
                calcHeight = PromotionalHeaderCellSizeCalculator.calculatePageHeaderHeight(pageHeader, htmlHeight: nil, cellWidth: cellWidth)
            }
            else {
                let text = pageHeader.subheader
                let html = StreamTextCellHTML.editorialHTML(text)
                webView.loadHTMLString(html, baseURL: URL(string: "/"))
            }
        }
        else {
            loadNext()
            return
        }

        if let calcHeight = calcHeight {
            let height = max(minHeight, calcHeight)
            assignHeight(height)
        }
    }

    private func assignHeight(_ height: CGFloat) {
        guard let item = cellItem else { return }
        item.calculatedCellHeights.oneColumn = height
        item.calculatedCellHeights.multiColumn = height
        loadNext()
    }
}

extension PromotionalHeaderCellSizeCalculator: UIWebViewDelegate {
    func webViewDidFinishLoad(_ webView: UIWebView) {
        guard
            let item = cellItem,
            let pageHeader = item.jsonable as? PageHeader
        else { return }

        let textHeight = webView.windowContentSize()?.height
        let calcHeight = PromotionalHeaderCellSizeCalculator.calculatePageHeaderHeight(pageHeader, htmlHeight: textHeight, cellWidth: cellWidth)
        let minHeight: CGFloat
        if Globals.isIpad {
            minHeight = Size.minIpadHeight
        }
        else {
            minHeight = Size.minPhoneHeight
        }
        let actualHeight = max(minHeight, calcHeight)
        assignHeight(actualHeight)
    }
}
