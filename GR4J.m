% =======================================================================
% -----------------------------------------------------------------------
% -----------------------   JUAN CARLOS TICONA  -------------------------
% ----------- INSTITUTO DE PESQUISAS HIDRAULICAS (IPH) UFRGS  -----------
% ---------------------------- GR4J Model -------------------------------
% -------------------------- OUTUBRO DE 2023 ----------------------------   
% -----------------------------------------------------------------------
% =======================================================================

function [ Q, QO ] = GR4J( X )
% Modelo hidrol�gico conceitual: GR4J
%
% Copyright (C) 2023 Juan Carlos Ticona Gutierrez
% O modelo GR4J � principalmente emp�rico, foi amplamente testado 
% em bacias na Fran�a, mas tamb�m em outros pa�ses. O modelo tamb�m foi 
% comparado com outros modelos hidrol�gicos e forneceu resultados comparativamente 
% bons. Possui 5 par�metros detalhada em:
% LEMOINE, N. Le bassin versant de surface vu par le souterrain: une
% voie d�am�lioration des performances et du r�alisme desmod�les pluie-d�bit? Paris. 2008.

% Come�a a ler os dados de entrada
QO   = textread('vaz_goias_c.txt','%f')';        % vaz�o observado em m3/s
P    = textread('prec_goias_c.txt','%f');        % Precitac�o em mm/dia
E    = textread('evap_goias_c.txt','%f');        % Evapotranspira��o mm/dia
NT   = length(QO);

% Areas das bacias hidrograficas aplicadas
% Bacia Ijui
% Area = 5414; % km^2
% Area = 86.4/Area;  % convers�o vaz�o em unidades de m^3/s
% Bacia Canoas
% Area = 989; % km^2
% Area = 86.4/Area;  % convers�o vaz�o em unidades de m^3/s
% % Bacia Goias
Area = 1817; % km^2
Area = 86.4/Area;  % convers�o vaz�o em unidades de m^3/s

% %Iniciar vetores de armazenamento
S = zeros(1,NT);
R = zeros(1,NT);

Pn   = zeros(1,NT);
Ps   = zeros(1,NT);
Pr   = zeros(1,NT);
En   = zeros(1,NT);
Es   = zeros(1,NT);
qr   = zeros(1,NT);
qd   = zeros(1,NT);
Q    = zeros(1,NT);

q9   = zeros(1,NT);
q1   = zeros(1,NT);

% Iniciar tanques do modelo
load ('storeinitial_gr4j_goias.prn')    % comeca a ler os dados de entrada, armazenamento inicial dos reservatorios
% ------------------------------------------------------------------------
S(1) = storeinitial_gr4j_goias(1);      % Armazenamento inicial de umidade do solo
R(1) = storeinitial_gr4j_goias(2);      % Armazenamento inicial de routing

% Par�metros 
Smax      = X(1);     % Armazenamento m�ximo de umidade do solo [mm]
kf        = X(2);     % Coeficiente de troca de �gua [mm/d]
Rmax      = X(3);     % Armazenamento m�ximo de armazenamento de roteamento [mm]
T         = X(4);     % Delay de fluxo [d]
% S(1)      = X(5);     % Armazenamento inicial de umidade do solo
% R(1)      = X(6);     % Initial routing storage

% Preparar hidrogramas unitarios
UH1 = uh_1(T);
UH2 = uh_2(T);

n1  = length(UH1);  	% vetor tempor�rio necess�rio para lidar com o roteamento
n2  = length(UH2);      % vetor tempor�rio necess�rio para lidar com o roteamento

for t = 2:NT
    if(P(t) >= E(t)) 
	Pn(t) = P(t) - E(t);
	En(t) = 0;
	Ps(t) = Smax*(1-(S(t-1)/Smax)^2)*tanh(Pn(t)/Smax) / (1+S(t-1)/Smax+tanh(Pn(t)/Smax));
	Es(t) = 0;
    else
	En(t) = E(t) - P(t);
	Pn(t) = 0;
	Es(t) = S(t-1)*(2-S(t-1)/Smax)*tanh(En(t)/Smax) / (1+(1-S(t-1)/Smax)*tanh(En(t)/Smax));
	Ps(t) = 0;
    end

    S(t) = S(t) - Es(t) + Ps(t);
    Perc = S(t)*(1-(1+(4*S(t)/(9*Smax))^4)^(-1/4)); 
    S(t) = S(t) - Perc;
    Pr(t) = Perc + Pn(t) - Ps(t);
end

for t = 2:NT
    if t >= n2
        for i = 1:n1
            q9(t) = q9(t) + UH1(i)*Pr(t + 1 - i)*0.9;
        end
        for i = 1:n2
            q1(t) = q1(t) + UH2(i)*Pr(t + 1 - i)*0.1;
        end
    elseif ((t >= n1) && (t < n2))
        for i = 1:n1
            q9(t) = q9(t) + UH1(i)*Pr(t + 1 - i)*0.9;
        end
        for i = 1:t
            q1(t) = q1(t) + UH2(i)*Pr(t + 1 - i)*0.1;
        end
    elseif (t < n1)
        for i = 1:t
            q9(t) = q9(t) + UH1(i)*Pr(t + 1 - i)*0.9;
        end
        for i = 1:t
            q1(t) = q1(t) + UH2(i)*Pr(t + 1 - i)*0.1;
        end
    else
        
    end
    F = kf*(R(t-1)/Rmax)^(7/2);
    
    R(t) = max(0, q9(t) + F +R(t-1));
    qr(t) = R(t)*(1-(1+(R(t)/Rmax)^4)^(-1/4));
    
    R(t) = R(t) - qr(t); 
    qd(t) = max(0, q1(t) + F);
    
    Q(t) = qr(t) + qd(t);
end
Q = Q/Area;
end