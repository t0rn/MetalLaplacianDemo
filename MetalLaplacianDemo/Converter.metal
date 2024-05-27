//
//  Converter.metal
//  MetalLaplacianDemo
//
//  Created by Alexey Ivanov on 20/5/24.
//

#include <metal_stdlib>
using namespace metal;
//Converts texture from BGRA 8Unorm to RGBA Float
kernel void convertTexture(texture2d<float, access::read> inputTexture [[texture(0)]],
                           texture2d<half, access::write> outputTexture [[texture(1)]],
                           uint2 gid [[thread_position_in_grid]],
                           uint mipLevel [[thread_index_in_threadgroup]]) {
    if (gid.x >= outputTexture.get_width(mipLevel) || gid.y >= outputTexture.get_height(mipLevel)) {
        return;
    }

    float4 color = inputTexture.read(gid, mipLevel);
    half4 convertedColor = half4(color.r, color.g, color.b, color.a); // BGRA to RGBA
    outputTexture.write(convertedColor, gid, mipLevel);
}

