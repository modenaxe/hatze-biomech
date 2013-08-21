function person = thigh(person,S,lr,h)

P = person.origin{S} + person.offset{S};
i_m = person.sex;

%% Thigh

N = 10; 
indf = 1:N;

%% Densities

wp= 1;
wt= 1;
v = wp/wt-1; % v is the subcutaneous fat indicator;
gamma_i1 = @(ii,i_m) 1000+(30+10*(ii-2))/((1+2*v)^2)+20*i_m; % for i = 1,2,3;
gamma_i2 = @(i_m) 1030+10*i_m; % for i = 4,5,6,7,8,9;
gamma_i3 = @(i_m) 1490+10*i_m; % for i =10;
gamma_0 = 1020 + 30/((1+2*v)^2)+20*i_m; 

gamma_i = @(i_m) [gamma_i1(1:3,i_m) gamma_i2(i_m) gamma_i2(i_m) gamma_i2(i_m) gamma_i2(i_m) gamma_i2(i_m) gamma_i2(i_m) gamma_i3(i_m)];

%% Measurements

a = person.meas{S}.diam/2; % ai 
u = person.meas{S}.perim; 
b = sqrt(((u/pi).^2)/2-a.^2); % b
l_1 = person.meas{S}.length;

person.meas{S}.a = a;
person.meas{S}.b = b;

%% Calculations

% Mass 
v_i = pi*a.*b*l_1/N;
m_i = gamma_i(i_m).*v_i;
a_1 = a(1);
b_1 = b(1);
v_0 = 2*pi*a_1*b_1*h/3;
m_0 = gamma_0*v_0;

v=sum(v_i)+v_0;
m=sum(m_i)+m_0;

% Mass centroid:
xc = P(1);
yc = P(2);
zc = P(3) - (m_0*0.4*h+sum(h+l_1*(2*indf-1)/20))/m;

% Moments of inertia:
I_x0 = m_0*(b_1^2/4+0.0686*h^2);
I_y0 = m_0*(0.15*a_1^2+0.0686*h^2);
I_z0 = m_0*(0.15*a_1^2+b_1^2/4);
I_xi = m_i.*(3*b.^2+(l_1/10)^2)/12;
I_yi = m_i.*(3*a.^2+(l_1/10)^2)/12;
I_zi = m_i.*(a.^2+b.^2)/4;

% principal moments of inertia; 
Ip_x = I_x0+m_0.*(-0.4*h-zc).^2+sum(I_xi+m_i.*(h*(2*indf-1)/20-zc).^2);
Ip_y = I_y0+m_0.*(-0.4*h-zc).^2+sum(I_yi+m_i.*(h*(2*indf-1)/20-zc).^2);
Ip_z= I_z0+sum(I_zi);

disp('-------------------------')
if lr == 'l'
  disp('Left thigh section')
elseif lr == 'r'
  disp('Right thigh section')
end
disp('-------------------------')
fprintf('Mass:     %2.3f kg\n',m)
fprintf('Volume:   %1.4f m^3\n',v)
fprintf('Centroid: [ %2.0f , %2.0f , %2.0f ] mm\n',1000*xc,1000*yc,1000*zc)
fprintf('Moments of inertia: [ %2.3f , %2.3f , %2.3f ] kg.m^2\n',Ip_x,Ip_y,Ip_z)

Q = P+[0;0;-l_1-h];
person.origin{S+1} = Q;

%% Plot

opt  = {'opacity',person.opacity{S}(1),'edgeopacity',person.opacity{S}(2),'colour',person.color{S}};
 
for ii = indf
  ph = l_1-ii*l_1/N; % plate height
  plot_elliptic_plate(Q+[0;0;ph],[a(ii) b(ii)],l_1/N,opt{:})
end

plot_hoof(P-[0;0;h],a(1),b(1),h,opt{:})

end
