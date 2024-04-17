//
//  LaplacianPyramid.swift
//  MetalLaplacianDemo
//
//  Created by Alexey Ivanov on 2/4/24.
//

import Foundation
import MetalPerformanceShaders

//see https://stackoverflow.com/questions/54004576/appropriate-usage-of-mpsimagegaussianpyramid-with-metal
class LaplacianPyramid: CommandBufferEncodable {
    let gaussianPyramid: MPSImageGaussianPyramid
    let laplacianPyramid: MPSImageLaplacianPyramid
    
    required init(device: MTLDevice) {
        gaussianPyramid = MPSImageGaussianPyramid(device: device, centerWeight: 0.375)
        gaussianPyramid.edgeMode = .clamp
        laplacianPyramid = MPSImageLaplacianPyramid(device: device)
        laplacianPyramid.edgeMode = .clamp
    }
    
    func encode(
        commandBuffer: MTLCommandBuffer,
        sourceTexture: MTLTexture,
        destinationTexture: MTLTexture
    ) {
        var inputTexture = sourceTexture
        
        let sourceTextureDescription = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm, //rgba8Unorm wrong
            width: Int(inputTexture.width),
            height: Int(inputTexture.height),
            mipmapped: true
        )
        sourceTextureDescription.usage = MTLTextureUsage(rawValue: ( MTLTextureUsage.shaderWrite.rawValue |
                                                                     MTLTextureUsage.shaderRead.rawValue |
                                                                     MTLTextureUsage.pixelFormatView.rawValue))
        
        //Intermediate Texture for Pyramid
        let intermediateTexture = gaussianPyramid.device.makeTexture(descriptor: sourceTextureDescription)!
//        let intermediateTexture = sourceTexture.makeTextureView(
//            pixelFormat: sourceTexture.pixelFormat,
//            textureType: sourceTexture.textureType,
//            levels: 0..<5,
//            slices: 0..<1
//        )!
        
        //Image to Pyramid, Laplacian requires a Guassian Pyramid as input
//        let MBECopyAllocator = { (kernel: MPSKernel, commandBuffer: MTLCommandBuffer, sourceTexture: MTLTexture) -> MTLTexture in
//            sourceTexture.device.makeTexture(descriptor: sourceTexture.matchingDescriptor())!
//        }
        gaussianPyramid.encode(
            commandBuffer: commandBuffer,
            inPlaceTexture: &inputTexture,
            fallbackCopyAllocator: nil
        )
        laplacianPyramid.encode(
            commandBuffer: commandBuffer,
            sourceTexture: inputTexture,
            destinationTexture: intermediateTexture
        )
        
//        Grab a particular level for viewing
        let blitEncoder = commandBuffer.makeBlitCommandEncoder()!
        let sourceLevel = 0 //see MTKTextureLoader.Option.SRGB: false in texture loader
        let scaleFactor = NSDecimalNumber(decimal: pow(2, sourceLevel) ).intValue
        let sourceSize = MTLSize(
            width: Int(sourceTexture.width / scaleFactor),
            height: Int(sourceTexture.height / scaleFactor),
            depth: 1
        )
        
        blitEncoder.copy(from: intermediateTexture, sourceSlice: 0, sourceLevel: sourceLevel,
                         sourceOrigin: .zero,
                         sourceSize: sourceSize,
                         to: destinationTexture,
                         destinationSlice: 0, destinationLevel: 0, destinationOrigin: .zero)
        
        blitEncoder.endEncoding()
    }

    func encode(
        commandBuffer: MTLCommandBuffer,
        sourceImage: MPSImage,
        destinationImage: MPSImage
    ) {
        /*
        let inputTexture = try! textureLoader.loadTexture()
        let sourceTextureDescription = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm,
            width: Int(inputTexture.width),
            height: Int(inputTexture.height),
            mipmapped: true
        )
        sourceTextureDescription.usage = MTLTextureUsage(rawValue: ( MTLTextureUsage.shaderWrite.rawValue |
                                                                     MTLTextureUsage.shaderRead.rawValue |
                                                                     MTLTextureUsage.pixelFormatView.rawValue))
        
        let tmpImage = MPSTemporaryImage(commandBuffer: commandBuffer,
                                         textureDescriptor: sourceTextureDescription)
        
        */

        let imageDescriptor = MPSImageDescriptor(
            channelFormat: MPSImageFeatureChannelFormat.unorm8,
            width: sourceImage.width,
            height: sourceImage.height,
            featureChannels: 3 //?
        )
////        let destinationImage = MPSImage(device: device,
////                                        imageDescriptor: descriptor)
//        let tmpImage = MPSTemporaryImage(commandBuffer: commandBuffer,
//                                         imageDescriptor: imageDescriptor)
        self.encode(
            commandBuffer: commandBuffer,
            sourceTexture: sourceImage.texture,
            destinationTexture: destinationImage.texture
        )
    }
}


