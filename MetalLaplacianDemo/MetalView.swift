//
//  MetalView.swift
//  MetalLaplacianDemo
//
//  Created by Alexey Ivanov on 1/4/24.
//

import Foundation
import MetalKit

class MetalView: UIView {
    lazy var mtkView: MTKView = {
        let view = MTKView()
        view.framebufferOnly = false
        view.isPaused = true
//        view.clearColor = MTLClearColor()
//        view.isOpaque = false
        view.colorPixelFormat = .rgba16Float
//        view.colorPixelFormat = .bgra8Unorm //?
//        view.contentMode = .scaleAspectFit //?
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    convenience init(
        frame: CGRect = .zero,
        device: MTLDevice? = MTLCreateSystemDefaultDevice()
    ) {
        self.init(frame: .zero)
        self.mtkView.device = device
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    private func commonInit() {
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(mtkView)
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: mtkView.topAnchor),
            leadingAnchor.constraint(equalTo: mtkView.leadingAnchor),
            trailingAnchor.constraint(equalTo: mtkView.trailingAnchor),
            bottomAnchor.constraint(equalTo: mtkView.bottomAnchor)
        ])
    }
}
