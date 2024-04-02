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
    
    lazy var imageFilter: LaplacianPyramid = {
        return LaplacianPyramid(device: self.device)
    }()
    
    var sourceTexture: MTLTexture?
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        /** The content is rendered *after* the view has appeared.
            This allows the MTKView to set up properly and get the current drawable.
            The MTKView's draw() method is called once after the still image has been loaded.
         */
        sourceTexture = loadTexture(textureLoader: textureLoader)
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
        let url = Bundle.main.url(forResource: "Food_4", withExtension: "JPG")!
        
        let options = [MTKTextureLoader.Option.textureUsage : NSNumber(value:MTLTextureUsage.shaderRead.rawValue |
                                                                       MTLTextureUsage.shaderWrite.rawValue | MTLTextureUsage.pixelFormatView.rawValue),
                       MTKTextureLoader.Option.SRGB: false, MTKTextureLoader.Option.allocateMipmaps : true]
        
        return try! textureLoader.newTexture(URL: url, options: options)
    }
}

extension ViewController: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        metalView.layoutIfNeeded()
    }
    
    func draw(in view: MTKView) {
        // Use a guard to ensure the method has a valid current drawable, a source texture, and an image filter.
        guard
            let currentDrawable = metalView.mtkView.currentDrawable,
            let sourceTexture = sourceTexture
        else { return }
        
        let commandBuffer = commandQueue.makeCommandBuffer()!
        
        /** Obtain the current drawable.
            The final destination texture is always the filtered output image written to the MTKView's drawable.
         */
        let destinationTexture = currentDrawable.texture
        
        // Encode the image filter operation.
        imageFilter.encode(to: commandBuffer,
                           sourceTexture: sourceTexture,
                           destinationTexture: destinationTexture)
        
        commandBuffer.present(currentDrawable)
        commandBuffer.commit()
    }
}
