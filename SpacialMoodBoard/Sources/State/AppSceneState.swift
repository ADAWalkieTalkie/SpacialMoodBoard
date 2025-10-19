//
//  AppSceneState.swift
//  SpacialMoodBoard
//
//  Created by PenguinLand on 10/18/25.
//

import Foundation
import Observation

@MainActor
@Observable
final class AppSceneState {
  static let volumeWindowID = "VolumeWindow"
  var activeProjectID: UUID?
}

