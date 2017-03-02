function person = segment_abdomino_thoracic(person,S)
%% abdomino-thoracic

person.segment(S).origin = person.q(1:3);
O1 = person.segment(S).origin + person.segment(S).offset;
i_m = person.sex;
PI = person.const.pi;

N  = 10; % number of disks
Nt =  7; % number of disks for thoracic region

% Indices for thoracic and abdominal (resp.) groups of disks:
indt = 1:Nt;
inda = (Nt+1):N;

% Measurements and variables:
a  = nan(1,N);
b  = nan(1,N);
w  = nan(1,N);

% coefficients for lungs calcs: (how to generalise?)
c      = nan(1,Nt);
c(1:2) = 0.8333;
c(3:6) = 0.2;
c(7)   = 0.4111;

% Densities:
gamma_t = person.density.thoracic_wall(i_m);
gamma_a = person.density.abdomen(i_m);
gamma_l = person.density.lungs(i_m);
gamma_b = person.density.breasts(i_m); % (? see A2.94, gamma_b for legs = 1200)

%% Measurements

l = person.meas{S}.length;

d_11 = person.meas{11}.all(19); % AP distance between centre of hip joint & Symphysion
z_h  = mean([person.meas{3}.all(4), person.meas{7}.all(4)]); % height between shoulder and O1

d = person.meas{S}.all(08);    % nipple-to-nipple distance
r = person.meas{S}.all(09)/2;  % radius of breast
h = person.meas{S}.all(21);    % height below C5 of nipple

% thorax ML widths (7) and AP thicknesses (10)
X1 = person.meas{S}.widths;
Y1 = person.meas{S}.depths;

%% Implicit measurements

RR = person.segment(S).Rglobal;

person.segment(S+1).origin = O1+person.segment(S).Rlocal*[0;0;l];

g = (1+0.3*i_m)*d_11;

% symmetric chest until the end of the lungs:
w(indt)  = Y1(indt)/2; % in Hatze's code w(indt) is set to 0
b(indt)  = Y1(indt)/2;

% interpolate width minus shoulder; implies 10 disks:
a([1, 5:10]) = X1([1, 5:10])/2;
a(4) = a(5);
ii = [2, 3];
a(ii) = a(5)+(0.42*a(5)-a(1)).*l/N*(4-ii)/(0.35*l-z_h)+...
    (2*a(1)-1.42*a(5))*((l./N*(4-ii))/(0.35*l-z_h)).^2;

%male or female
jj = floor(h/(l/N)); % Integer Conversion != Rounding
if h==0
    b_j = 0;
else
    b_j = b(jj);
end 

% interpolate asymmetric belly thicknesses:
w(inda) = interp1([Nt N],[Y1(Nt)/2 g],inda);
b(inda) = Y1(inda) - w(inda);

person.segment(S).a = a;
person.segment(S).b = b;

% Lungs:
a2 = a(indt).*(c(1)-c(indt));
b2 = (b(indt)-a(indt)/6).*sqrt(1-(c(indt)./c(1)).^2);


%% Calculations

v_e = PI*a(indt).*b(indt)*l/N; % volume of each thoracic disk
v_p = 8/3*a2.*b2*l/N; % volume of lungs in each disk

m_e = gamma_t*v_e; % mass of thorax as if it were solid
m_p = (gamma_t-gamma_l)*v_p; % mass difference between thorax & lungs
m_t = (v_e-v_p)*gamma_t; % mass of thoracic volume without lungs
m_g = v_p*gamma_l; % mass of lungs only
%m_t+m_g=m_e-m_p

v_1 = PI*a(inda).*w(inda)*l/2/N;    
v_2 = PI*a(inda).*b(inda)*l/2/N;    
m_1 = gamma_a*v_1;
m_2 = gamma_a*v_2;

v_f = (1-i_m)*4/3*PI*r^3; % breasts (2 hemispheres)
m_f = gamma_b*v_f;

volume = sum(v_e)+sum(v_1+v_2)+v_f;
mass = sum(m_t+m_g)+sum(m_1+m_2)+m_f;

% Mass centroid (w.r.t original segment axes)
xc = 0;

yc = ( ...
  sum( ((m_1+m_2).*0.424.*(b(inda).^2-w(inda).^2))./(b(inda)+w(inda)))...  %= sum(a(inda).*(b(inda).^2-w(inda).^2).*gamma_a*l/N*PI*0.212 ... 
  + m_f*(b_j+3/8*r) ...
  )/mass;

zc = ( ...
  sum( (m_t+m_g).*(21-2*indt)*l/2/N ) ...
  + sum( (m_1+m_2).*(21-2*inda)*l/2/N ) ...
  + m_f*(l-h) ...
  )/mass;

% Moments of inertia w.r.t centroid
s = l^2/1200;
I_x = m_e.*((b(indt).^2)/4 +s) ...
      - m_p.*((b2(indt).^2)/5+s) ...
      + (m_e-m_p).*(yc^2+(l*(21-2*indt)/20-zc).^2);
I2_x = sum(I_x) ...
       + sum(...
           m_1.*(0.07*w(inda).^2+s+(-0.424*w(inda)-yc).^2+(l*(21-2*inda)./20-zc).^2) ...
         + m_2.*(0.07*b(inda).^2+s+(+0.424*b(inda)-yc).^2+(l*(21-2*inda)./20-zc).^2) ...
       ) ...
       + m_f*(0.2594*r^2+(l-h-zc)^2+(b_j+3*r/8-yc)^2);
Ip_x = I2_x;

I_y = m_e.*((a(indt).^2)/4+s) ...          %error in Hatze (1979)A2.31: does not include division by 4 of a_i^2
      - m_p.*(0.06857*a2(indt).^2+s+(c(indt).*a(indt)+0.4*a2(indt)).^2) ...
      + (m_e-m_p).*(l*(21-2*indt)/20-zc).^2;
I2_y = sum(I_y)... 
       + sum((m_1+m_2).*((a(inda).^2)/4+s+(l*(21-2*inda)./20-zc).^2)) ...
       + m_f*(0.4*r^2+(l-h-zc)^2+(d/2)^2);

I_z = m_e.*(a(indt).^2+b(indt).^2)/4 ...
      - m_p.*(0.06857*a2.^2+(b2.^2)/5+(c(indt).*a(indt)+0.4*a2(indt)).^2) ...
      + (m_e-m_p).*yc^2;
I2_z = sum(I_z) + sum( ...
       m_1.*(0.07*w(inda).^2+(a(inda).^2)/4+(-0.424*w(inda)-yc).^2) ...
       + m_2.*(0.07*b(inda).^2+(a(inda).^2)/4+(0.424*b(inda)-yc).^2) ...
       ) + m_f*(0.2594*r^2+(b_j+3*r/8-yc).^2+(d/2)^2);

I_yz = sum((m_e-m_p).*(-yc).*(l*(21-2*indt)/20-zc));

I2_yz = sum(I_yz) + sum((l*(21-2*inda)./20-zc).*(...
       m_1.*(-0.424*w(inda)-yc) + m_2.*(+0.424*b(inda)-yc))...
       ) + m_f*(b_j+3*r/8-yc)*(l-h-zc);

Ip_y = (I2_y+I2_z)/2+sqrt(1/4*(I2_y-I2_z)^2+I2_yz^2);   
Ip_z = (I2_y+I2_z)/2-sqrt(1/4*(I2_y-I2_z)^2+I2_yz^2);

theta = atan(I2_yz/(I2_z-Ip_y));

%centroid w.r.t local coordinate systems (since principal axes differ from
%original segment axes)
xbc=xc;
ybc=yc*cos(theta)+zc*sin(theta);
zbc=zc*cos(theta)-yc*sin(theta);

%principal moments of inertia w.r.t local systems origin
PIOX=Ip_x+mass*(ybc^2+zbc^2);
PIOY=Ip_y+mass*zbc^2;
PIOZ=Ip_z+mass*ybc^2;

person.segment(S).mass = mass;
person.segment(S).volume = volume;
person.segment(S).centroid = [xc; yc; zc];
person.segment(S).theta = theta;
person.segment(S).Minertia = [Ip_x,Ip_y,Ip_z];

%% Plot

if person.plot || person.segment(S).plot

  opt  = {'opacity',person.segment(S).opacity(1),'edgeopacity',person.segment(S).opacity(2),'colour',person.segment(S).colour};
  optl = {'opacity',min(1,2*person.segment(S).opacity(1)),'edgeopacity',person.segment(S).opacity(2),'colour',person.segment(S).colour};

  % thorax:
  for ii = indt
    ph = l-ii*l/N; % plate height

    plot_elliptic_plate(O1+RR*[0;0;ph],[a(ii) b(ii)],l/N,opt{:},'rotate',RR);

    % lungs:
    plot_parabolic_plate(O1+RR*[ c(ii)*a(ii);0;ph],[ a2(ii) b2(ii)],l/N,optl{:});
    plot_parabolic_plate(O1+RR*[-c(ii)*a(ii);0;ph],[-a2(ii) b2(ii)],l/N,optl{:});
  end

  % abdomen:
  for ii = inda
    ph = l-ii*l/N; % plate height
    plot_elliptic_plate(O1+RR*[0;0;ph],[a(ii) -w(ii)],l/N,'segment',[0 0.5],opt{:},'rotate',RR)
    plot_elliptic_plate(O1+RR*[0;0;ph],[a(ii)  b(ii)],l/N,'segment',[0 0.5],opt{:},'rotate',RR)
  end

  % breasts:
  if i_m == 0 % female
    plot_sphere(O1+RR*[+d/2; b(jj); l-h],r,'latrange',[-1 1],'N',[20 10],opt{:})
    plot_sphere(O1+RR*[-d/2; b(jj); l-h],r,'latrange',[-1 1],'N',[20 10],opt{:})
  end

end
