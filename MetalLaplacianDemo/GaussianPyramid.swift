//
//  File.swift
//  MetalLaplacianDemo
//
//  Created by Alexey Ivanov on 20/4/24.
//

import Foundation
import MetalPerformanceShaders

final class GaussianPyramid: CommandBufferEncodable {
    let device: MTLDevice
    let gaussianPyramid: MPSImageGaussianPyramid
    var level: Int
    
    required init(device: MTLDevice, level: Int = 0) {
        self.device = device
        self.level = level
        //white textures as result
        let weights: [Float] =
//        [
//            1,   4,   6,   4,   1,
//            4,  16,  24,  16,   4,
//            6,  24,  36,  24,   6,
//            4,  16,  24,  16,  4,
//            1,   4,   6,   4,   1
//        ]
        [
            0.015625, 0.0625  , 0.09375 , 0.0625  , 0.015625,
            0.0625  , 0.25    , 0.375   , 0.25    , 0.0625,
            0.09375 , 0.375   , 0.5625  , 0.375   , 0.09375,
            0.0625  , 0.25    , 0.375   , 0.25    , 0.0625,
            0.015625, 0.0625  , 0.09375 , 0.0625  , 0.015625
        ]
        /*
         The Gaussian image pyramid is constructed as follows: First the zeroth level mipmap of the input image is filtered with the specified convolution kernel. The default the convolution filter kernel is

         k = w w^T, where w = [ 1/16,  1/4,  3/8,  1/4,  1/16 ]^T,

         but the user may also tweak this kernel with a centerWeight parameter: 'a':

         k = w w^T, where w = [ (1/4 - a/2),  1/4,  a,  1/4,  (1/4 - a/2) ]^T
         */
        gaussianPyramid = MPSImageGaussianPyramid(
            device: device,
            //centerWeight > 1 makes it noisy
            centerWeight: 0.7
//            kernelWidth: 5,
//            kernelHeight: 5,
//            weights: weights
        )
        gaussianPyramid.options = [MPSKernelOptions.verbose]
        gaussianPyramid.edgeMode = .clamp
    }
    
    //MARK: CommandBufferEncodable
    func encode(
        commandBuffer: MTLCommandBuffer,
        sourceTexture: MTLTexture,
        destinationTexture: MTLTexture
    ) {
        var inputTexture = sourceTexture

        gaussianPyramid.encode(
            commandBuffer: commandBuffer,
            inPlaceTexture: &inputTexture,
            fallbackCopyAllocator: nil
        )
        let blitEncoder = commandBuffer.makeBlitCommandEncoder()!
        let levels = 4
        var nextOrigin = MTLOrigin.zero
        for level in 0...levels {
            let sourceSize = sourceSize(sourceLevel: level, sourceTexture: inputTexture)
            blitEncoder.copy(from: inputTexture, sourceSlice: 0, sourceLevel: level,
                             sourceOrigin: .zero,
                             sourceSize: sourceSize,
                             to: destinationTexture,
                             destinationSlice: 0, destinationLevel: 0, destinationOrigin: nextOrigin)
            
            if level == 0 {
                nextOrigin.y = sourceSize.height
            } else {
                nextOrigin.x += sourceSize.width
            }
        }

        blitEncoder.endEncoding()
    }
    
    func sourceSize(sourceLevel: Int, sourceTexture: MTLTexture) -> MTLSize {
        let scaleFactor = NSDecimalNumber(decimal: pow(2, sourceLevel)).intValue
        let sourceSize = MTLSize(width: max(sourceTexture.width / scaleFactor, 1),
                                 height: max(sourceTexture.height / scaleFactor, 1),
                                 depth: 1)
        return sourceSize
    }
    
    func encode(
        commandBuffer: MTLCommandBuffer,
        sourceImage: MPSImage,
        destinationImage: MPSImage
    ) {
        encode(
            commandBuffer: commandBuffer,
            sourceTexture: sourceImage.texture,
            destinationTexture: destinationImage.texture
        )
    }
}
