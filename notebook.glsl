//sdf for hor. line. xmm: min and max value for line x
float sdfLineX(vec2 uv, vec2 xmm){
	return length(uv - vec2(clamp(uv.x, xmm.x, xmm.y), 0.));
}
//sdf for ver. line. ymm: min and max value for line y
float sdfLineY(vec2 uv, vec2 ymm){
	return length(uv - vec2(0., clamp(uv.y, ymm.x, ymm.y)));   
}
//sdf for square
float sdfRect(vec2 uv, vec2 xmm, vec2 ymm){
    return length(uv - vec2(clamp(uv.x, xmm.x, xmm.y),clamp(uv.y, ymm.x, ymm.y)));
}
//sdf for cirlce
float sdfCircle(vec2 uv, float r){
	return length(uv - vec2(0.)) - r;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (fragCoord-.5*iResolution.xy)/iResolution.y;
	uv *= 3.;
    vec3 col = vec3(0.);
	
    col += smoothstep(.1, .0, sdfLineX(uv, vec2(-1.,+1.)));
    col += smoothstep(.1, .0, sdfLineY(uv, vec2(-1.,+1.)));
    col += smoothstep(.1, .0, sdfRect(uv, vec2(-.5,.5), vec2(-.5,.5)));
    col += smoothstep(.1, .0, sdfCircle(uv, .6));
    
    fragColor = vec4(col,1.0);
}
