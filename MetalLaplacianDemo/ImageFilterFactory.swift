//
//  ImageFilterFactory.swift
//  MetalLaplacianDemo
//
//  Created by Alexey Ivanov on 20/4/24.
//

import Foundation
import MetalPerformanceShaders

enum ImageFilterFactory {
    case blur(sigma: Float)
    case sobel
    case laplacian
    case gaussianPyramid(level: Int)
    case custom
    
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
        case .gaussianPyramid(let level):
            
            return GaussianPyramid(device: device, level: level)
        case .custom:
            return LaplacianPyramid(device: device)
        }
    }
}
