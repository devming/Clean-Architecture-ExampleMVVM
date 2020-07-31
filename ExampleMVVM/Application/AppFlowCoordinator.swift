//
//  AppFlowCoordinator.swift
//  ExampleMVVM
//
//  Created by Oleh Kudinov on 03.03.19.
//

import UIKit

// 앱의 전체적인 플로우를 관리할 코디네이터
// 모듈별로 개별적인 코디네이터를 만들고 이 클래스는 전체적인 프로우만 책임을 가지는 듯 하다.
// 각 모듈별 코디네이터도 DI컨테이너를 통해 만들어서 의존성을 가지지 않게 하려는 듯 함
class AppFlowCoordinator {

    // 객체 생성은 Appdelegate에서 함
    var navigationController: UINavigationController
    private let appDIContainer: AppDIContainer
    
    init(navigationController: UINavigationController,
         appDIContainer: AppDIContainer) {
        self.navigationController = navigationController
        self.appDIContainer = appDIContainer
    }

    func start() {
        // In App Flow we can check if user needs to login, if yes we would run login flow
        let moviesSceneDIContainer = appDIContainer.makeMoviesSceneDIContainer()
        //flow는 MovieSearch관련한 VC들의 화면전환을 관리하는 FlowCoordinator
        let flow = moviesSceneDIContainer.makeMoviesSearchFlowCoordinator(navigationController: navigationController)
        // MoviewSearch관련 Coordinator에서 start로 앱의 첫 화면을 전환
        flow.start()
    }
}
