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
    //TODO: inject instead
    let device = MTLCreateSystemDefaultDevice()!
    lazy var commandQueue: MTLCommandQueue = device.makeCommandQueue()!
    lazy var textureLoader = MTKTextureLoader(device: device)
    
    private(set) lazy var imageView: UIImageView = {
        let view = UIImageView(frame: .zero)
        view.contentMode = .scaleAspectFit
        view.translatesAutoresizingMaskIntoConstraints = false
        let image = UIImage(contentsOfFile: Bundle.testImageURL.path())
        view.image = image
        return view
    }()
    
    private(set) lazy var metalView: MetalView = {
        let view = MetalView(device: device)
        view.mtkView.delegate = self
        return view
    }()
    
    lazy var imageFilter: CommandBufferEncodable = {
        ImageFilterFactory
            .custom
            .makeFilter(device: device)
    }()
    
    lazy var actionButton: UIButton = {
        let button = UIButton(primaryAction: UIAction(title: "draw", handler: { [weak self] action in
            self?.draw()
        }))
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    var sourceTexture: MTLTexture?
    var sourceImage: MPSImage?
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(imageView)
        view.addSubview(actionButton)
        view.addSubview(metalView)
        
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: imageView.topAnchor, constant: -80),
            view.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
            actionButton.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            actionButton.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 4),
            actionButton.bottomAnchor.constraint(equalTo: metalView.topAnchor, constant: 4),
            actionButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            imageView.leadingAnchor.constraint(equalTo: metalView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: metalView.trailingAnchor),
            metalView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -40)
        ])
    }
    
    func draw() {
        /** The content is rendered *after* the view has appeared.
            This allows the MTKView to set up properly and get the current drawable.
            The MTKView's draw() method is called once after the still image has been loaded.
         */
        sourceImage = try! textureLoader.loadImage()
        metalView.mtkView.draw()
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
        let destinationImage = MPSImage(texture: destinationTexture, featureChannels: 4)
        
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
        guard let currentDrawable = metalView.mtkView.currentDrawable else { return }
        
        let commandBuffer = commandQueue.makeCommandBuffer()!
        guard let sourceImage  = sourceImage else { return }
        
        apply(filter: imageFilter,
              in: currentDrawable,
              sourceImage: sourceImage,
              commandBuffer: commandBuffer)
    }
}
