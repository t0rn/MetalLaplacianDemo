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
    let device: MTLDevice
    
    ///Note that the top mip-level of the source texture still contains data required
    ///for reconstruction of the original Gaussian pyramid data, and it is user's responsibility
    ///to propagate it around, i.e. via the use of MTLBlitCommandEncoder.
    let gaussianPyramid: MPSImageGaussianPyramid
    
    ///For each mip-level of the destination, MPSImageLaplacianPyramidSubtract constructs Laplacian pyramid
    let laplacianPyramidDecomposition: MPSImageLaplacianPyramidSubtract
    
    ///MPSImageLaplacianPyramidAdd is responsible for reconstruction
    ///LaplacianMipLevel[l] from the source
    ///GaussianMipLevel[l + 1]  written to the destination on the previous iteration
    let laplacianPyramidReconstruction: MPSImageLaplacianPyramidAdd
    
    required init(
        device: MTLDevice,
        centerWeight: Float = 0.5625
    ) {
        self.device = device
        
        let kernel: [Float] = [0.015625, 0.0625  , 0.09375, 0.0625 , 0.015625,
                              0.0625  , 0.25    , 0.375   , 0.25    , 0.0625,
                              0.09375 , 0.375   , 0.5625  , 0.375   , 0.09375,
                              0.0625  , 0.25    , 0.375   , 0.25    , 0.0625,
                              0.015625, 0.0625  , 0.09375 , 0.0625  , 0.01]
        
        gaussianPyramid = MPSImageGaussianPyramid(
            device: device,
            kernelWidth: 5,
            kernelHeight: 5,
            weights: kernel
//            centerWeight: centerWeight
        )
        
        laplacianPyramidDecomposition = MPSImageLaplacianPyramidSubtract(
            device: device
        )
        laplacianPyramidDecomposition.edgeMode = .clamp
        
        //:= laplacianBias + pixel * laplacianScale,
        //default values being laplacianBias = 0.0, laplacianScale = 1.0

        laplacianPyramidDecomposition.laplacianBias = 0.0
        laplacianPyramidDecomposition.laplacianScale = 1.0
        
        laplacianPyramidReconstruction = MPSImageLaplacianPyramidAdd(
            device: device
        )
        laplacianPyramidReconstruction.edgeMode = .clamp
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
    
    func encode(
        commandBuffer: MTLCommandBuffer,
        //sourceTexture has bgra8Unorm pixel format
        sourceTexture: MTLTexture,
        destinationTexture: MTLTexture
    ) {
        guard var gaussianTexture = convertTexture(device: device,
                                                   commandBuffer: commandBuffer,
                                                   inputTexture: sourceTexture) else {
            return
        }
        //1. Create Gaussian Pyramid from source texture input for Laplassian
        //Image to Pyramid, Laplacian requires a Guassian Pyramid as input
        gaussianPyramid.encode(
            commandBuffer: commandBuffer,
            inPlaceTexture: &gaussianTexture,
            fallbackCopyAllocator: nil
        )
        
        let sourceTextureDescription = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba16Float,
            width: Int(sourceTexture.width),
            height: Int(sourceTexture.height),
            mipmapped: true
        )
        
        sourceTextureDescription.usage =  [MTLTextureUsage.shaderWrite,
                                           MTLTextureUsage.shaderRead,
                                           MTLTextureUsage.pixelFormatView]
        //Intermediate Texture for Laplacian Pyramid
        let lapImagePyramid = device.makeTexture(descriptor: sourceTextureDescription)!
        //2. Substract / Decompose / Construct Laplacian Pyramid from Gaussian Pyramid as source
        laplacianPyramidDecomposition
            .encode(
                commandBuffer: commandBuffer,
                sourceTexture: gaussianTexture,
                destinationTexture: lapImagePyramid
            )
        let lvl = sourceTexture.mipmapLevelCount - 1
        let srcSize = sourceSize(sourceLevel: lvl, sourceTexture: sourceTexture)
        let copyTextureEncoder = commandBuffer.makeBlitCommandEncoder()!
        copyTextureEncoder.copy(from: gaussianTexture, sourceSlice: 0, sourceLevel: gaussianTexture.mipmapLevelCount - 1,
                                sourceOrigin: .zero,
                                sourceSize: srcSize,
                                to: lapImagePyramid,
                                destinationSlice: 0, destinationLevel: lapImagePyramid.mipmapLevelCount - 1, destinationOrigin: .zero)
        copyTextureEncoder.endEncoding()
        
        sourceTextureDescription.usage =  [MTLTextureUsage.shaderWrite,
                                           MTLTextureUsage.shaderRead,
                                           MTLTextureUsage.pixelFormatView]

        //3. Add/ Reconstruct/ Merge Laplacian and Gaussian pyramides
        laplacianPyramidReconstruction
            .encode(
                commandBuffer: commandBuffer,
                sourceTexture: lapImagePyramid,
                destinationTexture: gaussianTexture
            )
        
//        Grab a particular level for viewing
        let blitEncoder = commandBuffer.makeBlitCommandEncoder()!
        let levels = 5 //how many level do we have really?
        var nextOrigin = MTLOrigin.zero
        for level in 0...levels {
            let sourceSize = sourceSize(sourceLevel: level, sourceTexture: gaussianTexture)
            blitEncoder.copy(from: gaussianTexture, sourceSlice: 0, sourceLevel: level,
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
    
    func convertTexture(device: MTLDevice, 
                        commandBuffer: MTLCommandBuffer,
                        inputTexture: MTLTexture) -> MTLTexture? {
        guard let defaultLibrary = device.makeDefaultLibrary(),
              let kernelFunction = defaultLibrary.makeFunction(name: "convertTexture"),
              let computePipelineState = try? device.makeComputePipelineState(function: kernelFunction),
              let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
            return nil
        }

        let outputTexture = createTexture(device: device, 
                                          width: inputTexture.width,
                                          height: inputTexture.height,
                                          pixelFormat: .rgba16Float,
                                          mipmapLevelCount: inputTexture.mipmapLevelCount)

        computeEncoder.setComputePipelineState(computePipelineState)
        computeEncoder.setTexture(inputTexture, index: 0)
        computeEncoder.setTexture(outputTexture, index: 1)

        let threadGroupSize = MTLSizeMake(16, 16, 1)
        let threadGroups = MTLSize(width: (inputTexture.width + threadGroupSize.width - 1) / threadGroupSize.width,
                                   height: (inputTexture.height + threadGroupSize.height - 1) / threadGroupSize.height,
                                   depth: 1)

        computeEncoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupSize)
        computeEncoder.endEncoding()


        return outputTexture
    }
    
    func createTexture(device: MTLDevice, width: Int, height: Int, pixelFormat: MTLPixelFormat, mipmapLevelCount: Int) -> MTLTexture? {
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.pixelFormat = pixelFormat
        textureDescriptor.width = width
        textureDescriptor.height = height
        textureDescriptor.usage = [.shaderRead, .shaderWrite]
        textureDescriptor.storageMode = .private
        textureDescriptor.mipmapLevelCount = mipmapLevelCount
        return device.makeTexture(descriptor: textureDescriptor)
    }
}
