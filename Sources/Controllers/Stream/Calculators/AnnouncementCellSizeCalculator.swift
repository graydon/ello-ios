////
///  AnnouncementCellSizeCalculator.swift
//

class AnnouncementCellSizeCalculator {
    var originalWidth: CGFloat = 0

    private typealias CellJob = (cellItems: [StreamCellItem], width: CGFloat, completion: Block)
    private var cellJobs: [CellJob] = []
    private var cellItems: [StreamCellItem] = []

    static func calculateAnnouncementHeight(_ announcement: Announcement, cellWidth: CGFloat) -> CGFloat {
        let attributedTitle = NSAttributedString(label: announcement.header, style: .boldWhite)
        let attributedBody = NSAttributedString(label: announcement.body, style: .white)
        let attributedCTA = NSAttributedString(button: announcement.ctaCaption, style: .whiteUnderlined)

        let textWidth = cellWidth - AnnouncementCell.Size.margins - AnnouncementCell.Size.imageSize - AnnouncementCell.Size.textLeadingMargin - AnnouncementCell.Size.closeButtonSize
        var calcHeight: CGFloat = 0
        calcHeight += 2 * AnnouncementCell.Size.margins
        var textHeight: CGFloat = 0
        textHeight += attributedTitle.heightForWidth(textWidth)
        textHeight += AnnouncementCell.Size.textVerticalMargin
        textHeight += attributedBody.heightForWidth(textWidth)
        textHeight += AnnouncementCell.Size.textVerticalMargin
        textHeight += attributedCTA.heightForWidth(textWidth)

        let imageHeight: CGFloat
        if let attachment = announcement.preferredAttachment,
            let width = attachment.width.flatMap({ CGFloat($0) }),
            let height = attachment.height.flatMap({ CGFloat($0) })
        {
            imageHeight = height * AnnouncementCell.Size.imageSize / width
        }
        else {
            imageHeight = 0
        }
        return calcHeight + max(textHeight, imageHeight)
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

    private func finish() {
        guard let job = cellJobs.first else { return }
        cellJobs.remove(at: 0)
        job.completion()
        if let nextJob = cellJobs.safeValue(0) {
            processJob(nextJob)
        }
    }

    private func processJob(_ job: CellJob) {
        self.cellItems = job.cellItems
        self.originalWidth = job.width
        loadNext()
    }

    private func loadNext() {
        if let item = self.cellItems.safeValue(0) {
            if let announcement = item.jsonable as? Announcement {
                assignCellHeight(AnnouncementCellSizeCalculator.calculateAnnouncementHeight(announcement, cellWidth: originalWidth))
            }
            else {
                assignCellHeight(0)
            }
        }
        else {
            finish()
        }
    }

    private func assignCellHeight(_ height: CGFloat) {
        if let cellItem = self.cellItems.safeValue(0) {
            self.cellItems.remove(at: 0)
            cellItem.calculatedCellHeights.oneColumn = height
            cellItem.calculatedCellHeights.multiColumn = height
        }
        loadNext()
    }

}
