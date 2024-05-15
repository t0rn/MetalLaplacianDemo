//
//  Bundle+Image.swift
//  MetalLaplacianDemo
//
//  Created by Alexey Ivanov on 20/4/24.
//

import Foundation

extension Bundle {
    static var testImageURL: URL {
        Self.main.url(forResource: "Food_4", withExtension: "JPG")!
    }
}
