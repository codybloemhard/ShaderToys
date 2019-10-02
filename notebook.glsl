//#### 2D SDF
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
//#### NOISE
//https://gist.github.com/patriciogonzalezvivo/670c22f3966e662d2f83
float wn11(float n){return fract(sin(n) * 43758.5453123);}
//https://gist.github.com/patriciogonzalezvivo/670c22f3966e662d2f83
float sn11(float p){
	float fl = floor(p);
  	float fc = fract(p);
	return mix(wn11(fl), wn11(fl + 1.0), fc);
}
//https://gist.github.com/patriciogonzalezvivo/670c22f3966e662d2f83
float wn21(vec2 c){
	return fract(sin(dot(c.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (fragCoord-.5*iResolution.xy)/iResolution.y;
	//uv *= pow(1.5,iTime) * .00000001;
    uv *= 0.07;
    vec3 col = vec3(0.);
	
    col = vec3(wn21(uv));
    
    fragColor = vec4(col,1.0);
}