//
//  MTKTextureLoader+Image.swift
//  MetalLaplacianDemo
//
//  Created by Alexey Ivanov on 20/4/24.
//

import Foundation
import MetalKit
import MetalPerformanceShaders

extension MTKTextureLoader {
    func loadImage(
        from url: URL = Bundle.testImageURL
    ) throws -> MPSImage {
        let texture = try loadTexture(from: url)
        return MPSImage(texture: texture, featureChannels: 4)
    }
    
    func loadTexture(
        from url: URL = Bundle.testImageURL,
        usage: MTLTextureUsage = [.shaderRead, .shaderWrite, .pixelFormatView]
    ) throws -> MTLTexture {        
        let options = [
            MTKTextureLoader.Option.textureUsage : NSNumber(value: usage.rawValue),
            MTKTextureLoader.Option.SRGB: false, //with false there will be images by levels
            MTKTextureLoader.Option.allocateMipmaps : true
        ]
        let texture = try newTexture(
            URL: url,
            options: options
        )
        return texture
    }
}
