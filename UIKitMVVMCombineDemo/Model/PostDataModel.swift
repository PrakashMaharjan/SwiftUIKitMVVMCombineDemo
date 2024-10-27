//
//  PostDataModel.swift
//  UIKitMVVMCombineDemo
//
//  Created by PM on 25/10/2024.
//

import Foundation

struct Post: Decodable, Identifiable {
    let id: Int
    let title: String
    let body: String
}
