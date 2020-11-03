% PlotRawPointingData.m
% Created 9/5/13 by A. Bosen
%
% This function fits the average auditory localization pointing error to a 
% nonlinear parametric model shape predicted from the Bayesian Inference Model

%Define plot color schemes
visualColor = [152/255 202/255 67/255]; %pale green 
auditoryColor = [31/255 60/255 115/255]; %dark blue
integrationColor = [228/255 62/255 37/255]; %medium red

%Load an array of target locations
subjectID = 'FAK';
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
AudFit = LinearUnimodalFit(audTargetLocations(AuditoryIndex),pointingLocations(AuditoryIndex));
VisFit = LinearUnimodalFit(visTargetLocations(VisualIndex),pointingLocations(VisualIndex));

perceivedVis = sign(visTargetLocations(BimodalIndex)) .* predict(VisFit,visTargetLocations(BimodalIndex));
perceivedAud = sign(visTargetLocations(BimodalIndex)) .* predict(AudFit,audTargetLocations(BimodalIndex));

deltaAV =  sign(visTargetLocations(BimodalIndex)) .*(audTargetLocations(BimodalIndex) - visTargetLocations(BimodalIndex));
correctedDeltaAV = perceivedAud - perceivedVis;
pointingError = sign(visTargetLocations(BimodalIndex)) .* (pointingLocations(BimodalIndex) - audTargetLocations(BimodalIndex)); 
correctedError = sign(visTargetLocations(BimodalIndex)) .* (pointingLocations(BimodalIndex) - predict(AudFit, audTargetLocations(BimodalIndex))); 
maxError = 28; 
if(max(max(abs(correctedError))) > maxError)
	disp(['WARNING: corrected pointing error is greater than plot maximum']);
end
maxDisparity = 46;
if(max(abs(correctedDeltaAV)) > maxDisparity)
	disp(['WARNING: corrected audio-visual disparity is greater than plot maximum']);
end
splineTolerance = 0.005;
errorSpline = csaps(deltaAV,pointingError,splineTolerance);
errorSplinePoints = fnplt(errorSpline);
correctedErrorSpline = csaps(correctedDeltaAV,correctedError,splineTolerance);
correctedSplinePoints = fnplt(correctedErrorSpline);

%Plot unimodal localization data
maxEccentricity = 42.5;
SDA =std(AudFit.Residuals.Raw);
SDV =std(VisFit.Residuals.Raw);
disp(['Localization Parameters:']);
disp(['   Auditory S.G.  : ' num2str(AudFit.Coefficients.Estimate(2))]);
disp(['   Auditory Offset: ' num2str(AudFit.Coefficients.Estimate(1))]);
disp(['   Auditory S.D.  : ' num2str(SDA)]);
disp(['   Visual S.G.  : ' num2str(VisFit.Coefficients.Estimate(2))]);
disp(['   Visual Offset: ' num2str(VisFit.Coefficients.Estimate(1))]);
disp(['   Visual S.D.  : ' num2str(SDV)]);

pointingPlotLimits = 48;
figure(1);
hold off;
%zero error reference line
plot([-1*pointingPlotLimits pointingPlotLimits], [-1*pointingPlotLimits pointingPlotLimits], '-','LineWidth',1,'Color',[0 0 0]);
hold on;
%Linear Fit Lines
plot([-1*pointingPlotLimits pointingPlotLimits], [-1*pointingPlotLimits * (VisFit.Coefficients.Estimate(2)) + VisFit.Coefficients.Estimate(1),...
						pointingPlotLimits * (VisFit.Coefficients.Estimate(2)) + VisFit.Coefficients.Estimate(1)],...
						'-','LineWidth',2,'color',visualColor);
%Raw Data
plot(visTargetLocations(VisualIndex),pointingLocations(VisualIndex),...
	'o','MarkerSize',7,'MarkerEdgeColor','black','MarkerFaceColor',visualColor);
set(gca,'YTick',-50:10:50);
set(gca,'XTick',-50:10:50);
set(gca,'FontSize',16);%set(gca,'YTick',[0.00 0.25 0.50 0.75 1.00]) 
axis([-1 * pointingPlotLimits pointingPlotLimits -1 * pointingPlotLimits pointingPlotLimits],'square');
ylabel('Pointer Azimuth (Deg)');
xlabel('Target Azimuth (Deg)');
set(gca,'YTick',-50:10:50);
set(gca,'XTick',-50:10:50);
set(gcf, 'PaperUnits','inches');
set(gcf, 'PaperSize',[6 6]);
set(gcf, 'PaperPosition',[0 0 6 6]);
set(gcf, 'PaperOrientation','portrait');
%print('-dpng',['Presentation Figures\' subjectID ' ' sessionString ' Unimodal Visual Pointing.png']);


figure(2);
hold off;
%zero error reference line
plot([-1*maxEccentricity maxEccentricity], [0 0], '-','LineWidth',2,'Color',[0 0 0]);
hold on;
%Linear Fit Lines
plot([-1*maxEccentricity maxEccentricity], [-1*maxEccentricity * (VisFit.Coefficients.Estimate(2) - 1) + VisFit.Coefficients.Estimate(1),...
						maxEccentricity * (VisFit.Coefficients.Estimate(2) - 1) + VisFit.Coefficients.Estimate(1)],...
						'-','LineWidth',4,'color',visualColor);
%Raw Data
plot(visTargetLocations(VisualIndex),pointingLocations(VisualIndex) - visTargetLocations(VisualIndex),...
	'o','MarkerSize',14,'MarkerEdgeColor','black','MarkerFaceColor',visualColor);
set(gca,'YTick',-35:5:35);
set(gca,'XTick',-50:10:50);
set(gca,'FontSize',32);%set(gca,'YTick',[0.00 0.25 0.50 0.75 1.00]) 
axis([-1 * maxEccentricity maxEccentricity -1 * maxError maxError]);
ylabel('Pointing Error (Deg)');
xlabel('Target Azimuth (Deg)');
set(gca,'YTick',-35:5:35);
set(gca,'XTick',-50:10:50);
set(gcf, 'PaperUnits','inches');
set(gcf, 'PaperSize',[6.5 14]);
set(gcf, 'PaperPosition',[0 0 16 6.5]);
set(gcf, 'PaperOrientation','portrait');
%print('-dpng',['Presentation Figures\' subjectID ' ' sessionString ' Unimodal Visual Error.png']);


figure(3);
hold off;
plot([-1*maxEccentricity maxEccentricity], [0 0], '-','LineWidth',2,'Color',[0 0 0]);
hold on;
%Linear Fit Lines
plot([-1*maxEccentricity maxEccentricity], [-1*maxEccentricity * (AudFit.Coefficients.Estimate(2) - 1) + AudFit.Coefficients.Estimate(1),...
						maxEccentricity * (AudFit.Coefficients.Estimate(2) - 1) + AudFit.Coefficients.Estimate(1)],...
						'-','LineWidth',4,'color',auditoryColor);
%Raw Data
plot(audTargetLocations(AuditoryIndex),pointingLocations(AuditoryIndex) - audTargetLocations(AuditoryIndex),...
	'o','MarkerSize',14,'MarkerEdgeColor','black','MarkerFaceColor',auditoryColor);
box on;
set(gca,'FontSize',32);%set(gca,'YTick',[0.00 0.25 0.50 0.75 1.00]) 
axis([-1 * maxEccentricity maxEccentricity -1 * maxError maxError]);
ylabel('Pointing Error (Deg)');
xlabel('Target Azimuth (Deg)');
set(gca,'YTick',-35:5:35);
set(gca,'XTick',-50:10:50);
set(gcf, 'PaperUnits','inches');
set(gcf, 'PaperSize',[6.5 14]);
set(gcf, 'PaperPosition',[0 0 16 6.5]);
set(gcf, 'PaperOrientation','portrait');
%print('-dpng',['Presentation Figures\' subjectID ' ' sessionString ' Unimodal Auditory Error.png']);

figure(4);
hold off;
%Plot a flat dashed line at zero as a reference auditory-only localization
plot([-1*maxDisparity maxDisparity], [0 0],'-','LineWidth',2,'color',auditoryColor);
hold on;
%Plot a dashed line with slope equal to the relative reliability of vision relative to audition as a reference for capture
plot([-1*maxDisparity maxDisparity], [maxDisparity -1*maxDisparity]*(SDA^2/(SDA^2+SDV^2)),'-','LineWidth',2,'color',integrationColor);
%Plot a spline with confidence interval for the raw data
plot(errorSplinePoints(1,:),errorSplinePoints(2,:),'-','color',[0.2 0.2 0.2],'Linewidth',2);
%plot the raw pointing data
scatter(deltaAV, pointingError,20,'Black','fill');
set(gca,'FontSize',16);%set(gca,'YTick',[0.00 0.25 0.50 0.75 1.00]) 
title(['Subject ' subjectID ' ' sessionString ' Pointing Error']);
axis([-1*maxDisparity maxDisparity -1*maxError maxError]);
ylabel('Error (Deg)','fontsize',28);
xlabel('Audiovisual Disparity (Deg)','fontsize',28);
set(gca,'YTick',-35:5:35);
set(gca,'XTick',-50:10:50);
set(gcf, 'PaperUnits','inches')
set(gcf, 'PaperSize',[6 11])
set(gcf, 'PaperPosition',[0 0 11 6])
set(gcf, 'PaperOrientation','portrait')
%print('-dpng',['Presentation Figures\' subjectID ' ' sessionString ' pointing Error DeltaAV with Spline.png']);


figure(5);
hold off;
%Plot a flat dashed line at zero as a reference auditory-only localization
plot([-1*maxDisparity maxDisparity], [0 0],'-','LineWidth',2,'color',auditoryColor);
hold on;
%Plot a visual only line
plot([-1*maxDisparity maxDisparity], [maxDisparity -1*maxDisparity],'-','LineWidth',2,'color',visualColor);
%Plot a dashed line with slope equal to the relative reliability of vision relative to audition as a reference for capture
plot([-1*maxDisparity maxDisparity], [maxDisparity -1*maxDisparity]*(SDA^2/(SDA^2+SDV^2)),'--','LineWidth',2,'color',integrationColor);
%Plot a spline with confidence interval for the raw data
plot(correctedSplinePoints(1,:),correctedSplinePoints(2,:),'-','color',[0.1 0.1 0.1],'LineWidth',2);
%plot the raw pointing data
scatter(correctedDeltaAV, correctedError,30,'Black','fill');
set(gca,'FontSize',20);%set(gca,'YTick',[0.00 0.25 0.50 0.75 1.00]) 
%title(['Subject ' subjectID ' ' sessionString ' Pointing Error']);
axis([-1*maxDisparity maxDisparity -1*maxError maxError]);
ylabel('Perceived Error (Deg)','fontsize',24);
xlabel('Perceived Audiovisual Disparity (Deg)','fontsize',24);
set(gca,'YTick',-35:5:35);
set(gca,'XTick',-40:10:40);
set(gcf, 'PaperUnits','inches')
set(gcf, 'PaperSize',[6 11])
set(gcf, 'PaperPosition',[0 0 11 6])
set(gcf, 'PaperOrientation','portrait')
print('-dpng',['Presentation Figures\' subjectID ' ' sessionString ' corrected Error DeltaAV with Spline.png']);


%Build color and size scales based on pointing errors
pointSize = 10 + ((300 - 20)/(2*maxError))*abs(pointingLocations(BimodalIndex) - predict(AudFit, audTargetLocations(BimodalIndex)));
pointColor= (127.5 + ((255 - 0)/(2*maxError))*(pointingLocations(BimodalIndex) - predict(AudFit, audTargetLocations(BimodalIndex))) * [1 1 1])/255;
%Color points black if the error is toward the visual, white otherwise
%pointColor = ((sign(audTargetLocations(BimodalIndex) - visTargetLocations(BimodalIndex)) .*...
%	     sign(pointingLocations(BimodalIndex) - predict(AudFit, audTargetLocations(BimodalIndex)))) + 1) * [1 1 1];


figure(6);
hold off;
scatter(audTargetLocations(BimodalIndex), visTargetLocations(BimodalIndex),pointSize,pointColor,'fill','markeredgecolor','black');
box on;
colormap('gray')
cbar = colorbar('Ticks',((-35:5:35) + maxError)/(2*maxError),'TickLabels',-35:5:35);
cbar.Label.String = 'Perceived Error (Deg)';
set(gca,'FontSize',20);%set(gca,'YTick',[0.00 0.25 0.50 0.75 1.00]) 
title([subjectID ' ' sessionString ' Raw Pointing Error']);
axis([-45 45 -45 45]); axis square;
ylabel('Visual Target Location (Deg)','fontsize',16);
xlabel('Auditory Target Location (Deg)','fontsize',16);
set(gca,'YTick',-50:10:50);
set(gca,'XTick',-50:10:50);
%c = colorbar;
%caxis([0 255]);
%set(c,'YTick',[42.5, 127.5, 212.5],'YTickLabel',{'-20', '0', '20'});
%ylabel(c,'Error (Deg)','fontsize',20);
set(gcf, 'PaperUnits','inches')
set(gcf, 'PaperSize',[8.5 11])
set(gcf, 'PaperPosition',[0 0 11 8.5])
set(gcf, 'PaperOrientation','portrait')
%print('-dpng',['Presentation Figures\' subjectID ' ' sessionString ' Raw Data.png']);

