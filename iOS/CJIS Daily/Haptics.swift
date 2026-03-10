//
//  Haptics.swift
//  CJIS Daily
//
//  Created by Ramon Dominguez on 12/1/25.
//
import UIKit

enum Haptics {
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}
