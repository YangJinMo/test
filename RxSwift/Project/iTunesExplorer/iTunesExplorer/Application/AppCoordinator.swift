//
//  AppCoordinator.swift
//  iTunesExplorer
//
//  Created by YangJinMo on 2021/04/20.
//

import UIKit

class AppCoordinator {
  
  // MARK: - Constants
  
  private let window: UIWindow
  
  // MARK: - Initialization
  
  init(window: UIWindow) {
    self.window = window
  }
  
  // MARK: - Internal Methods
  
  func start() {
    let viewController = AppContainer.instance.searchViewController
    window.rootViewController = viewController
    window.makeKeyAndVisible()
  }
}