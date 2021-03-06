function Diffresult = DiffusionProcess_aq_gas(diffMatrixInd,waterFilm,waterVolume,gasVolume,sitesCin,sitesCgin,HenryDomainin,reactionCin,InvasedIsland,sitesNEquilin,sitesNGEquilin,AlphaMin,listE,Lp,dt,testMinT, reducedLevelC)

% diffMatrixInd = diffMatrix(:,:,1);
% 
% sitesCin = sitesC{1}(:,:)
% sitesCgin = sitesCg{1}(:,:);
% HenryDomainin = HenryDomain{1}(:,:);
% reactionCin = reactionC(:,:,1);
% sitesNEquilin = sitesNEquil{1}(:,:);
% sitesNGEquilin = sitesNGEquil{1}(:,:);
% sitesNGEquilin =AlphaM{1}(:,:);
% 

[m,n] = size(waterFilm);
nutShare = zeros(m,n);
totConsumed = zeros(m,n);
reactionN = zeros(m,n);
changeN = zeros(m,n);
nnEffWF = zeros(m*n,m*n);
nnEffDiff = zeros(m*n,m*n);

DiagWF = diag(waterFilm(:));
nnWF = listE*DiagWF;
for i = 1:(m*n)
    nnEffWF(:,i) = min(nnWF(:,i),waterFilm(i))/waterFilm(i);
end

DiagDiff = diag(diffMatrixInd(:));
nnDiff = listE*DiagDiff;
for i = 1:(m*n)
    nnEffDiff(:,i) = 2*nnDiff(:,i).*diffMatrixInd(i)./(nnDiff(:,i)+diffMatrixInd(i));
end
HeteroDiffM = nnEffWF.*nnEffDiff*testMinT/Lp/Lp; %nearest neighbor
HeteroDiffM = HeteroDiffM - diag(sum(HeteroDiffM)); %including self
Afuture = sparse((eye(m*n)-HeteroDiffM));
Apresent = (eye(m*n)+HeteroDiffM);
tT = testMinT;

reactionN(:,:) = reactionCin; % change in nutrient mass
sitesCtemp = sitesCin;
sitesCgtemp = sitesCgin;
tempC1 = sitesCtemp(:);

while (min(tempC1)>=0)&&(tT<=dt)
    totalN = sitesCtemp.*waterVolume + sitesCgtemp.*gasVolume;
    sitesCtempEq = sitesNEquilin.*InvasedIsland + (InvasedIsland==0).*HenryDomainin.*totalN./AlphaMin;
    sitesCgtempEq = sitesNGEquilin.*InvasedIsland + (InvasedIsland==0).*totalN./AlphaMin;
    intermediateN = sitesCtempEq.*waterVolume;
    tempLog = 1*(intermediateN + reactionN < 0);
    nutShareL = (tempLog==1).*intermediateN./abs(reactionN) + (tempLog==0).*ones(m,n);
    nutShareL(isnan(nutShareL)) = 1;
    nutShare = nutShare + nutShareL(:,:);
    totConsumed = totConsumed-((tempLog==1).*nutShareL.*reactionN + (tempLog==0).*reactionN)*testMinT;
    intermediateN = intermediateN + ((tempLog==1).*nutShareL.*reactionN + (tempLog==0).*reactionN)*testMinT;
    sitesCtemp = intermediateN./waterVolume;
    sitesCtemp(end,:) = sitesNEquilin(end,:)*reducedLevelC;
    sitesCtemp(InvasedIsland==reducedLevelC) = sitesCtemp(end,1);
    presentChange = Apresent*sitesCtemp(:);
    [tempC1, flag] = bicgstab(Afuture,presentChange,[],1);
    sitesCtemp = reshape(tempC1,m,n);
    sitesCgtemp = sitesCgtempEq;
    sitesCgtemp(isnan(sitesCgtempEq)) = 0;
    changeN = changeN + (sitesCtemp - sitesNEquilin).*waterVolume.*InvasedIsland;
    tT = tT+testMinT;
end
sitesCout = sitesCtemp;
sitesCgout = sitesCgtemp;
nutShare = nutShare*testMinT/dt;
Diffresult.sitesC = sitesCout;
Diffresult.sitesCg = sitesCgout;
Diffresult.nutShare = nutShare;
Diffresult.totConsumed = totConsumed;
Diffresult.changeN = changeN;






