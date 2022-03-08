import UIKit
import SafariServices




class VideosViewController: UICollectionViewController {
  // MARK: - Properties
  private var videoList = Video.allVideos
  
  enum Section {
    case main
  }
    
  typealias DataSource = UICollectionViewDiffableDataSource<Section, Video>
  typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Video>
  
  private lazy var dataSource = makeDataSource()
  
  
  private var searchController = UISearchController(searchResultsController: nil)
  
  // MARK: - Value Types
  
  // MARK: - Life Cycles
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white
    configureSearchController()
    configureLayout()
    
    applySnapshot(animatingDifferences: false)
  }
  
  // MARK: - Functions
  func makeDataSource() -> DataSource {
    let dataSource = DataSource(collectionView: collectionView,
                                cellProvider: { (collectionView, indexPath, video) -> UICollectionViewCell? in
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VideoCollectionViewCell", for: indexPath) as? VideoCollectionViewCell
      cell?.video = video
      return cell
    })
    return dataSource
  }
  
  // Create Snapshot
  func applySnapshot(animatingDifferences: Bool = true) {
    var snapshot = Snapshot()
    snapshot.appendSections([.main])
    snapshot.appendItems(videoList)
    dataSource.apply(snapshot, animatingDifferences: animatingDifferences)
  }
  
}

// MARK: - UICollectionViewDelegate
extension VideosViewController {
  override func collectionView(
    _ collectionView: UICollectionView,
    didSelectItemAt indexPath: IndexPath
  ) {
    
    // The ensures the app retrives vedios directly from the dataSource because UICollectionViewDiffableDataSource might do work in the background that makes videoList inconsistent with the currently displayed data
    guard let video = dataSource.itemIdentifier(for: indexPath) else {
      return
    }
    
    guard let link = video.link else {
      print("Invalid link")
      return
    }
    let safariViewController = SFSafariViewController(url: link)
    present(safariViewController, animated: true, completion: nil)
  }
}

// MARK: - UISearchResultsUpdating Delegate
extension VideosViewController: UISearchResultsUpdating {
  func updateSearchResults(for searchController: UISearchController) {
    videoList = filteredVideos(for: searchController.searchBar.text)
    applySnapshot()
  }
  
  func filteredVideos(for queryOrNil: String?) -> [Video] {
    let videos = Video.allVideos
    guard
      let query = queryOrNil,
      !query.isEmpty
      else {
        return videos
    }
    return videos.filter {
      return $0.title.lowercased().contains(query.lowercased())
    }
  }
  
  func configureSearchController() {
    searchController.searchResultsUpdater = self
    searchController.obscuresBackgroundDuringPresentation = false
    searchController.searchBar.placeholder = "Search Videos"
    navigationItem.searchController = searchController
    definesPresentationContext = true
  }
}

// MARK: - Layout Handling
extension VideosViewController {
  private func configureLayout() {
    collectionView.collectionViewLayout = UICollectionViewCompositionalLayout(sectionProvider: { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
      let isPhone = layoutEnvironment.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiom.phone
      let size = NSCollectionLayoutSize(
        widthDimension: NSCollectionLayoutDimension.fractionalWidth(1),
        heightDimension: NSCollectionLayoutDimension.absolute(isPhone ? 280 : 250)
      )
      let itemCount = isPhone ? 1 : 3
      let item = NSCollectionLayoutItem(layoutSize: size)
      let group = NSCollectionLayoutGroup.horizontal(layoutSize: size, subitem: item, count: itemCount)
      let section = NSCollectionLayoutSection(group: group)
      section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
      section.interGroupSpacing = 10
      return section
    })
  }
  
  override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    coordinator.animate(alongsideTransition: { context in
      self.collectionView.collectionViewLayout.invalidateLayout()
    }, completion: nil)
  }
}

// MARK: - SFSafariViewControllerDelegate Implementation
extension VideosViewController: SFSafariViewControllerDelegate {
  func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
    controller.dismiss(animated: true, completion: nil)
  }
}
