//
//  ViewController.swift
//  MetalLaplacianDemo
//
//  Created by Alexey Ivanov on 22/3/24.
//

import UIKit
import MetalKit
import MetalPerformanceShaders

class ViewController: UIViewController {
    
    private(set) lazy var metalView: MetalView = {
        let view = MetalView(device: device)
        view.mtkView.delegate = self
        return view
    }()
    
    //TODO: inject instead
    let device = MTLCreateSystemDefaultDevice()!
    lazy var commandQueue: MTLCommandQueue = device.makeCommandQueue()!
    lazy var textureLoader = MTKTextureLoader(device: device)
    
    lazy var imageFilter: CommandBufferEncodable = {
        ImageFilterFactory
//            .laplacian
            .sobel
//            .blur(sigma: 10)
            .makeFilter(device: device)
    }()
    
    var sourceTexture: MTLTexture?
    var sourceImage: MPSImage?
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        /** The content is rendered *after* the view has appeared.
            This allows the MTKView to set up properly and get the current drawable.
            The MTKView's draw() method is called once after the still image has been loaded.
         */
        sourceTexture = loadTexture(textureLoader: textureLoader)
        sourceImage = try! textureLoader.loadImage()
        metalView.mtkView.draw()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(metalView)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: metalView.topAnchor, constant: -80),
            view.leadingAnchor.constraint(equalTo: metalView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: metalView.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: metalView.bottomAnchor)
        ])
    }

    func loadTexture(textureLoader: MTKTextureLoader) -> MTLTexture {
        try! textureLoader.loadTexture()
    }
    
    func apply(
        filter: CommandBufferEncodable,
        in drawable: CAMetalDrawable,
        sourceTexture: MTLTexture,
        commandBuffer: MTLCommandBuffer
    ) {
        /** Obtain the current drawable.
         The final destination texture is always the filtered output image written to the MTKView's drawable.
         */
        let destinationTexture = drawable.texture
        
        // Encode the image filter operation.
        filter.encode(
            commandBuffer: commandBuffer,
            sourceTexture: sourceTexture,
            destinationTexture: destinationTexture
        )
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    func apply(
        filter: CommandBufferEncodable,
        in drawable: CAMetalDrawable,
        sourceImage: MPSImage,
        commandBuffer: MTLCommandBuffer
    ) {
        let destinationTexture = drawable.texture
        
        let imageDescriptor = MPSImageDescriptor(
                    channelFormat: MPSImageFeatureChannelFormat.unorm8,
                    width: sourceImage.width,
                    height: sourceImage.height,
                    featureChannels: 3 //?
        )
        let destinationImage = MPSImage(texture: destinationTexture, featureChannels: 3) //
//        let destinationImage = MPSImage(device: device,
//                                        imageDescriptor: imageDescriptor)
//        let destinationImage = MPSTemporaryImage(commandBuffer: commandBuffer,
//                                                 imageDescriptor: imageDescriptor)
//        
        // Encode the image filter operation.
        filter.encode(
            commandBuffer: commandBuffer,
            sourceImage: sourceImage,
            destinationImage: destinationImage
        )
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

extension ViewController: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        metalView.layoutIfNeeded()
    }
    
    func draw(in view: MTKView) {
        // Use a guard to ensure the method has a valid current drawable, a source texture, and an image filter.
        guard
            let currentDrawable = metalView.mtkView.currentDrawable
//            let sourceTexture = sourceTexture
        else { return }
        let commandBuffer = commandQueue.makeCommandBuffer()!
        if let sourceImage {
            apply(filter: imageFilter,
                  in: currentDrawable,
                  sourceImage: sourceImage,
                  commandBuffer: commandBuffer)
        }
        else if let sourceTexture {
            apply(
                filter: imageFilter,
                in: currentDrawable,
                sourceTexture: sourceTexture,
                commandBuffer: commandBuffer
            )
        }
    }
}
extension Bundle {
    static var testImageURL: URL {
        Self.main.url(forResource: "Food_4", withExtension: "JPG")!
    }
}
extension MTKTextureLoader {
    func loadImage(
        from url: URL = Bundle.testImageURL
    ) throws -> MPSImage {
        let texture = try loadTexture(from: url, usage: [.shaderRead, .pixelFormatView])
        return MPSImage(texture: texture, featureChannels: 3)
    }
    
    func loadTexture(
        from url: URL = Bundle.testImageURL,
        usage: MTLTextureUsage = [.shaderRead, .shaderWrite, .pixelFormatView]
    ) throws -> MTLTexture {
//        let usage: MTLTextureUsage = [.shaderRead,.shaderWrite, .pixelFormatView]
        
        let options = [
            MTKTextureLoader.Option.textureUsage : NSNumber(value: usage.rawValue),
//            MTKTextureLoader.Option.SRGB: false, //with false there will be images by levels
            MTKTextureLoader.Option.allocateMipmaps : true
        ]
        let texture = try newTexture(
            URL: url,
            options: options
        )
        return texture
    }
}
