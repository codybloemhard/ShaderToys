#define MAX_STEPS 200
#define MAX_DIST 10000.
#define EPSILON 0.01
#define AMBIENT 0.05

float raymarch_d(vec3, vec3);
float raymarch_s(vec3, vec3, float);

vec3 ro;

//https://stackoverflow.com/questions/45597118/fastest-way-to-do-min-max-based-on-specific-component-of-vectors-in-glsl
vec2 minx(vec2 a, vec2 b)
{
    return mix( a, b, step( b.x, a.x ) );
}
//iq's blend functions
float sdfBlendUnion(float d1, float d2, float k){
    float h = clamp(0.5 + 0.5*(d2-d1)/k, 0.0, 1.0);
    return mix(d2, d1, h) - k*h*(1.0-h);
}

float sdfBlendSub(float d1, float d2, float k) {
    float h = clamp(0.5 - 0.5*(d2+d1)/k, 0.0, 1.0);
    return mix(d2, -d1, h) + k*h*(1.0-h);
}

float sdfBlendInter(float d1, float d2, float k) {
    float h = clamp(0.5 - 0.5*(d2-d1)/k, 0.0, 1.0);
    return mix(d2, d1, h) + k*h*(1.0-h);
}

float sphere(vec3 p, vec3 so, float sr){
	return length(p - so) - sr;   
}

float capsule(vec3 p, float h, float r)
{
    p.y -= clamp(p.y, 0.0, h);
    return length(p) - r;
}

float caterpillar_dist(vec3 p){
    float z = 0.;
    float head = sphere(p,vec3(-1.,1,z), .8);
    float balll = sphere(p,vec3(-1.,2.5,z+.3), .15);
    float ballr = sphere(p,vec3(-1.,2.5,z-.3), .15);
    float stickl = capsule(p-vec3(-1.,1.5,z+.3), 1., .05);
    float stickr = capsule(p-vec3(-1.,1.5,z-.3), 1., .05);
    float c = .9;
    vec3 q = p;
    q.x = mod(max(0.,p.x),c*2.)-c;
    float body0 = sphere(q,vec3(0,1,z), .6);
    q.x = mod(max(0.,p.x + c),c*2.)-c;
    float body1 = sphere(q,vec3(0,1,z), .6);
    c *= .5;
    q.x = mod(max(0.,p.x + c),c*2.)-c;
    float legl = capsule(q-vec3(0,.1,z+.3), .5, .05);
    float legr = capsule(q-vec3(0,.1,z-.3), .5, .05);
    float footl = sphere(q,vec3(-.15,0,z+.3), .1);
    float footr = sphere(q,vec3(-.15,0,z-.3), .1);
    float eyel = sphere(p,vec3(-1.65,1.4,z+.3), .1);
    float eyer = sphere(p,vec3(-1.65,1.4,z-.3), .1);
    float nose = sphere(p,vec3(-1.6,.9,z), .3);
    float d = sdfBlendUnion(head, balll, .1);
    d = sdfBlendUnion(d, ballr, .1);
    d = sdfBlendUnion(d, stickl, .15);
    d = sdfBlendUnion(d, stickr, .15);
    d = sdfBlendUnion(d, body0, .1);
    d = sdfBlendUnion(d, body1, .15);
    d = sdfBlendUnion(d, legl, .15);
    d = sdfBlendUnion(d, legr, .15);
    d = sdfBlendUnion(d, footl, .3);
    d = sdfBlendUnion(d, footr, .3);
    d = sdfBlendUnion(d, eyel, .1);
    d = sdfBlendUnion(d, eyer, .1);
    d = sdfBlendUnion(d, nose, .1);
    return d;
}

float scene_dist(vec3 p){
    float boi = caterpillar_dist(p);
    /*because of the infite lenght of the body,
	there is a weird shadow artifact in the neg x dir,
	as if the body kinda is there(but it shouldnt).
	so we cut that part off, but smoothly*/
    if(p.x < -4.) 
        boi *= -p.x - 3.;
    float floord = p.y;
    float d = min(boi, floord);
    return d;
}

vec3 calc_normal(vec3 p) {
	float d = scene_dist(p);
    vec2 e = vec2(.001, 0);
    vec3 n = d - vec3(
        scene_dist(p-e.xyy),
        scene_dist(p-e.yxy),
        scene_dist(p-e.yyx));
    return normalize(n);
}

vec3 calc_light(vec3 p){
	vec3 n = calc_normal(p);
    //point light
    vec3 lpos = vec3(ro.x, 5., ro.z);
    vec3 tol = lpos - p;
    float dist = length(tol);
    vec3 ldir = tol / dist;
    float str = max(0.,dot(n, ldir));
    vec3 e = vec3(str * 1. / dist);
    float shadow = raymarch_s(p + n * EPSILON * 2., ldir, 4.);
    e *= shadow;
    //directional light (sun)
    vec3 dld = normalize(vec3(-1, 1, 1));
    float dl = max(0., dot(n,dld)) * 0.3;
    dl *= raymarch_s(p + n * EPSILON * 2., dld, 4.);
    e += vec3(dl) * vec3(0.9, 0.5, 0.2);
    //sky light
    vec3 skydir = vec3(0,1,0);
    float sky = max(0., dot(n,skydir));
    sky *= raymarch_s(p + n * EPSILON * 2., skydir, 2.);
    e += sky * vec3(.3,.5,.9) * .2;
    //indirect light
    e += vec3(1.) * .1;
    e = max(vec3(AMBIENT), e);
    return e;
}

float raymarch_d(vec3 ro, vec3 rd){
	float dO = 0.;
    vec3 p;
    for(int i = 0; i < MAX_STEPS; i++){
    	p = ro + rd*dO;
        float dS = scene_dist(p);
        dO += dS;
        if(dO > MAX_DIST || dS < EPSILON)
            break;
    }
    return dO;
}

float raymarch_s(vec3 ro, vec3 rd, float k){
	float dO = 0.001;
    vec3 p;
    float res = 1.;
    for(int i = 0; i < MAX_STEPS; i++){
    	p = ro + rd*dO;
        float dS = scene_dist(p);
        dO += dS;
        res = min(res, k*dS/dO);
        if(dO > MAX_DIST) break;
    }
    return res;
}

vec4 raymarch_p(vec3 ro, vec3 rd){
	float dO = raymarch_d(ro, rd);
    return vec4(ro + rd * dO, dO);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord-0.5*iResolution.xy) / iResolution.y;
	
    vec3 col = vec3(0);
    float cdist = 10.;
    ro = vec3(-1. + sin(iTime*.2)*cdist, 2., 0. + cos(iTime*.2)*cdist);
    vec3 cd = normalize(vec3(-1, 1, 0) - ro);
    vec3 ri = -normalize(cross(cd, vec3(0,1,0)));
    vec3 up = -normalize(cross(ri, cd));
    vec3 planep = ro + (cd*1.) + (ri*uv.x) + (up*uv.y);
    vec3 rd = normalize(planep - ro);
    vec4 res = raymarch_p(ro, rd);
    if(res.w > MAX_DIST){
        col = vec3(.3, .7, 1.);
        col = mix(col, vec3(.7, .7, .9), exp(rd.y*-10.));
    }else
    	col = calc_light(res.xyz);
    
    col = pow(col, vec3(.4545));
    
    fragColor = vec4(col,1.0);
}