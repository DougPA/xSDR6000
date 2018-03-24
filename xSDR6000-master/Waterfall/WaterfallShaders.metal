//
//  WaterfallShaders.metal
//  xSDR6000
//
//  Created by Douglas Adams on 10/9/17.
//  Copyright © 2017 Douglas Adams. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

// --------------------------------------------------------------------------------
// MARK: - Kernel shader for Gradient calculations
// --------------------------------------------------------------------------------

struct Constants {                          // constant values
  ushort        blackLevel;
  float         colorGain;
  unsigned int  lineNumber;
};

//  Kernel function for conversion of intensity to color (gradient)
//
//  - Parameters:
//    - inTexture:          2D, intensity values (UInt16)
//    - outTexture:         2D, derived color value for intensity (bgra8Unorm)
//    - gradientTexture:    1D, color gradient (bgra8Unorm)
//    - gradientSampler:    1D, sampler for gradientTexture
//    - gid:                system generated position in grid
//
//  Result is written into outTexture
//
kernel void convert(texture1d<ushort, access::read> inTexture [[texture(0)]],
                    texture2d<float, access::write> outTexture [[texture(1)]],
                    texture1d<float, access::sample> gradientTexture [[texture(2)]],
                    sampler gradientSampler [[sampler(0)]],
                    uint2 gid [[thread_position_in_grid]],
                    constant Constants &constants [[ buffer(0) ]])
{
  float4  colorAtPixel;
  float   normalizedIntensity;
  float   power;
  
  // is the intensity below the black level?
  if (inTexture.read(gid.x).r < constants.blackLevel) {
    // YES, ignore it
    normalizedIntensity = 0;
    
  } else {
    
    // NO, make it non-linear
    power = pow( (1.0 + constants.colorGain), 4.0 );
    
    // normalize it (0 -> UInt16.max becomes 0.0 -> 1.0)
    normalizedIntensity = float( (inTexture.read(gid.x).r - constants.blackLevel) / float(65536) )  * power;
  }
  
  // lookup the color in the gradient
  colorAtPixel = gradientTexture.sample(gradientSampler, normalizedIntensity).rgba;
  
  // write the color into the output texture
  outTexture.write(colorAtPixel, uint2( gid.x, constants.lineNumber));
}

// --------------------------------------------------------------------------------
// MARK: - Vertex & Fragment shaders for Waterfall draw calls
// --------------------------------------------------------------------------------

struct Vertex {
  float2  coord;                            // waterfall coordinates
  float2  texCoord;                         // texture coordinates
};

struct VertexOutput {
  float4  coord [[ position ]];             // vertex coordinates
  float2  texCoord;                         // texture coordinates
};

// Waterfall vertex shader
//
//  - Parameters:
//    - vertices:       an array of Vertex structs
//    - vertexId:       a system generated vertex index
//
//  - Returns:          a VertexOutput struct
//
vertex VertexOutput waterfall_vertex(const device Vertex* vertices [[ buffer(0) ]],
                                     unsigned int vertexId [[ vertex_id ]])
{
  VertexOutput v_out;
  
  // pass the vertex & texture coordinates to the Fragment shader
  v_out.coord = float4(vertices[vertexId].coord.xy, 0.0, 1.0);
  v_out.texCoord = vertices[vertexId].texCoord.xy;
  
  return v_out;
}

// Waterfall fragment shader
///
//  - Parameters:
//    - in:             VertexOutput struct
//  - Returns:          the fragment color
//
fragment float4 waterfall_fragment( VertexOutput in [[ stage_in ]],
                                   texture2d<float, access::sample> drawtexture [[texture(0)]],
                                   sampler drawTextureSampler [[sampler(0)]])
{
  // paint the fragment with the texture color
  return float4( drawtexture.sample(drawTextureSampler, in.texCoord).rgba);
}


