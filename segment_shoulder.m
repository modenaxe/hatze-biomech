function person = segment_shoulder(person,S)

if S == 3
	lr = 1;
else
	lr = -1;
end

P = person.segment(2).origin+person.segment(S).offset;
B = person.segment(1).origin+person.segment(S).offset;
R = person.segment(S).Rglobal;
i_m = person.sex;
PI = person.const.pi;

gamma_1 = person.density.shoulder_lateral(i_m);
gamma_2 = person.density.shoulder_medial(i_m);
gamma_T = person.density.shoulder_cutout(i_m);
gamma_s = person.density.humerous(i_m);     %IS THIS REQUIRED?? FORTRAN CODE USED GAM37=1030+20i_m in all cases including line 84

l_t = person.meas{1}.length;
at1 = person.segment(1).a(1);       
at4 = person.segment(1).a(4);       
at5 = person.segment(1).a(5);

d   = person.meas{S}.all(1);
b   = person.meas{S}.all(2)/2;
b1  = person.meas{S}.all(3)/2;
z_h = person.meas{S}.all(4);

bt1 = person.meas{1}.depths(1)/2;   
bt4 = person.meas{1}.depths(4)/2;   

if b < bt4
	fprintf ('warning depth of shoulder (%f) is smaller than depth of fourth thoraic segment (%f)', 2*b, 2*bt4);
end


%% Calculations

h1 = 0.68*at5 - at1;
j1 = 0.35*l_t - z_h;
j2 = 0.20*l_t - z_h;
j3 = 0.15*l_t;
d_z = j2 - 1.5*b1;

beta  = asin( d_z/d );
alpha = atan( h1/j1 );

d_x = d*cos(beta);
h_x = d_x - h1;
h_z = j3 - b1; % after simplication

gamma = atan( h_z/h_x );

% NB that beta is always tiny:
% disp('[alpha beta gamma]')
% disp(180/PI*[alpha beta gamma])

c2  = -(tan(beta) + tan(gamma));
c4  = -(b - 1.42*b1)/h_x;
c1  = 2.5*b1  - d_x*c2;
c3  = 1.42*b1 - d_x*c4;

c14 = c2*c3 + c1*c4;

c5  = j1-h1/tan(alpha); %0.35*l_t - z_h - h1*cot(alpha);  %c5 = 0 by definition!
c6  = j1/h1 - d_z/d_x;              % cot(alpha) - tan(beta)
c8  = bt4 - (j1-j2)*(bt4-bt1)/j1;
c9  = (bt4-bt1)/j1;
c10 = (0.42*at4-at1)/j1;
c11 = (2*at1-1.42*at4)/(j1^2);

A1 = @(z) c1 + c2*z;    % h1..d_x
B1 = @(z) c3 + c4*z;
A2 = @(z) c5 + c6*z;    % 0..h1
B2 = @(z) b*sqrt(z/h1);


% Mass and volume

v1 = 4/3*(c1*c3*h_x + (c2*c3 + c1*c4)*((h1+h_x)^2 - h1^2)/2 + ...
    c2*c4*((h1+h_x)^3 - h1^3)/3);
v2 = 8/3*b*(1/3*c5*h1+1/5*c6*h1^2);
v_s = 2*PI*(b1/2)^3/3;

at = @(e) at4 + c10.*(e+j1-j2) + c11.*(e+j1-j2).^2;
bt = @(e) c8-c9.*e;
u  = @(e) (at1 + (j2-e).*tan(alpha))./at(e);

sarg = @(e) sqrt(1-u(e).^2);
    
fun = @(e) bt(e).*at(e).*(PI/2-u(e).*sarg(e)-asin(u(e)));
v_T = integral(fun,-j3,j2);

m1  = gamma_1*v1;
m2  = gamma_2*v2;
m_s = gamma_1*v_s;  %or gamma_s?
m_T = gamma_T*v_T;

volume = v1 + v2 - v_s - v_T;
mass   = m1 + m2 - m_s - m_T;

% Mass centroid:
xc = 0;
yc = 0;

zeta2 = gamma_2*8*b*(1/5*c5*h1^2 + 1/7*c6*h1^3)/(3*m2);
%fun2 = @(e) at(e).*bt(e).*(PI/2-u(e).*sarg(e)-asin(u(e))).*e;
fun2 = @(e) fun(e).*e;
e_barm = m2*j2*(1-zeta2/h1) - gamma_T*integral(fun2,-j3,j2);
e_bar = e_barm/mass;

fun3 = @(e) at(e).*bt(e).*(at1.*(u(e).*sarg(e) + asin(u(e))-PI/2) +...
    2/3.*at(e).*sarg(e).^3);
JT = integral(fun3,-j3,j2);
zeta_barm = 4/3*gamma_1*(c1*c3*((h1+h_x)^2-h1^2)/2+...
    c14*((h1+h_x)^3-h1^3)/3 + c2*c4*((h1+h_x)^4-h1^4)/4)+...
    zeta2*m2-m_s*(d_x-3*b1/16)-JT*gamma_1;      %INCLUDED gamma_1. Mistake? in JT equation p39 Hatze. Included in fortran code equation for zetab
zeta_bar = zeta_barm/mass;

theta7 = atan(e_bar/(d_x-zeta_bar));
theta7 = lr*theta7;

zc = (at1+zeta_bar)/(cos(theta7));

% principal moments of inertia; 
f1 = @(e)at(e)-at1-(j2-e).*tan(alpha);
f2 = @(e)bt(e).*sqrt(1-(((j2-e).*tan(alpha)+at1)./at(e)).^2);     %f2=bt(e)*sqrt(1-f_2^2) where f_2 is from Hatze 79 
f3 = c1*c3^3*h_x + (c2*c3^3 + 3*c1*c3^2*c4)*((h1+h_x)^2-h1^2)/2+...
    3*(c1*c3*c4^2+c2*c3^2*c4)*((h1+h_x)^3-h1^3)/3+...
    (c1*c4^3+3*c2*c3*c4^2)*((h1+h_x)^4-h1^4)/4+...
    c2*c4^3*((h1+h_x)^5-h1^5)/5;
f4 = c3*c1^3*h_x + (c4*c1^3 + 3*c3*c1^2*c2)*((h1+h_x)^2-h1^2)/2+... %same as f3, but with c3 swapped for c1 and c2 swapped for c4
    3*(c3*c1*c2^2+c4*c1^2*c2)*((h1+h_x)^3-h1^3)/3+...
    (c3*c2^3+3*c4*c1*c2^2)*((h1+h_x)^4-h1^4)/4+...
    c4*c2^3*((h1+h_x)^5-h1^5)/5;

I_M = 4/3*gamma_1*(c1*c3*((h1+h_x)^3-h1^3)/3 +...
    c14*((h1+h_x)^4-h1^4)/4 + c2*c4*((h1+h_x)^5-h1^5)/5) -...
    2*zeta_bar*4/3*gamma_1*(c1*c3*((h1+h_x)^2-h1^2)/2 +...
    c14*((h1+h_x)^3-h1^3)/3 + c2*c4*((h1+h_x)^4-h1^4)/4) +  m1*zeta_bar^2;
I_s = m_s*(0.4*(b1/2)^2 + (d_x-0.375*(b1/2)-zeta_bar)^2);

fun4 = @(e) 4/15*f1(e).*(f2(e).^3) + 16/175*f1(e).^3.*f2(e) +...
    4/3*f1(e).*f2(e).*(zeta_bar-0.4*(at(e)-at1)-0.6*(j2-e)*tan(alpha)).^2;
fun5 = @(e) 16/175*f1(e).^3.*f2(e)+...
    4/3*f1(e).*f2(e).*((zeta_bar-0.4*(at(e)-at1)-0.6*(j2-e)*tan(alpha)).^2+(e-e_bar).^2);
fun6 = @(e) 4/15*f1(e).*(f2(e).^3) + 4/3*f1(e).*f2(e).*(e-e_bar).^2;
I_eT = gamma_1*integral (fun4,-j3, j2);
I_nT = gamma_1*integral (fun5,-j3, j2);
I_zT = gamma_1*integral (fun6,-j3, j2);


Ip_x = 4/15*gamma_1*f3 + ...
  I_M - I_s + ...
  0.533*gamma_1*b^3*(c5*h1/5+c6*h1^2/7) + ...
  8/3*gamma_1*b*((c5*h1^3/7+c6*h1^4/9) + ...
  -2*zeta_bar*(c5*h1^2/5+c6*h1^3/7) + zeta_bar^2*(c5*h1/3+c6*h1^2/5)) + ...
  -I_eT;

Ip_y = 16/175*gamma_1*f4...
    +I_M -I_s +...
    + (m1 - m_s)*e_bar^2+...
    0.1828*gamma_1*b*(c5^3*h1/3 + 3*c5^2*c6*h1^2/5 + 3*c5*c6^2*h1^3/7 + c6^3*h1^4/9)+...
    8/3*gamma_1*b*((1+(j2/h1)^2)*(c5*h1^3/7+c6*h1^4/9)-...
    2*(zeta_bar+(j2^2-e_bar*j2)/h1)*(c5*h1^2/5+c6*h1^3/7)+...
    (zeta_bar^2+(e_bar-j2)^2)*(c5*h1/3+c6*h1^2/5))-I_nT;

% Ip_z = 0; by definition
Ip_z = 4/15*gamma_1*f3 + ...
  0.533*gamma_1*b^3*(c5*h1/5 + c6*h1^2/7) + ...
  16/175*gamma_1*f4 + (m1 - m_s)*e_bar^2+...
  0.1828*gamma_1*b*(c5^3*h1/3 + 3*c5^2*c6*h1^2/5 + 3*c5*c6^2*h1^3/7 + c6^3*h1^4/9)+...
  8/3*gamma_1*b*(((j2/h1)^2)*(c5*h1^3/7+c6*h1^4/9)...
  -2*((j2^2-e_bar*j2)/h1)*(c5*h1^2/5+c6*h1^3/7)+...
  ((e_bar-j2)^2)*(c5*h1/3+c6*h1^2/5))...
    -0.4*m_s*(b1/2)^2-I_zT;


% principal moments of inertia w.r.t local systems origin
PIOX=Ip_x+mass*zc^2;
PIOY=Ip_y+mass*zc^2;
PIOZ=Ip_z;

%coordinates of origin of axes
OX=0;
OY=(0.8*l_t+(e_bar/(d_x-zeta_bar))*(d_x+at1))*sin(person.segment(1).theta);
OZ=(0.8*l_t+(e_bar/(d_x-zeta_bar))*(d_x+at1))*cos(person.segment(1).theta);

%distances (between origins of segments) 
O1O7 = 0.8*l_t+e_bar*(d_x+at1)/(d_x-zeta_bar);
O7O8 = (d_x+at1)/cos(theta7);


R7 = [cos(theta7), 0, sin(theta7); 0, 1, 0; -sin(theta7), 0, cos(theta7)];

person.segment(S).Rglobal = R7'*R;
person.segment(S).Rlocal = R7'*person.segment(S).Rlocal;

person.segment(S).theta = theta7;

Oshoulder = B + person.segment(1).Rglobal*[0;0;O1O7];
Oarm = Oshoulder + person.segment(S).Rglobal*[ 0 ; 0; (at1+d_x)/cos(theta7) ];
Ocutout = P + person.segment(1).Rglobal*[0;0;-z_h-d_z-1.5*b1];
person.segment(S).origin = Oshoulder;
person.segment(S+1).origin = Oarm;
person.segment(S+1).origin1 = O7O8;

person.segment(S).mass = mass;
person.segment(S).volume = volume;
person.segment(S).centroid = [xc; yc; zc];
person.segment(S).Minertia = [Ip_x,Ip_y,Ip_z];


%% Plot

hr = b1/2; % radius of humerous

if person.plot || person.segment(S).plot

  if S == 7
    rcorr = [0 180 0];
    rcorr_plates = [0 0 180];
    lr_sign = 1;
  else
    rcorr = [0 0 0];
    rcorr_plates = [0 0 0];
    lr_sign = -1;
  end

  Rlocal = R*rotation_matrix_zyx(rcorr);
  Rlocal_plates = R*rotation_matrix_zyx(rcorr_plates);

  opts = {...
    'rotate',R*rotation_matrix_zyx(rcorr),...
    'colour',person.segment(S).colour,...
    'opacity',person.segment(S).opacity(1),...
    'edgeopacity',person.segment(S).opacity(2)};
  
  % lateral wedge
  
  a10 = A1(d_x);
  b10 = B1(d_x);
  a1h = A1(h1);
  b1h = B1(h1);
  
  plot_parabolic_wedge(...
    Oarm,...
	[a10 b10],[a1h b1h],lr_sign*h_x,'skew', j2 - tan(beta)*h1 - a1h,...
	'drop',-b1,...
    'face',[true false],...
    'humoffset',b1,...
    'humradius',hr,...
    opts{:})
  
  plot_sphere(Oarm,hr,'longrange',[0 lr_sign],opts{:})
  
  % medial wedge
  
  Nw = 10;
  hrange = linspace(h1,0,Nw);
  
  for nn = 1:Nw-1
    
    a20 = A2(hrange(nn));
    b20 = B2(hrange(nn));
  
    a2h = A2(hrange(nn+1));
    b2h = B2(hrange(nn+1));
    
    if a2h < eps, a2h = 0.00001; end
    if b2h < eps, b2h = 0.00001; end
  
	plot_parabolic_wedge(...
		Oarm+R*[0;0;-h_x-(nn-1)*h1/(Nw-1)],...
		[a20 b20],[a2h b2h],lr_sign*h1*1/(Nw-1), ...
		'skew', j2 - tan(beta)*hrange(nn+1) - a2h , ...
		'drop', j2 - tan(beta)*hrange(nn)   - a20,...
		'face',[false false],...
		opts{:})

  end
  % shoulder origins
 
%  xyz = [ [0;0;0] , [0;0;at1] , [0;0;at1+h1] , [0;0;at1+h1+h_x] ];
%  XYZ = Rlocal*xyz;
%  plot3(Oshoulder(1)+XYZ(1,:),Oshoulder(2)+XYZ(2,:),Oshoulder(3)+XYZ(3,:),'r.','markersize',30)

  % cutout plates
  
  ne = 20;
  co_x = nan(ne,2*ne);
  co_y = nan(ne,2*ne);
  co_z = nan(ne,2*ne); 
  
  zz = linspace(-j3,j2,ne);
  ellipse_points = @(ze,xi) bt(ze).*sqrt(1 - ( xi./at(ze) ).^2);
  cutout_medial  = @(ze) at1+tan(alpha)*(j2-ze);
  
  for nn = 1:ne
    ze  = zz(nn);
    ml_points = linspace(cutout_medial(ze),at(ze),ne);
    y3  = ellipse_points(ze,ml_points);
    s3 = [ [ze*ones(size(y3));y3;ml_points], [ze*ones(size(y3));-fliplr(y3);fliplr(ml_points)] ];
    
    S3 = Rlocal_plates*s3;  
    
    co_x(nn,:) = S3(1,:)+Ocutout(1); 
    co_y(nn,:) = S3(2,:)+Ocutout(2); 
    co_z(nn,:) = S3(3,:)+Ocutout(3);
%    plot3(co_x(nn,:),co_y(nn,:),co_z(nn,:),'b.','markersize',20)
  end
  
  for nn = 2:ne
    patch(...
      [co_x(nn-1,:) co_x(nn,end:-1:1)],...
      [co_y(nn-1,:) co_y(nn,end:-1:1)],...
      [co_z(nn-1,:) co_z(nn,end:-1:1)],...
      [0 0 0],...
      'facecolor',person.segment(S).colour,...
      'facealpha',person.segment(S).opacity(1),...
      'edgealpha',person.segment(S).opacity(2)...
      )
  end
end

end


