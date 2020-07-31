//
//  DIContainer.swift
//  ExampleMVVM
//
//  Created by Oleh Kudinov on 01.10.18.
//

import Foundation

// DI를 할 오브젝트를 생성하고, 오브젝트들간의 관계를 wiring하는 책임을 가지는 클래스
// 이 클래스도 AppFlowCoordinator처럼 앱 전체적인 DI를 주입하거나 관리할 컨테이너 같음
// 각 모듈별 DIContainer에 API Service와 로컬 DB쪽 Service의 의존성을 주입하는 역할인듯 함
final class AppDIContainer {
    
    lazy var appConfiguration = AppConfiguration()
    
    // MARK: - Network
    // 의존성 주입을 위해 protocol로 정의
    lazy var apiDataTransferService: DataTransferService = {
        // Api Service에 쓰일 configuration
        let config = ApiDataNetworkConfig(baseURL: URL(string: appConfiguration.apiBaseURL)!,
                                          queryParameters: ["api_key": appConfiguration.apiKey,
                                                            "language": NSLocale.preferredLanguages.first ?? "en"])
        
        let apiDataNetwork = DefaultNetworkService(config: config)
        return DefaultDataTransferService(with: apiDataNetwork)
    }()
    
    // 의존성 주입을 위해 protocol로 정의
    lazy var imageDataTransferService: DataTransferService = {
        let config = ApiDataNetworkConfig(baseURL: URL(string: appConfiguration.imagesBaseURL)!)
        let imagesDataNetwork = DefaultNetworkService(config: config)
        return DefaultDataTransferService(with: imagesDataNetwork)
    }()
    
    // MARK: - DIContainers of scenes
    func makeMoviesSceneDIContainer() -> MoviesSceneDIContainer {
        let dependencies = MoviesSceneDIContainer.Dependencies(apiDataTransferService: apiDataTransferService,
                                                               imageDataTransferService: imageDataTransferService)
        return MoviesSceneDIContainer(dependencies: dependencies)
    }
}
