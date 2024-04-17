//
//  TestViewController.swift
//  MetalLaplacianDemo
//
//  Created by Alexey Ivanov on 17/4/24.
//

import UIKit
import MetalKit
import MetalPerformanceShaders

class TestViewController: UIViewController {
    
    let device = MTLCreateSystemDefaultDevice()!
    lazy var commandQueue: MTLCommandQueue = device.makeCommandQueue()!
    lazy var textureLoader = MTKTextureLoader(device: device)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func testGaussianPyramid() {
        let p = MPSImageGaussianPyramid(device: device, centerWeight: 1)
        let commandBuffer = commandQueue.makeCommandBuffer()!
        
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
        let sourceImage = try! textureLoader.loadImage()
        let imageDescriptor = MPSImageDescriptor(
            channelFormat: MPSImageFeatureChannelFormat.unorm8,
            width: sourceImage.width,
            height: sourceImage.height,
            featureChannels: 3 //?
        )
//        let destinationImage = MPSImage(device: device,
//                                        imageDescriptor: descriptor)
        let tmpImage = MPSTemporaryImage(commandBuffer: commandBuffer,
                          imageDescriptor: imageDescriptor)
        p.encode(
            commandBuffer: commandBuffer,
            sourceImage: sourceImage,
            destinationImage: tmpImage
        )
        
    }
}

