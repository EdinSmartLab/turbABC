%This function implements the LRR RST model
%by P.E. Hamlington, January 16, 2009

function dy =lrr(t,y)

global ce1 ce2

dy = zeros(8,1);  

%Anisotropy tensor
a(1,1)=y(1);
a(2,2)=y(2);
a(3,3)=y(3);
a(1,2)=y(4);
a(1,3)=y(5);
a(2,3)=y(6);
a(2,1)=a(1,2);
a(3,1)=a(1,3);
a(3,2)=a(2,3);

k=y(7); %turbulence kinetic energy
e=y(8); %dissipation rate
ke=k/e; %k/e

C1=1.5;
C2=0.8;
C3=1.75/2;
C4=1.31/2;

alf1=(-1+C1);
alf2=(C2-4/3);
alf3=(C3-1);
alf4=(C4-1);

%These are the governing equations
i=1;
j=1;
dy(1)=-(alf1/ke)*a(i,j); 

i=2;
j=2;
dy(2)=-(alf1/ke)*a(i,j);  

i=3;
j=3;
dy(3)=-(alf1/ke)*a(i,j);  

i=1;
j=2;
dy(4)=-(alf1/ke)*a(i,j);  

i=1;
j=3;
dy(5)=-(alf1/ke)*a(i,j);

i=2;
j=3;
dy(6)=-(alf1/ke)*a(i,j);  
    
%dk/dt=-ka_{ij}S_{ij}-e
%de/dt=(-kC_{e1}a_{ij}S_{ij}-C_{e2}e)*e/k
dy(7)=-e; %dk/dt
dy(8)=-ce2*e/ke; %de/dt