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
// MARK: - Vertex & Fragment shaders for Waterfall draw calls
// --------------------------------------------------------------------------------

struct Intensity {
  ushort  i;                          // intensities
};

struct Constants {                    // constant values
  float   deltaX;
  ushort  offsetY;
  ushort  numberOfLines;
  float   colorGain;                  // color gain, 0.0 -> 1.0
  ushort  blackLevel;                 // black level
};

struct VertexOutput {
  float4  coord [[ position ]];       // vertex coordinates
  float   intensity;                  // vertex intensity
};

// Waterfall vertex shader
//
//  - Parameters:
//    - vertices:       an array of Vertex structs
//    - vertexId:       a system generated vertex index
//
//  - Returns:          a VertexOutput struct
//
vertex VertexOutput waterfall_vertex(const device Intensity* intensities [[ buffer(0) ]],
                                     const device Intensity* line [[ buffer(1) ]],
                                     unsigned int vertexId [[ vertex_id ]],
                                     constant Constants &constants [[ buffer(2) ]])

{
  VertexOutput v_out;
  float xCoord;
  float yCoord;
  ushort temp1;
  
  // calculate the x coordinate & normalize to clip space
  xCoord = ((float(vertexId) * constants.deltaX) * 2) - 1 ;
  
  // calculate the y coordinate & normalize to clip space
  // with line "0" == top. line "# lines" == bottom
  temp1 = ((line->i) + constants.offsetY) % (constants.numberOfLines);
  yCoord = -((( float(temp1) / (float(constants.numberOfLines) ))  * 2.0) - 1.0);
  
  // pass the vertex & texture coordinates to the Fragment shader
  v_out.coord = float4(xCoord, yCoord, 0.0, 1.0);
  v_out.intensity = float(intensities[vertexId].i) / 65535.0;
  
  return v_out;
}

// Waterfall fragment shader
///
//  - Parameters:
//    - in:             VertexOutput struct
//  - Returns:          the fragment color
//
fragment float4 waterfall_fragment( VertexOutput in [[ stage_in ]],
                                   texture1d<float, access::sample> gradientTexture [[texture(0)]],
                                   sampler gradientTextureSampler [[sampler(0)]])
{
  // paint the fragment with the gradient color
//  return float4( gradientTexture.sample(gradientTextureSampler, in.intensity));
//  return float4( gradientTexture.sample(gradientTextureSampler, 1.0));
  return float4( 1.0, 1.0, 0.0, 1.0);
}
