//
//  MoviesListViewModel.swift
//  ExampleMVVM
//
//  Created by Oleh Kudinov on 01.10.18.
//

import Foundation

// 후에 또 다른 클로저들을 추가할 때 편리하게 추가하기 위해 struct로 그룹화함
// Coordinator에서 또 다른 뷰로 가기 위해서 이 클로저를 통해서 요청한다.
// 클로저가 call되면 coordinator가 다른 뷰를 present할 것이다.
struct MoviesListViewModelClosures {
    // Note: if you would need to edit movie inside Details screen and update this Movies List screen with updated movie then you would need this closure:
    //  showMovieDetails: (Movie, @escaping (_ updated: Movie) -> Void) -> Void
    let showMovieDetails: (Movie) -> Void
    let showMovieQueriesSuggestions: (@escaping (_ didSelect: MovieQuery) -> Void) -> Void
    let closeMovieQueriesSuggestions: () -> Void
}

enum MoviesListViewModelLoading {
    case fullScreen
    case nextPage
}

// Input Output는 ViewController를 테스트에 용이하게 해준다.
// mock뷰모델을 쉽게 만들게 해주므로 그런 것 같다?

protocol MoviesListViewModelInput {
    func viewDidLoad()
    func didLoadNextPage()
    func didSearch(query: String)
    func didCancelSearch()
    func showQueriesSuggestions()
    func closeQueriesSuggestions()
    func didSelectItem(at index: Int)
}

protocol MoviesListViewModelOutput {
    var items: Observable<[MoviesListItemViewModel]> { get }
    var loadingType: Observable<MoviesListViewModelLoading?> { get }
    var query: Observable<String> { get }
    var error: Observable<String> { get }
    var isEmpty: Bool { get }
    var screenTitle: String { get }
    var emptyDataTitle: String { get }
    var errorTitle: String { get }
    var searchBarPlaceholder: String { get }
}

protocol MoviesListViewModel: MoviesListViewModelInput, MoviesListViewModelOutput {}

final class DefaultMoviesListViewModel: MoviesListViewModel {

    private let searchMoviesUseCase: SearchMoviesUseCase
    private let closures: MoviesListViewModelClosures?

    var currentPage: Int = 0
    var totalPageCount: Int = 1
    var hasMorePages: Bool { currentPage < totalPageCount }
    var nextPage: Int { hasMorePages ? currentPage + 1 : currentPage }

    private var pages: [MoviesPage] = []
    private var moviesLoadTask: Cancellable? { willSet { moviesLoadTask?.cancel() } }

    // MARK: - OUTPUT

    let items: Observable<[MoviesListItemViewModel]> = Observable([])
    let loadingType: Observable<MoviesListViewModelLoading?> = Observable(.none)
    let query: Observable<String> = Observable("")
    let error: Observable<String> = Observable("")
    var isEmpty: Bool { return items.value.isEmpty }
    let screenTitle = NSLocalizedString("Movies", comment: "")
    let emptyDataTitle = NSLocalizedString("Search results", comment: "")
    let errorTitle = NSLocalizedString("Error", comment: "")
    let searchBarPlaceholder = NSLocalizedString("Search Movies", comment: "")

    // MARK: - Init

    init(searchMoviesUseCase: SearchMoviesUseCase,
         closures: MoviesListViewModelClosures? = nil) {
        self.searchMoviesUseCase = searchMoviesUseCase
        self.closures = closures
    }

    // MARK: - Private

    private func appendPage(_ moviesPage: MoviesPage) {
        currentPage = moviesPage.page
        totalPageCount = moviesPage.totalPages

        pages = pages
            .filter { $0.page != moviesPage.page }
            + [moviesPage]

        items.value = pages.movies.map(MoviesListItemViewModel.init)
    }

    private func resetPages() {
        currentPage = 0
        totalPageCount = 1
        pages.removeAll()
        items.value.removeAll()
    }

    private func load(movieQuery: MovieQuery, loadingType: MoviesListViewModelLoading) {
        self.loadingType.value = loadingType
        query.value = movieQuery.query

        moviesLoadTask = searchMoviesUseCase.execute(
            requestValue: .init(query: movieQuery, page: nextPage),
            cached: appendPage,
            completion: { result in
                switch result {
                case .success(let page):
                    self.appendPage(page)
                case .failure(let error):
                    self.handle(error: error)
                }
                self.loadingType.value = .none
        })
    }

    private func handle(error: Error) {
        self.error.value = error.isInternetConnectionError ?
            NSLocalizedString("No internet connection", comment: "") :
            NSLocalizedString("Failed loading movies", comment: "")
    }

    private func update(movieQuery: MovieQuery) {
        resetPages()
        load(movieQuery: movieQuery, loadingType: .fullScreen)
    }
}

// MARK: - INPUT. View event methods

extension DefaultMoviesListViewModel {

    func viewDidLoad() { }

    func didLoadNextPage() {
        guard hasMorePages, loadingType.value == .none else { return }
        load(movieQuery: MovieQuery(query: query.value),
             loadingType: .nextPage)
    }

    func didSearch(query: String) {
        guard !query.isEmpty else { return }
        update(movieQuery: MovieQuery(query: query))
    }

    func didCancelSearch() {
        moviesLoadTask?.cancel()
    }

    func showQueriesSuggestions() {
        closures?.showMovieQueriesSuggestions(update(movieQuery:))
    }

    func closeQueriesSuggestions() {
        closures?.closeMovieQueriesSuggestions()
    }

    func didSelectItem(at index: Int) {
        closures?.showMovieDetails(pages.movies[index])
    }
}

// MARK: - Private

private extension Array where Element == MoviesPage {
    var movies: [Movie] { flatMap { $0.movies } }
}
