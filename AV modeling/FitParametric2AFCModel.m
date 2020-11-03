% FitParametric2AFCModel.m
% Created 9/6/13 by A. Bosen
%
% This function fits the "same location/different location" responses to a 
% Gaussian Curve


%Load an array of target locations
subjectID = 'KT';
session = 'Binding_Session3';
sessionString = 'Binding Session 3';
[numData,textData] = xlsread(['Data\' subjectID ' Audloc_' session '.csv']);
%Parse relevant columns out of subject data.
audTargetLocations = numData(:,5);
visTargetLocations = numData(:,7);
pointingLocations = numData(:,9);
choiceResponses = 0 < numData(:,10);
stimType = textData(:,2);
%Chop off stimType header
stimType = stimType(2:length(stimType));

AuditoryIndex = strcmp(stimType,'A') == 1;
VisualIndex = strcmp(stimType,'V') == 1;
BimodalIndex = strcmp(stimType,'B') == 1;

%Estimate fixed model parameters from subject unimodal pointing data
AudFit = LinearModel.fit(audTargetLocations(AuditoryIndex),pointingLocations(AuditoryIndex));
VisFit = LinearModel.fit(visTargetLocations(VisualIndex),pointingLocations(VisualIndex));

perceivedVis = sign(visTargetLocations(BimodalIndex)) .* predict(VisFit,visTargetLocations(BimodalIndex));
perceivedAud = sign(visTargetLocations(BimodalIndex)) .* predict(AudFit,audTargetLocations(BimodalIndex));

beta = NonLinearModel.fit([perceivedVis perceivedAud],...
		choiceResponses(BimodalIndex),...  
		'y~b1*exp(-1*(x1-x2-b2)^2/(2*(b3)^2))',[1 0 10],'Options',statset('MaxIter',2000));


%Build a surface from the model fit to plot
figure(1);
hold off;
[sV, sA] = meshgrid(5:1:40,5:1:40);
[xV, xA] = meshgrid(predict(VisFit,(5:1:40)'),predict(AudFit,(5:1:40)'));
a = beta.Coefficients.Estimate(1);
b = beta.Coefficients.Estimate(2);
c = beta.Coefficients.Estimate(3);
d = 0;%beta.Coefficients.Estimate(4);
modelPointingError = exp(-1*(xV - xA - b).^2./(2*c+d.*abs(xA)).^2);
disp(['Fit Parameters:']);
disp(['   Maximum: ' num2str(beta.Coefficients.Estimate(1)) '     ' num2str(beta.Coefficients.pValue(1))]);
disp(['   Width  : ' num2str(beta.Coefficients.Estimate(3)) '     ' num2str(beta.Coefficients.pValue(3))]);
disp(['   Offset : ' num2str(beta.Coefficients.Estimate(2)) '     ' num2str(beta.Coefficients.pValue(2))]);

maxPointingError = max(max(abs([modelPointingError])));	

figure;
surf(5:1:40,5:1:40,modelPointingError);
hold on;
scatter3(sign(visTargetLocations(BimodalIndex)) .* visTargetLocations(BimodalIndex),...
	sign(visTargetLocations(BimodalIndex)) .* audTargetLocations(BimodalIndex),...
	choiceResponses(BimodalIndex),40);

pointSize = choiceResponses(BimodalIndex) * 30 + 40;
%want 1s 'same location' responses to be black, want 0s to be white
pointColor= (1-choiceResponses(BimodalIndex)) * [1 1 1];

figure(2);
hold off;
plot(-40:0.25:40,exp(-1*((-40:0.25:40) - b).^2./(2*(c).^2)),'Color',[0/255 148/255 68/255],'linewidth',3);
hold on;
scatter(sign(visTargetLocations(BimodalIndex)) .*(visTargetLocations(BimodalIndex) - audTargetLocations(BimodalIndex)),...
	choiceResponses(BimodalIndex),pointSize, pointColor,'fill','markeredgecolor','black');
set(gca,'FontSize',24);%set(gca,'YTick',[0.00 0.25 0.50 0.75 1.00]) 
title(['Subject ' subjectID ' ' sessionString ' Common Source Probability']);
ylabel('Probability of Common Source','fontsize',28);
xlabel('Audiovisual Disparity (Deg)','fontsize',28);
print('-dpng',['Figures\' subjectID ' ' sessionString ' DeltaAV.png']);

