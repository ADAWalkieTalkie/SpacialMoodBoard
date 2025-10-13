//
//  CreationStep.swift
//  SpacialMoodBoard
//
//  Created by PenguinLand on 10/13/25.
//

enum CreationStep: Hashable {
  case roomTypeSelection
  case groundSizeSelection(roomType: RoomType)
  case projectTitleInput(roomType: RoomType, groundSize: GroundSizePreset)
}
