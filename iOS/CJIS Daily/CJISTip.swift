//
//  CJISTip.swift
//  CJIS Daily
//
//  Created by Ramon Dominguez on 11/30/25.
//
import Foundation

struct CJISTip: Identifiable, Codable {
    let id: Int
    let title: String
    let shortText: String
    let longText: String
    let section: String    // e.g. "5.6.2 – Identification and Authentication"
}
