%This m-file solves various turbulence flow models for homogeneous turbulence
%that is strain, relaxed, and then destrained.
%by P.E. Hamlington, November 14, 2007.

clc;
clear all;

load ske.txt %experimental straining from Chen et al.
load b11.txt %experimental anisotropy 
load b11_old.txt
load b11_rdt.txt
load chen_15.txt
load pe.txt
load uu.txt
load uuerr.txt
load vv.txt
load vverr.txt

global k0e0 a1 a2 a3 a4 S0 Lt t1 t2 t3 t4 t5 t6 cmu c ce1 ce2

k0e0=0.0092/0.0035; %initial value of k/e

%Model parameters
cmu=0.05; %eddy viscosity coefficient
ce1=1.44; %dissipation equation production coefficient
ce2=1.92; %dissipation equation disspation coefficient

c=0.26; %NKE memory time scale coefficient

%ODE Solution parameters
dt=0.0001; %time step

%Plot location and dimension parameters------------------------------------
%Figure dimensions and location on screen in inches
fx=8;
fy=5.5;
fw=5;
fh=4;

%Plot dimensions
x=0.14;
y=0.13;
w=0.8;
h=0.81;

%Font sizes
pfont=12; %tick mark font size
legfont=12; %legend font size
xfont=13; %x label font size
yfont=13; %y label font size
yfontf=17;
tfont=12;

lwid=2; %line width
msize=7;

yx=8;
%--------------------------------------------------------------------------

%88888888888888888888888888888888888888888888888888888888888888888888888888
%Set up straining
a1=9*k0e0^2;
a2=10*k0e0^2;
a3=18*k0e0^2;
a4=8*k0e0^2;
S0=0;
Lt=0.1/k0e0;
t1=0.25;
t3=0.55;
t2=(a1*t1+a2*t3)/(a1+a2);
t4=0.70;
t6=0.95;
t5=(a3*t4+a4*t6)/(a3+a4);

ti=[0:dt:t1];
tii=[t1+dt:dt:t2];
tiii=[t2+dt:dt:t3];
tiv=[t3+dt:dt:t4];
tv=[t4+dt:dt:t5];
tvi=[t5+dt:dt:t6];

S1=ti-ti;
S2=a1*(tii-t1);
S3=-a2*(tiii-t3);
S4=tiv-tiv;
S5=-a3*(tv-t4);
S6=a4*(tvi-t6);

Savg=mean(abs(ske(:,2)))

ifig=1;
figure(ifig)
set(gcf,'Units','inches','Position',[fx fy+(fh+1)*(1-ifig) fw fh],'Color','w')
clf;

xlow=0;
xhigh=1;
ylow=-10;
yhigh=10;

subplot('Position',[x,y,w,h]);plot(ske(:,1),ske(:,2),'ok','MarkerSize',7)
hold on;
subplot('Position',[x,y,w,h]);plot(ti,S1,'-k','LineWidth',lwid)
subplot('Position',[x,y,w,h]);plot(tii,S2,'-k','LineWidth',lwid)
subplot('Position',[x,y,w,h]);plot(tiii,S3,'-k','LineWidth',lwid)
subplot('Position',[x,y,w,h]);plot(tiv,S4,'-k','LineWidth',lwid)
subplot('Position',[x,y,w,h]);plot(tv,S5,'-k','LineWidth',lwid)
subplot('Position',[x,y,w,h]);plot(tvi,S6,'-k','LineWidth',lwid)
hold off;
annotation('doublearrow',[0.35,0.57],[0.5,0.5],'LineWidth',1,'Color','k')
annotation('doublearrow',[0.57,0.688],[0.48,0.48],'LineWidth',1,'Color','k')
annotation('doublearrow',[0.688,0.88],[0.58,0.58],'LineWidth',1,'Color','k')
text(0.32,-1.6,'Straining','FontSize',tfont,'Interpreter','Latex')
text(0.57,-2,'Relax.','FontSize',tfont,'Interpreter','Latex')
text(0.72,2.0,'Destraining','FontSize',tfont,'Interpreter','Latex')
set(gca,'FontSize',pfont,'FontName','Times')
ylabel('$\frac{\overline{S}_{11}k_0}{\epsilon_0}$','Interpreter','latex','Rotation',0,...
    'FontSize',yfontf,'Position',[xlow-(xhigh-xlow)/10,(ylow+yhigh)/2])
xlabel('$t\epsilon_0/k_0$','Interpreter','latex','FontSize',xfont,...
    'Position',[(xlow+xhigh)/2,-11.3])
axis([xlow,xhigh,ylow,yhigh])

%This is the ghetto legend generator---------------------------------------
%The legend is defined as an array with coordinates i x j
%Line styles and labels must be changed manually.
%All dimensions are in axis coordinates.

xs=0.03; %LEFT edge of legend
ys=-7.5; %TOP edge of legend
len=(xhigh-xlow)/8; %line length
xlsp=(xhigh-xlow)/40; %horizontal space between line and label
ysp=(yhigh-ylow)/14; %vertical space between legend entries
xsp=(xhigh-xlow)/4; %horizontal space between legend entries

i=1; %x location
j=1; %y location
xmark=(xs+(i-1)*xsp+len-(xs+(i-1)*xsp))/2;
line([xs+(i-1)*xsp+xmark,xs+(i-1)*xsp+xmark],[(ys-(j-1)*ysp),(ys-(j-1)*ysp)],...
    'Marker','o','Color','k','MarkerSize',7)
text(xs+(i-1)*xsp+len+xlsp,(ys-(j-1)*ysp),'Experiment','Interpreter',...
    'latex','FontSize',legfont)

i=1; %x location
j=2; %y location
line([xs+(i-1)*xsp,xs+(i-1)*xsp+len],[(ys-(j-1)*ysp),(ys-(j-1)*ysp)],...
    'LineStyle','-','Color','k','LineWidth',lwid)
text(xs+(i-1)*xsp+len+xlsp,(ys-(j-1)*ysp),'Approximation','Interpreter',...
    'latex','FontSize',legfont)
%--------------------------------------------------------------------------
%88888888888888888888888888888888888888888888888888888888888888888888888888


%88888888888888888888888888888888888888888888888888888888888888888888888888
%Solve SKE ODEs
[T1ske,Y1ske] = ode45(@ske_1,[0:dt:t1],[1,1]);
lk=length(Y1ske(:,1));
le=length(Y1ske(:,2));
[T2ske,Y2ske] = ode45(@ske_2,[t1+dt:dt:t2],[Y1ske(lk,1),Y1ske(le,2)]);
lk=length(Y2ske(:,1));
le=length(Y2ske(:,2));
[T3ske,Y3ske] = ode45(@ske_3,[t2+dt:dt:t3],[Y2ske(lk,1),Y2ske(le,2)]);
lk=length(Y3ske(:,1));
le=length(Y3ske(:,2));
[T4ske,Y4ske] = ode45(@ske_4,[t3+dt:dt:t4],[Y3ske(lk,1),Y3ske(le,2)]);
lk=length(Y4ske(:,1));
le=length(Y4ske(:,2));
[T5ske,Y5ske] = ode45(@ske_5,[t4+dt:dt:t5],[Y4ske(lk,1),Y4ske(le,2)]);
lk=length(Y5ske(:,1));
le=length(Y5ske(:,2));
[T6ske,Y6ske] = ode45(@ske_6,[t5+dt:dt:t6],[Y5ske(lk,1),Y5ske(le,2)]);

%Solve NKE ODEs
[T1nke,Y1nke] = ode113(@nke_1,[0:dt:t1],[1,1]);
lk=length(Y1nke(:,1));
le=length(Y1nke(:,2));
[T2nke,Y2nke] = ode113(@nke_2,[t1+dt:dt:t2],[Y1nke(lk,1),Y1nke(le,2)]);
lk=length(Y2nke(:,1));
le=length(Y2nke(:,2));
[T3nke,Y3nke] = ode113(@nke_3,[t2+dt:dt:t3],[Y2nke(lk,1),Y2nke(le,2)]);
lk=length(Y3nke(:,1));
le=length(Y3nke(:,2));
[T4nke,Y4nke] = ode113(@nke_4,[t3+dt:dt:t4],[Y3nke(lk,1),Y3nke(le,2)]);
lk=length(Y4nke(:,1));
le=length(Y4nke(:,2));
[T5nke,Y5nke] = ode113(@nke_5,[t4+dt:dt:t5],[Y4nke(lk,1),Y4nke(le,2)]);
lk=length(Y5nke(:,1));
le=length(Y5nke(:,2));
[T6nke,Y6nke] = ode113(@nke_6,[t5+dt:dt:t6],[Y5nke(lk,1),Y5nke(le,2)]);

%Solve LRR ODEs
[T1lrr,Y1lrr] = ode45(@lrr_1,[0:dt:t1],[0,0,0,0,0,0,1,1]);
lk=length(Y1lrr(:,7));
[T2lrr,Y2lrr] = ode45(@lrr_2,[t1+dt:dt:t2],Y1lrr(lk,:));
lk=length(Y2lrr(:,7));
[T3lrr,Y3lrr] = ode45(@lrr_3,[t2+dt:dt:t3],Y2lrr(lk,:));
lk=length(Y3lrr(:,7));
[T4lrr,Y4lrr] = ode45(@lrr_4,[t3+dt:dt:t4],Y3lrr(lk,:));
lk=length(Y4lrr(:,7));
[T5lrr,Y5lrr] = ode45(@lrr_5,[t4+dt:dt:t5],Y4lrr(lk,:));
lk=length(Y5lrr(:,7));
[T6lrr,Y6lrr] = ode45(@lrr_6,[t5+dt:dt:t6],Y5lrr(lk,:));
%88888888888888888888888888888888888888888888888888888888888888888888888888


%88888888888888888888888888888888888888888888888888888888888888888888888888
%Find SKE anisotropy time series
ke=Y1ske(:,1)./Y1ske(:,2);
S11=ke-ke; %strain
a1ske=-2*cmu*ke.*S11; %anisotropy 
P1ske=-ke.*(2*a1ske.*S11);

ke=Y2ske(:,1)./Y2ske(:,2);
S11=a1*(T2ske-t1); %strain
a2ske=-2*cmu*ke.*S11; %anisotropy 
P2ske=-ke.*(2*a2ske.*S11);

ke=Y3ske(:,1)./Y3ske(:,2);
S11=-a2*(T3ske-t3); %strain
a3ske=-2*cmu*ke.*S11; %anisotropy 
P3ske=-ke.*(2*a3ske.*S11);

ke=Y4ske(:,1)./Y4ske(:,2);
S11=ke-ke; %strain
a4ske=-2*cmu*ke.*S11; %anisotropy 
P4ske=-ke.*(2*a4ske.*S11);

ke=Y5ske(:,1)./Y5ske(:,2);
S11=-a3*(T5ske-t4); %strain
a5ske=-2*cmu*ke.*S11; %anisotropy 
P5ske=-ke.*(2*a5ske.*S11);

ke=Y6ske(:,1)./Y6ske(:,2);
S11=a4*(T6ske-t6); %strain
a6ske=-2*cmu*ke.*S11; %anisotropy 
P6ske=-ke.*(2*a6ske.*S11);
%88888888888888888888888888888888888888888888888888888888888888888888888888


%88888888888888888888888888888888888888888888888888888888888888888888888888
%Find NKE anisotropy time series
ke=Y1nke(:,1)./Y1nke(:,2);
lam=c*ke; %memory time scale
S11=ke-ke; %strain
S11e=ke-ke; %effective strain
a1nke=-2*cmu*ke.*S11e; %anisotropy 
P1nke=-Y1nke(:,1).*(2*a1nke.*S11);

ke=Y2nke(:,1)./Y2nke(:,2);
lam=c*ke; %memory time scale
S11=a1*(T2nke-t1); %strain
S11e=a1*((T2nke-t1)-lam.*(1-exp(-(T2nke-t1)./lam))); %effective strain
a2nke=-2*cmu*ke.*S11e; %anisotropy 
P2nke=-Y2nke(:,1).*(2*a2nke.*S11);

ke=Y3nke(:,1)./Y3nke(:,2);
lam=c*ke; %memory time scale
S11=-a2*(T3nke-t3); %strain
S11e=a1*(lam.*exp(-(T3nke-t1)./lam)-(lam+t1-t2).*exp(-(T3nke-t2)./lam))...
    +a2*(lam-(T3nke-t3)-(lam-t2+t3).*exp(-(T3nke-t2)./lam));  %effective strain
a3nke=-2*cmu*ke.*S11e; %anisotropy 
P3nke=-Y3nke(:,1).*(2*a3nke.*S11);

ke=Y4nke(:,1)./Y4nke(:,2);
lam=c*ke; %memory time scale
S11=ke-ke; %strain
S11e=a1*(lam.*exp(-(T4nke-t1)./lam)-(lam+t1-t2).*exp(-(T4nke-t2)./lam))...
    +a2*(lam.*exp(-(T4nke-t3)./lam)-(lam-t2+t3).*exp(-(T4nke-t2)./lam));  %effective strain
a4nke=-2*cmu*ke.*S11e; %anisotropy 
P4nke=-Y4nke(:,1).*(2*a4nke.*S11);

ke=Y5nke(:,1)./Y5nke(:,2);
lam=c*ke; %memory time scale
S11=-a3*(T5nke-t4); %strain
S11e=a1*(lam.*exp(-(T5nke-t1)./lam)-(lam+t1-t2).*exp(-(T5nke-t2)./lam))...
    +a2*(lam.*exp(-(T5nke-t3)./lam)-(lam-t2+t3).*exp(-(T5nke-t2)./lam))...
    +a3*(lam-(T5nke-t4)-lam.*exp(-(T5nke-t4)./lam));   %effective strain
a5nke=-2*cmu*ke.*S11e; %anisotropy 
P5nke=-Y5nke(:,1).*(2*a5nke.*S11);

ke=Y6nke(:,1)./Y6nke(:,2);
lam=c*ke; %memory time scale
S11=a4*(T6nke-t6); %strain
S11e=a1*(lam.*exp(-(T6nke-t1)./lam)-(lam+t1-t2).*exp(-(T6nke-t2)./lam))...
    +a2*(lam.*exp(-(T6nke-t3)./lam)-(lam-t2+t3).*exp(-(T6nke-t2)./lam))...
    -a3*(lam.*exp(-(T6nke-t4)./lam)-(lam+t4-t5).*exp(-(T6nke-t5)./lam))...
    +a4*(-lam+(T6nke-t6)+(lam-t5+t6).*exp(-(T6nke-t5)./lam));  %effective strain
a6nke=-2*cmu*ke.*S11e; %anisotropy 
P6nke=-Y6nke(:,1).*(2*a6nke.*S11);
%88888888888888888888888888888888888888888888888888888888888888888888888888

%88888888888888888888888888888888888888888888888888888888888888888888888888
a1lrr=Y1lrr(:,1); %anisotropy
a2lrr=Y2lrr(:,1); %anisotropy
a3lrr=Y3lrr(:,1); %anisotropy
a4lrr=Y4lrr(:,1); %anisotropy
a5lrr=Y5lrr(:,1); %anisotropy
a6lrr=Y6lrr(:,1); %anisotropy

%Concatenate
Canke=cat(1,a1nke,a2nke,a3nke,a4nke,a5nke,a6nke);
CPnke=cat(1,P1nke,P2nke,P3nke,P4nke,P5nke,P6nke);
CTnke=cat(1,T1nke,T2nke,T3nke,T4nke,T5nke,T6nke);

Tnke=[0:0.001:t6];
anke=spline(CTnke,Canke,Tnke);
Pnke=spline(CTnke,CPnke,Tnke);

Trdt=[0.05:0.001:0.95];
brdt=spline(b11_rdt(:,1),b11_rdt(:,2),Trdt);

sc=2/3;
sc2=1;

yoff=0.030;
yoff2=-0.1;
yoff3=0.05;

%%
ifig=2;
figure(ifig)
set(gcf,'Units','inches','Position',[fx fy+(fh+1)*(1-ifig) fw fh],'Color','w')
clf;

%Plot dimensions
x=0.128;
y=0.12;
w=0.86;
h=0.86;

xlow=0;
xhigh=1;
ylow=-1.1;
yhigh=1.1;

subplot('Position',[x,y,w,h]);plot(T1ske,sc2*a1ske,'-.r','LineWidth',lwid)
hold on;
%subplot('Position',[x,y,w,h]);plot(Trdt,2*sc*brdt,'--m','LineWidth',1)
subplot('Position',[x,y,w,h]);plot(b11(:,1),2*sc*b11(:,2),'ok','MarkerSize',7)
%subplot('Position',[x,y,w,h]);plot(b11_old(:,1),2*sc*b11_old(:,2),'or','MarkerSize',7)
subplot('Position',[x,y,w,h]);plot(T2ske,sc2*a2ske,'-.r','LineWidth',lwid)
subplot('Position',[x,y,w,h]);plot(T3ske,sc2*a3ske,'-.r','LineWidth',lwid)
subplot('Position',[x,y,w,h]);plot(T4ske,sc2*a4ske,'-.r','LineWidth',lwid)
subplot('Position',[x,y,w,h]);plot(T5ske,sc2*a5ske,'-.r','LineWidth',lwid)
subplot('Position',[x,y,w,h]);plot(T6ske,sc2*a6ske,'-.r','LineWidth',lwid)
subplot('Position',[x,y,w,h]);plot(T1lrr,sc2*a1lrr,'--m','LineWidth',lwid)
subplot('Position',[x,y,w,h]);plot(T2lrr,sc2*a2lrr,'--m','LineWidth',lwid)
subplot('Position',[x,y,w,h]);plot(T3lrr,sc2*a3lrr,'--m','LineWidth',lwid)
subplot('Position',[x,y,w,h]);plot(T4lrr,sc2*a4lrr,'--m','LineWidth',lwid)
subplot('Position',[x,y,w,h]);plot(T5lrr,sc2*a5lrr,'--m','LineWidth',lwid)
subplot('Position',[x,y,w,h]);plot(T6lrr,sc2*a6lrr,'--m','LineWidth',lwid)
subplot('Position',[x,y,w,h]);plot(Tnke,sc2*anke,'-b','LineWidth',lwid)
hold off;
annotation('doublearrow',[0.35,0.57],[0.60,0.60],'LineWidth',1,'Color','k')
annotation('doublearrow',[0.57,0.688],[0.37-yoff,0.37-yoff],'LineWidth',1,'Color','k')
annotation('doublearrow',[0.688,0.88],[0.27-yoff,0.27-yoff],'LineWidth',1,'Color','k')
text(0.28,0.21*sc2+yoff3,'Straining','FontSize',tfont+2,'Interpreter','Latex')
text(0.52,-0.82*sc2-yoff2+0.07,'Relax.','FontSize',tfont+2,'Interpreter','Latex')
text(0.64,-1.02*sc2-yoff2,'Destraining','FontSize',tfont+2,'Interpreter','Latex')
set(gca,'FontSize',pfont+2,'FontName','Times','TickLength',[0.02,0.02])
set(gca,'YTick',[-1,-0.5,0,0.5,1])
ylabel('Anisotropy','Interpreter','latex','Rotation',90,'FontSize',yfont+2)
xlabel('Time','Interpreter','latex','FontSize',xfont+2)
axis([xlow,xhigh,sc2*ylow,sc2*yhigh])

%This is the ghetto legend generator---------------------------------------
%The legend is defined as an array with coordinates i x j
%Line styles and labels must be changed manually.
%All dimensions are in axis coordinates.

xs=0.04; %LEFT edge of legend
ys=1.0*sc2-0.07; %TOP edge of legend
len=(xhigh-xlow)/8; %line length
xlsp=(xhigh-xlow)/40; %horizontal space between line and label
ysp=(yhigh-ylow)/14; %vertical space between legend entries
xsp=(xhigh-xlow)/3.6; %horizontal space between legend entries

i=1; %x location
j=1; %y location
line([xs+(i-1)*xsp,xs+(i-1)*xsp+len],[(ys-(j-1)*ysp),(ys-(j-1)*ysp)],...
    'LineStyle','-.','Color','r','LineWidth',lwid)
text(xs+(i-1)*xsp+len+xlsp,(ys-(j-1)*ysp),'Equilibrium','Interpreter',...
    'latex','FontSize',legfont+2)

i=1; %x location
j=2; %y location
line([xs+(i-1)*xsp,xs+(i-1)*xsp+len],[(ys-(j-1)*ysp),(ys-(j-1)*ysp)],...
    'LineStyle','-','Color','b','LineWidth',lwid)
text(xs+(i-1)*xsp+len+xlsp,(ys-(j-1)*ysp),'Nonequilibrium','Interpreter',...
    'latex','FontSize',legfont+2)

i=1; %x location
j=3; %y location
xmark=(xs+(i-1)*xsp+len-(xs+(i-1)*xsp))/2;
line([xs+(i-1)*xsp+xmark,xs+(i-1)*xsp+xmark],[(ys-(j-1)*ysp),(ys-(j-1)*ysp)],...
    'Marker','o','Color','k','MarkerSize',7)
text(xs+(i-1)*xsp+len+xlsp,(ys-(j-1)*ysp),'Chen \textit{et al} (2006)','Interpreter',...
    'latex','FontSize',legfont+2)
%--------------------------------------------------------------------------