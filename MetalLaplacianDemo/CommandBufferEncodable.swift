//
//  CommandBufferEncodable.swift
//  MetalLaplacianDemo
//
//  Created by Alexey Ivanov on 2/4/24.
//

import Foundation
import MetalPerformanceShaders

protocol CommandBufferEncodable {
    func encode(
        commandBuffer: MTLCommandBuffer,
        sourceTexture: MTLTexture,
        destinationTexture: MTLTexture
    )
    
    func encode(
        commandBuffer: MTLCommandBuffer,
        sourceImage: MPSImage,
        destinationImage: MPSImage
    )
}
extension MPSImageLaplacian: CommandBufferEncodable {}
extension MPSImageGaussianBlur: CommandBufferEncodable {}
extension MPSImageSobel: CommandBufferEncodable {}

