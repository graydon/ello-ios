////
///  ProfileStatsSizeCalculator.swift
//

import PromiseKit


struct ProfileStatsSizeCalculator {

    func calculate(_ item: StreamCellItem) -> Guarantee<CGFloat> {
        let height = ProfileStatsView.Size.height
        return .value(height)
    }
}
