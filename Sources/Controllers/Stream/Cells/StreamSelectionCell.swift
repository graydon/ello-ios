////
///  StreamSelectionCell.swift
//

import SnapKit

class StreamSelectionCell: CollectionViewCell {
    static let reuseIdentifier = "StreamSelectionCell"

    struct Size {
        static let height: CGFloat = 45
        static let spacing: CGFloat = 1
    }

    var selectedStream: DiscoverType = .featured {
        didSet {
            switch selectedStream {
            case .featured: tabBar?.select(tab: featuredTab)
            case .trending: tabBar?.select(tab: trendingTab)
            case .recent: tabBar?.select(tab: recentTab)
            }
        }
    }
    var streams: [DiscoverType] = [.featured, .trending, .recent] {
        didSet { updateTabs() }
    }

    private var tabBar: NestedTabBarView?
    private var featuredTab: NestedTabBarView.Tab!
    private var trendingTab: NestedTabBarView.Tab!
    private var recentTab: NestedTabBarView.Tab!

    override func style() {
        backgroundColor = .white
        updateTabs()
    }

    private func updateTabs() {
        if let tabBar = self.tabBar {
            tabBar.removeFromSuperview()
        }

        let tabBar = NestedTabBarView()
        let tabs: [NestedTabBarView.Tab] = streams.map { stream in
            let tab = tabBar.createTab(title: stream.name)
            switch stream {
            case .featured:
                tab.addTarget(self, action: #selector(featuredTapped))
                featuredTab = tab
            case .trending:
                tab.addTarget(self, action: #selector(trendingTapped))
                trendingTab = tab
            case .recent:
                tab.addTarget(self, action: #selector(recentTapped))
                recentTab = tab
            }
            return tab
        }
        for tab in tabs {
            tabBar.addTab(tab)
        }
        tabBar.select(tab: tabs.first!)

        addSubview(tabBar)

        tabBar.snp.makeConstraints { make in
            make.edges.equalTo(contentView)
        }

        self.tabBar = tabBar
    }

    @objc
    func featuredTapped() {
        tabBar?.select(tab: featuredTab)
        let responder: StreamSelectionCellResponder? = findResponder()
        responder?.streamTapped(DiscoverType.featured.slug)
    }

    @objc
    func trendingTapped() {
        tabBar?.select(tab: trendingTab)
        let responder: StreamSelectionCellResponder? = findResponder()
        responder?.streamTapped(DiscoverType.trending.slug)
    }

    @objc
    func recentTapped() {
        tabBar?.select(tab: recentTab)
        let responder: StreamSelectionCellResponder? = findResponder()
        responder?.streamTapped(DiscoverType.recent.slug)
    }

}
