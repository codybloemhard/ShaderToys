#define MAX_STEPS 200
#define MAX_DIST 10000.
#define EPSILON 0.01
#define AMBIENT 0.05

vec2 raymarch_d(vec3, vec3);
float raymarch_s(vec3, vec3, float);

vec3 ro;

vec3 coloures[] = vec3[] ( //fool, orang is coloure!
	vec3(.2,.6,.3),
	vec3(.2,.2,.2),
	vec3(.8,.6,.3),
	vec3(.2,.2,.6),
	vec3(.6,.2,.2),
	vec3(.8,.6,.3),
	vec3(.2,.2,.2)
);

vec2 minx(vec2 a, vec2 b)
{
    float d = min(a.x, b.x);
    float m = step(a.x, d+.0001) * a.y;
    m += step(b.x, d+.0001) * b.y;
    return vec2(d, m);
    //https://stackoverflow.com/questions/45597118/fastest-way-to-do-min-max-based-on-specific-component-of-vectors-in-glsl
    //return mix(a, b, clamp(step(b.x, a.x), 0., 1.));//artifact at horizon?
}
//iq's blend functions
float sdfBlendUnion(float d1, float d2, float k){
    float h = clamp(0.5 + 0.5*(d2-d1)/k, 0.0, 1.0);
    return mix(d2, d1, h) - k*h*(1.0-h);
}
//with color
vec2 sdfBlendUnionCol(vec2 d1, vec2 d2, float k){
    float h = clamp(0.5 + 0.5*(d2.x-d1.x)/k, 0.0, 1.0);
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

float sdfSphere(vec3 p, vec3 so, float sr){
	return length(p - so) - sr;   
}

float sdfCapsule(vec3 p, float h, float r)
{
    p.y -= clamp(p.y, 0.0, h);
    return length(p) - r;
}

vec2 caterpillar(vec3 p){
    float z = 0.;
    float head = sdfSphere(p,vec3(-1.,1,z), .8);
    float balll = sdfSphere(p,vec3(-1.,2.5,z+.3), .15);
    float ballr = sdfSphere(p,vec3(-1.,2.5,z-.3), .15);
    float stickl = sdfCapsule(p-vec3(-1.,1.5,z+.3), 1., .05);
    float stickr = sdfCapsule(p-vec3(-1.,1.5,z-.3), 1., .05);
    float c = .9;
    vec3 q = p;
    q.x = mod(max(0.,p.x),c*2.)-c;
    float body0 = sdfSphere(q,vec3(0,1,z), .6);
    q.x = mod(max(0.,p.x + c),c*2.)-c;
    float body1 = sdfSphere(q,vec3(0,1,z), .6);
    c *= .5;
    q.x = mod(max(0.,p.x + c),c*2.)-c;
    float legl = sdfCapsule(q-vec3(0,.1,z+.3), .5, .05);
    float legr = sdfCapsule(q-vec3(0,.1,z-.3), .5, .05);
    float footl = sdfSphere(q,vec3(-.15,0,z+.3), .1);
    float footr = sdfSphere(q,vec3(-.15,0,z-.3), .1);
    float eyel = sdfSphere(p,vec3(-1.65,1.4,z+.3), .1);
    float eyer = sdfSphere(p,vec3(-1.65,1.4,z-.3), .1);
    float nose = sdfSphere(p,vec3(-1.6,.9,z), .3);
    vec2 d = sdfBlendUnionCol(vec2(head, 2.), vec2(balll, 1.), .1);
    d = sdfBlendUnionCol(d, vec2(ballr, 1.), .1);
    d = sdfBlendUnionCol(d, vec2(stickl, 2.), .15);
    d = sdfBlendUnionCol(d, vec2(stickr, 2.), .15);
    d = sdfBlendUnionCol(d, vec2(body0, 3.), .1);
    d = sdfBlendUnionCol(d, vec2(body1, 4.), .15);
    d = sdfBlendUnionCol(d, vec2(legl, 5.), .15);
    d = sdfBlendUnionCol(d, vec2(legr, 5.), .15);
    d = sdfBlendUnionCol(d, vec2(footl, 6.), .3);
    d = sdfBlendUnionCol(d, vec2(footr, 6.), .3);
    d = sdfBlendUnionCol(d, vec2(eyel, 1.), .1);
    d = sdfBlendUnionCol(d, vec2(eyer, 1.), .1);
    d = sdfBlendUnionCol(d, vec2(nose, 1.), .1);
    return d;
}

vec2 scene(vec3 p){
    vec2 boi = caterpillar(p);
    /*because of the infite lenght of the body,
	there is a weird shadow artifact in the neg x dir,
	as if the body kinda is there(but it shouldnt).
	so we cut that part off, but smoothly*/
    if(p.x < -3.)
        boi.x *= -p.x - 2.;
    vec2 floord = vec2(p.y, 0.);
    vec2 d = minx(boi, floord);
    return d;
}

vec3 calc_normal(vec3 p) {
	float d = scene(p).x;
    vec2 e = vec2(.001, 0);
    vec3 n = d - vec3(
        scene(p-e.xyy).x,
        scene(p-e.yxy).x,
        scene(p-e.yyx).x);
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
    vec3 e = vec3(str * .5 / dist);
    float shadow = raymarch_s(p + n * EPSILON * 2., ldir, 4.);
    e *= shadow;
    //directional light (sun)
    vec3 dld = normalize(vec3(-1, 1, 1));
    float dl = max(0., dot(n,dld)) * 0.3;
    dl *= raymarch_s(p + n * EPSILON * 2., dld, 4.);
    e += vec3(dl) * normalize(vec3(1., 0.9, 0.8)) * 1.;
    //sky light
    vec3 skydir = vec3(0,1,0);
    float sky = max(0., dot(n,skydir));
    sky *= raymarch_s(p + n * EPSILON * 2., skydir, 2.);
    e += sky * normalize(vec3(.8,.9,1.)) * 1.;
    //indirect light
    e += vec3(1.) * .2;
    e = max(vec3(AMBIENT), e);
    return e;
}

vec2 raymarch_d(vec3 ro, vec3 rd){
	vec2 dO = vec2(0);
    vec3 p;
    for(int i = 0; i < MAX_STEPS; i++){
    	p = ro + rd*dO.x;
        vec2 dS = scene(p);
        dO.x += dS.x;
        dO.y = dS.y;
        if(dO.x > MAX_DIST || dS.x < EPSILON)
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
        float dS = scene(p).x;
        dO += dS;
        res = min(res, k*dS/dO);
        if(dO > MAX_DIST) break;
    }
    return res;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord-0.5*iResolution.xy) / iResolution.y;
	
    vec3 col = vec3(0);
    float cdist = 6.;
    ro = vec3(-1. + sin(iTime*.1)*cdist, 2., 0. + cos(iTime*.1)*cdist);
    vec3 cd = normalize(vec3(-1, 1, 0) - ro);
    vec3 ri = -normalize(cross(cd, vec3(0,1,0)));
    vec3 up = -normalize(cross(ri, cd));
    vec3 planep = ro + (cd*1.) + (ri*uv.x) + (up*uv.y);
    vec3 rd = normalize(planep - ro);
    vec2 res = raymarch_d(ro, rd);
    if(res.x > MAX_DIST){
        col = vec3(.3, .7, 1.);
        col = mix(col, vec3(.7, .7, .9), exp(rd.y*-10.));
    }else{
    	col = calc_light(ro + rd * res.x);
       	float frac = fract(res.y);
        int low = int(res.y);
        int high = low + 1;
        col *= mix(coloures[low], coloures[high], frac);
    }
    col = pow(col, vec3(.4545));
    
    fragColor = vec4(col,1.0);
}