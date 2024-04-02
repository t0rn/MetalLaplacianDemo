//
//  CommandBufferEncodable.swift
//  MetalLaplacianDemo
//
//  Created by Alexey Ivanov on 2/4/24.
//

import Foundation
import MetalPerformanceShaders

protocol CommandBufferEncodable {
    func encode(to commandBuffer: MTLCommandBuffer,
                sourceTexture: MTLTexture,
                destinationTexture: MTLTexture)
}
