%% 1-C

N = 50;

% correggere l'help di MixGauss:
% non ritorna vettori 2nxd ma pnxd

[X1, Y1] = MixGauss([[0;0],[1;1]],[0.5,0.25],N);
figure(1); 
scatter(X1(:,1),X1(:,2),50,Y1,'filled');
title('dataset 1');

%% 1-D

[X2, C] = MixGauss([[0;0],[0;1],[1;1],[1;0]],[0.3,0.3,0.3,0.3],N);
figure(2); 
scatter(X2(:,1),X2(:,2),50,C);
title('dataset 2')

% correggere il testo perch? prima lo chiama C e poi Ytr

Y2 = 2*mod(C,2) - 1;
figure(3); 
scatter(X2(:,1),X2(:,2),50,Y2);
title('dataset 3')

%% 1-E

[X2t, Ct] = MixGauss([[0;0],[0;1],[1;1],[1;0]],[0.3,0.3,0.3,0.3],N);
figure(4); 
scatter(X2t(:,1),X2t(:,2),50,Ct);
title('dataset 4')

Y2t = 2*mod(C,2) - 1;
figure(5); 
scatter(X2t(:,1),X2t(:,2),50,Y2t);
title('dataset 5')

%% 2-B

k = N/2;
Y2pred = kNNClassify(X2,Y2,k,X2t);

%% 2-C

figure(6);
scatter(X2t(:,1),X2t(:,2),50,Y2t,'filled');
hold on
scatter(X2t(:,1),X2t(:,2),50,Y2pred);

%% 2-D

N2t = length(X2t);
pred_err = sum(Y2pred ~=Y2t)./N2t % Nt number of test data

%% 2-E

separatingFkNN(X2, Y2, k)

%% 3-A-B

intK = [1 3 5 7 9 11 17 21 31 41 51 71];

perc = 0.5;
nrip = 10;

[k, Vm, Vs, Tm, Ts] = holdoutCVkNN(X2, Y2, perc, nrip, intK);

errorbar(intK, Vm, sqrt(Vs), 'b');
hold on
errorbar(intK, Tm, sqrt(Ts), 'r');

%% 3-C

% correggere l'help di holdoutCV perch? qui non abbiamo couples of params

intK = [1 3 5 7 9 11 15 21 25 31 41 51 71];

perc = [0.2 0.4 0.5 0.6 0.8];
nrip = [1 90];

K = zeros(length(perc), length(nrip));
VM = zeros(length(perc), length(nrip));
TM = zeros(length(perc), length(nrip));

for p=1:length(perc)
    for r=1:length(nrip)
        [K(p,r), Vm, Vs, Tm, Ts] = holdoutCVkNN(X2, Y2, perc(p), nrip(r), intK);
        [VM(p,r), idx] = min(Vm);
        TM(p,r) = Tm(idx);
    end
end

figure
subplot(2,2,1:2)
set(gca, 'ColorOrder', jet(length(perc)), 'NextPlot', 'replacechildren');
plot(perc, K')
xlabel('perc')
ylabel('k')
legend(num2str(nrip'))

subplot(2,2,3)
set(gca, 'ColorOrder', jet(length(perc)), 'NextPlot', 'replacechildren');
plot(perc, VM')
xlabel('perc')
ylabel('val err')
legend(num2str(nrip'))
ylim([0 0.15])

subplot(2,2,4)
set(gca, 'ColorOrder', jet(length(perc)), 'NextPlot', 'replacechildren');
plot(perc, TM')
xlabel('perc')
ylabel('train err')
legend(num2str(nrip'))
ylim([0 0.15])

%% 3-D

Y2pred = kNNClassify(X2,Y2,k,X2t);

N2t = length(X2t)
pred_err = sum(Y2pred ~=Y2t)./N2t % Nt number of test data