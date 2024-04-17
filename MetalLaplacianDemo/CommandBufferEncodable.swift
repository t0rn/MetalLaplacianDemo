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

import MetalPerformanceShaders
//extension MPSImageGaussianPyramid: CommandBufferEncodable {}
enum ImageFilterFactory {
    case blur(sigma: Float)
    case sobel
    case laplacian
    
    func makeFilter(device:  MTLDevice) -> CommandBufferEncodable {
        switch self {
        case .blur(let sigma):
            
            return MPSImageGaussianBlur(device: device, sigma: sigma)
        case .laplacian:
            let filter = MPSImageLaplacian(device: device)
            filter.edgeMode = .clamp
            
            return filter
        case .sobel:
            return MPSImageSobel(device: device)
        }
    }
}
