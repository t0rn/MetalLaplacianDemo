//
//  LaplacianFilter.swift
//  MetalLaplacianDemo
//
//  Created by Alexey Ivanov on 2/4/24.
//

import Foundation
import MetalPerformanceShaders

class LaplacianFilter: CommandBufferEncodable {
    let laplacian: MPSImageLaplacian
    
    required init(device: MTLDevice) {
        laplacian = MPSImageLaplacian(device: device)
        laplacian.edgeMode = .zero
    }
    
    func encode(to commandBuffer: MTLCommandBuffer, sourceTexture: MTLTexture, destinationTexture: MTLTexture) {
        laplacian.encode(commandBuffer: commandBuffer,
                         sourceTexture: sourceTexture,
                         destinationTexture: destinationTexture)
    }
}

