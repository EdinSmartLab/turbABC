%This function implements the LRR RST model
%by P.E. Hamlington, January 16, 2009

function dy =lrr_4(t,y)

global k0e0 a1 a2 a3 a4 S0 Lt t1 t2 t3 t4 t5 t6 cmu c ce1 ce2

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

%Strain rate tensor
S(1,1)=0;
S(2,2)=-S(1,1);
S(3,3)=0;
S(1,2)=0;
S(1,3)=0;
S(2,3)=0;
S(2,1)=S(1,2);
S(3,1)=S(1,3);
S(3,2)=S(2,3);

%Rotation rate tensor
W(1,1)=0;
W(2,2)=0;
W(3,3)=0;
W(1,2)=0;
W(1,3)=0;
W(2,3)=0;
W(2,1)=-W(1,2);
W(3,1)=-W(1,3);
W(3,2)=-W(2,3);

%kinetic energy production P=-k*a_{ij}*S_{ij}
aS=a(1,:)*S(:,1)+a(2,:)*S(:,2)+a(3,:)*S(:,3);
P=-k*aS; 

C1=1.5;
C2=0.8;
C3=1.75/2;
C4=1.31/2;

alf1=(P/e-1+C1);
alf2=(C2-4/3);
alf3=(C3-1);
alf4=(C4-1);

%These are the governing equations
i=1;
j=1;
dy(1)=-(alf1/ke)*a(i,j)+alf2*S(i,j)...
      +alf3*(a(i,:)*S(:,j)+S(i,:)*a(:,j)-(2/3)*aS)...
      -alf4*(a(i,:)*W(:,j)-W(i,:)*a(:,j));  
i=2;
j=2;
dy(2)=-(alf1/ke)*a(i,j)+alf2*S(i,j)...
      +alf3*(a(i,:)*S(:,j)+S(i,:)*a(:,j)-(2/3)*aS)...
      -alf4*(a(i,:)*W(:,j)-W(i,:)*a(:,j));  
i=3;
j=3;
dy(3)=-(alf1/ke)*a(i,j)+alf2*S(i,j)...
      +alf3*(a(i,:)*S(:,j)+S(i,:)*a(:,j)-(2/3)*aS)...
      -alf4*(a(i,:)*W(:,j)-W(i,:)*a(:,j));    
i=1;
j=2;
dy(4)=-(alf1/ke)*a(i,j)+alf2*S(i,j)...
      +alf3*(a(i,:)*S(:,j)+S(i,:)*a(:,j))...
      -alf4*(a(i,:)*W(:,j)-W(i,:)*a(:,j));     
i=1;
j=3;
dy(5)=-(alf1/ke)*a(i,j)+alf2*S(i,j)...
      +alf3*(a(i,:)*S(:,j)+S(i,:)*a(:,j))...
      -alf4*(a(i,:)*W(:,j)-W(i,:)*a(:,j));
i=2;
j=3;
dy(6)=-(alf1/ke)*a(i,j)+alf2*S(i,j)...
      +alf3*(a(i,:)*S(:,j)+S(i,:)*a(:,j))...
      -alf4*(a(i,:)*W(:,j)-W(i,:)*a(:,j));   
    
%dk/dt=-ka_{ij}S_{ij}-e
%de/dt=(-kC_{e1}a_{ij}S_{ij}-C_{e2}e)*e/k
dy(7)=P-e; %dk/dt
dy(8)=(ce1*P-ce2*e)/ke; %de/dt