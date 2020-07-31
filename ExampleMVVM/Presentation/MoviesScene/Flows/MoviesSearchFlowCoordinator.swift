//
//  MoviesSearchFlowCoordinator.swift
//  ExampleMVVM
//
//  Created by Oleh Kudinov on 03.03.19.
//

import UIKit
import RxSwift

protocol MoviesSearchFlowCoordinatorDependencies  {
    func makeMoviesListViewController(closures: MoviesListViewModelClosures) -> MoviesListViewController
    func makeMoviesDetailsViewController(movie: Movie) -> UIViewController
    func makeMoviesQueriesSuggestionsListViewController(didSelect: @escaping MoviesQueryListViewModelDidSelectClosure) -> UIViewController
}

class MoviesSearchFlowCoordinator {
    
    private let navigationController: UINavigationController
    private let dependencies: MoviesSearchFlowCoordinatorDependencies

    private weak var moviesListVC: MoviesListViewController?
    private weak var moviesQueriesSuggestionsVC: UIViewController?

    // 의존성 주입
    // ViewController들에 대한 의존성을 가지지 않기 위해 DI컨테이너에서 의존성을 주입합
    // 이로 인해 ViewController들로 부터 의존성이 독립됨
    // Coordinator가 의존성이 없는 클래스가 됨
    init(navigationController: UINavigationController,
         dependencies: MoviesSearchFlowCoordinatorDependencies) {
        self.navigationController = navigationController
        self.dependencies = dependencies
    }
    
    // 앱의 첫 화면 전환
    func start() {
        // Note: here we keep strong reference with closures, this way this flow do not need to be strong referenced
        let closures = MoviesListViewModelClosures(showMovieDetails: showMovieDetails,
                                                   showMovieQueriesSuggestions: showMovieQueriesSuggestions,
                                                   closeMovieQueriesSuggestions: closeMovieQueriesSuggestions)
        let vc = dependencies.makeMoviesListViewController(closures: closures)

        navigationController.pushViewController(vc, animated: false)
        moviesListVC = vc
    }

    private func showMovieDetails(movie: Movie) {
        let vc = dependencies.makeMoviesDetailsViewController(movie: movie)
        navigationController.pushViewController(vc, animated: true)
    }

    private func showMovieQueriesSuggestions(didSelect: @escaping (MovieQuery) -> Void) {
        guard let moviesListViewController = moviesListVC, moviesQueriesSuggestionsVC == nil,
            let container = moviesListViewController.suggestionsListContainer else { return }

        let vc = dependencies.makeMoviesQueriesSuggestionsListViewController(didSelect: didSelect)

        moviesListViewController.add(child: vc, container: container)
        moviesQueriesSuggestionsVC = vc
        container.isHidden = false
    }

    private func closeMovieQueriesSuggestions() {
        moviesQueriesSuggestionsVC?.remove()
        moviesQueriesSuggestionsVC = nil
        moviesListVC?.suggestionsListContainer.isHidden = true
    }
}
