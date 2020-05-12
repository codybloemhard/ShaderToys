// https://iquilezles.org/www/articles/smin/smin.htm
float op_union(float d1, float d2, float k){
    float h = max(k-abs(d1-d2),0.0);
    return min(d1, d2) - h*h*0.25/k;
}

float op_sub(float d1, float d2, float k){
    float h = max(k-abs(-d1-d2),0.0);
    return max(-d1, d2) + h*h*0.25/k;
}

float op_inter(float d1, float d2, float k){
    float h = max(k-abs(d1-d2),0.0);
    return max(d1, d2) + h*h*0.25/k;
}
// https://iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
float sdf_circle(vec2 uv, vec2 pos, float rad){
	return length(uv - pos) - rad;
}

float sdf_rect(vec2 uv, vec2 pos, vec2 hsize){
    vec2 cwe = abs(uv - pos) - hsize;
    float outd = length(max(cwe, 0.0));
    float ind = min(max(cwe.x, cwe.y), 0.0);
    return outd + ind;
}

float sdf_triangle(vec2 uv, vec2 p0, vec2 p1, vec2 p2){
	vec2 e0 = p1 - p0;
	vec2 e1 = p2 - p1;
	vec2 e2 = p0 - p2;

	vec2 v0 = uv - p0;
	vec2 v1 = uv - p1;
	vec2 v2 = uv - p2;

	vec2 pq0 = v0 - e0*clamp( dot(v0,e0)/dot(e0,e0), 0.0, 1.0 );
	vec2 pq1 = v1 - e1*clamp( dot(v1,e1)/dot(e1,e1), 0.0, 1.0 );
	vec2 pq2 = v2 - e2*clamp( dot(v2,e2)/dot(e2,e2), 0.0, 1.0 );

    float s = sign( e0.x*e2.y - e0.y*e2.x );
    vec2 d = min( min( vec2( dot( pq0, pq0 ), s*(v0.x*e0.y-v0.y*e0.x) ),
                       vec2( dot( pq1, pq1 ), s*(v1.x*e1.y-v1.y*e1.x) )),
                       vec2( dot( pq2, pq2 ), s*(v2.x*e2.y-v2.y*e2.x) ));

	return -sqrt(d.x)*sign(d.y);
}

float sdf_arc(vec2 p, vec2 sca, vec2 scb, float ra, float rb)
{
    p *= mat2(sca.x,sca.y,-sca.y,sca.x);
    p.x = abs(p.x);
    float k = (scb.y*p.x>scb.x*p.y) ? dot(p.xy,scb) : length(p.xy);
    return sqrt( dot(p,p) + ra*ra - 2.0*ra*k ) - rb;
}

float pr_circle(vec2 uv, vec2 pos, float rad, float smoothness){
	return smoothstep(smoothness,0.0,sdf_circle(uv, pos, rad));
}

float pr_rect(vec2 uv, vec2 pos, vec2 hsize, float smoothness){
	return smoothstep(smoothness,0.0,sdf_rect(uv, pos, hsize));
}

//919098, d0b17a, f1ab86, b7918c, 3e4e50
#define COL_LIGHT vec3(0.5686274509803921, 0.5647058823529412, 0.596078431372549)
#define COL_MS_LOAF vec3(0.8156862745098039, 0.6941176470588235, 0.47843137254901963)
#define COL_ACCENT vec3(0.9450980392156862, 0.6705882352941176, 0.5254901960784314)
#define COL_BACK vec3(0.7176470588235294, 0.5686274509803921, 0.5490196078431373)
#define COL_DARK vec3(0.24313725490196078, 0.3058823529411765, 0.3137254901960784)

vec3 ms_loaf(vec2 uv){
    float a = sdf_circle(uv, vec2(-0.1,0.02), 0.1);
	float b = sdf_circle(uv, vec2(+0.1,0.0), 0.1);
    float body = op_union(a,b,0.2); // body
    body = op_union(body,sdf_triangle(uv,vec2(-0.18,0.06),vec2(-0.17,0.14),vec2(-0.1,0.1)),0.01); // left ear
    body = op_union(body,sdf_triangle(uv,vec2(-0.15,0.07),vec2(-0.09,0.16),vec2(-0.03,0.11)),0.01); // right ear
    body = smoothstep(0.01,0.0,body);
    vec3 col = vec3(body) * COL_MS_LOAF;
    float leye = sdf_arc(uv + vec2(0.15,-0.07), vec2(-30.0,0.0), vec2(30,0.0), 0.5, 0.0);
    leye = smoothstep(0.09,0.03,abs(leye));
    col = mix(col, COL_DARK, leye);
    float reye = sdf_arc(uv + vec2(0.1,-0.07), vec2(-30.0,0.0), vec2(30,0.0), 0.5, 0.0);
    reye = smoothstep(0.09,0.03,abs(reye));
    col = mix(col, COL_DARK, reye);
    return col;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) /  iResolution.y;
    uv *= 0.5;
    vec3 colour = ms_loaf(uv);
    // Output to screen
    fragColor = vec4(colour,1.0);
}
