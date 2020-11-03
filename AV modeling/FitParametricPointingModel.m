% FitParametricPointingModel.m
% Created 9/5/13 by A. Bosen
%
% This function fits the average auditory localization pointing error to a 
% nonlinear parametric model shape predicted from the Bayesian Inference Model


%Load an array of target locations
subjectID = 'KT';
session = 'Visual_Capture_Session2';
sessionString = 'Visual Capture Session 2';
[numData,textData] = xlsread(['Data\' subjectID ' Audloc_' session '.csv']);
%Parse relevant columns out of subject data.
audTargetLocations = numData(:,5);
visTargetLocations = numData(:,7);
pointingLocations = numData(:,9);
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
		sign(visTargetLocations(BimodalIndex)) .* (pointingLocations(BimodalIndex) - ...
		predict(AudFit,audTargetLocations(BimodalIndex))),...  
		'y~(x1-x2-b2)*b1*exp(-1*(x1-x2-b2)^2/(2*(b3)^2))',[1 0 10],'Options',statset('MaxIter',2000));

%Build a surface from the model fit to plot
figure(2);
hold off;
[sV, sA] = meshgrid(5:1:40,5:1:40);
[xV, xA] = meshgrid(predict(VisFit,(5:1:40)'),predict(AudFit,(5:1:40)'));
a = beta.Coefficients.Estimate(1);
b = beta.Coefficients.Estimate(2);
c = beta.Coefficients.Estimate(3);
d = 0;%beta.Coefficients.Estimate(4);
modelPointingError = (xV - xA - b) .* a .*...
		exp(-1*(xV - xA - b).^2./(2*c+d.*abs(xA)).^2);
disp(['Fit Parameters:']);
disp(['   Maximum: ' num2str(beta.Coefficients.Estimate(1)) '     ' num2str(beta.Coefficients.pValue(1))]);
disp(['   Width  : ' num2str(beta.Coefficients.Estimate(3)) '     ' num2str(beta.Coefficients.pValue(3))]);
disp(['   Offset : ' num2str(beta.Coefficients.Estimate(2)) '     ' num2str(beta.Coefficients.pValue(2))]);

maxPointingError = 25;%max(max(abs([modelPointingError])));
if(max(max(abs([modelPointingError]))) > maxPointingError)
	disp(['WARNING: pointing error is greater than plot maximum.']);
end

surf(5:1:40,5:1:40,modelPointingError);
hold on;
scatter3(sign(visTargetLocations(BimodalIndex)) .* visTargetLocations(BimodalIndex),...
	sign(visTargetLocations(BimodalIndex)) .* audTargetLocations(BimodalIndex),...
	sign(visTargetLocations(BimodalIndex)) .* (pointingLocations(BimodalIndex) - ...
	predict(AudFit, audTargetLocations(BimodalIndex))),40);


%Build color and size scales based on pointing errors
pointSize = 10 + ((300 - 20)/(30 - -30))*abs(pointingLocations(BimodalIndex) - predict(AudFit, audTargetLocations(BimodalIndex)));
%pointColor= 127.5 + ((255 - 0)/(30 - -30))*(pointingLocations(BimodalIndex) - predict(AudFit, audTargetLocations(BimodalIndex)));
%Color points black if the error is toward the visual, white otherwise
pointColor = ((sign(visTargetLocations(BimodalIndex) - audTargetLocations(BimodalIndex)) .*...
	     sign(pointingLocations(BimodalIndex) - predict(AudFit, audTargetLocations(BimodalIndex)))) - 1) * [1 1 1];

figure(3);
hold off;
%Plot the Predicted average pointing error for OC session 1
apredict = 1;
bpredict = -1.9;
cpredict = 6.5;
%plot(-40:0.25:40,((-40:0.25:40) - bpredict) .* apredict .* exp(-1*((-40:0.25:40) - bpredict).^2./(2*(cpredict).^2)),'--','color',[0/255 148/255 68/255],'linewidth',3);
hold on;
%Plot the fit to the pointing data
plot(-40:0.25:40,((-40:0.25:40) - b) .* a .* exp(-1*((-40:0.25:40) - b).^2./(2*(c).^2)),'color',[33/255 64/255 154/255],'linewidth',3);
%plot the raw pointing data
scatter(sign(visTargetLocations(BimodalIndex)) .*(visTargetLocations(BimodalIndex) - audTargetLocations(BimodalIndex)),...
sign(visTargetLocations(BimodalIndex)) .*(pointingLocations(BimodalIndex) - predict(AudFit, audTargetLocations(BimodalIndex))),pointSize,pointColor,'s','fill','markeredgecolor','black');
set(gca,'FontSize',24);%set(gca,'YTick',[0.00 0.25 0.50 0.75 1.00]) 
title(['Subject ' subjectID ' ' sessionString ' Pointing Error']);
axis([-40 40 -20 20]);
ylabel('Pointing Error (Deg)','fontsize',28);
xlabel('Audiovisual Disparity (Deg)','fontsize',28);
print('-dpng',['Figures\' subjectID ' ' sessionString ' DeltaAV.png']);

