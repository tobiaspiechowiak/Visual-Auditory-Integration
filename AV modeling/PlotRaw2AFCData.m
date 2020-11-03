% PlotRaw2AFCData.m
% Created 4/15/14 by A. Bosen
%
% This function fits the "same location/different location" responses to a 
% Gaussian Curve

%Define plot color schemes
visualColor = [152/255 202/255 67/255]; %pale green 
auditoryColor = [31/255 60/255 115/255]; %dark blue
integrationColor = [228/255 62/255 37/255]; %medium red

%Load an array of target locations
subjectID = 'FAK';
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
AudFit = LinearUnimodalFit(audTargetLocations(AuditoryIndex),pointingLocations(AuditoryIndex));
VisFit = LinearUnimodalFit(visTargetLocations(VisualIndex),pointingLocations(VisualIndex));

perceivedVis = sign(visTargetLocations(BimodalIndex)) .* predict(VisFit,visTargetLocations(BimodalIndex));
perceivedAud = sign(visTargetLocations(BimodalIndex)) .* predict(AudFit,audTargetLocations(BimodalIndex));

pointingError = pointingLocations(AuditoryIndex) - audTargetLocations(AuditoryIndex); 
maxError = 27;
if(max(max(abs(pointingError))) > maxError)
	disp(['WARNING: corrected pointing error is greater than plot maximum']);
end


%Plot unimodal localization data
maxEccentricity = 42.5;

disp(['Localization Parameters:']);
disp(['   Auditory S.G.  : ' num2str(AudFit.Coefficients.Estimate(2))]);
disp(['   Auditory Offset: ' num2str(AudFit.Coefficients.Estimate(1))]);
disp(['   Auditory S.D.  : ' num2str(std(AudFit.Residuals.Raw))]);
disp(['   Visual S.G.  : ' num2str(VisFit.Coefficients.Estimate(2))]);
disp(['   Visual Offset: ' num2str(VisFit.Coefficients.Estimate(1))]);
disp(['   Visual S.D.  : ' num2str(std(VisFit.Residuals.Raw))]);

deltaAV = sign(visTargetLocations(BimodalIndex)) .*(visTargetLocations(BimodalIndex) - audTargetLocations(BimodalIndex));
correctedDeltaAV = perceivedVis - perceivedAud;
maxDisparity = 46;
if(max(abs(correctedDeltaAV)) > maxDisparity)
	disp(['WARNING: corrected audio-visual disparity is greater than plot maximum']);
end

histogramBins = -37.5:5:37.5;
correctedHistogramBins = -1*maxDisparity:5:maxDisparity;
twoSourceCount = histc(deltaAV(~choiceResponses(BimodalIndex)),histogramBins);
oneSourceCount = histc(deltaAV(choiceResponses(BimodalIndex)),histogramBins);
totalCount = histc(deltaAV,histogramBins);
correctedTwoSourceCount = histc(correctedDeltaAV(~choiceResponses(BimodalIndex)),correctedHistogramBins);
correctedOneSourceCount = histc(correctedDeltaAV(choiceResponses(BimodalIndex)),correctedHistogramBins);
correctedTotalCount = histc(correctedDeltaAV,correctedHistogramBins);
[oneSourceProbability,oneSourceProbCI] = binofit(oneSourceCount,totalCount);
[correctedOneSourceProbability,correctedOneSourceProbCI] = binofit(correctedOneSourceCount,correctedTotalCount);
%Use the middle of each bin as the x axis point, which requires dropping a point from the y axis vectors
histogramIndex = (histogramBins(1:length(histogramBins)-1) + histogramBins(2:length(histogramBins))) / 2;
oneSourceCount = oneSourceCount(1:length(oneSourceCount)-1);
twoSourceCount = twoSourceCount(1:length(twoSourceCount)-1); 
oneSourceProbability = oneSourceProbability(1:length(oneSourceProbability)-1);
oneSourceProbCI = oneSourceProbCI(1:length(oneSourceProbCI)-1,:);
correctedHistogramIndex = (correctedHistogramBins(1:length(correctedHistogramBins)-1) + correctedHistogramBins(2:length(correctedHistogramBins))) / 2;
correctedOneSourceCount = correctedOneSourceCount(1:length(correctedOneSourceCount)-1);
correctedTwoSourceCount = correctedTwoSourceCount(1:length(correctedTwoSourceCount)-1); 
correctedOneSourceProbability = correctedOneSourceProbability(1:length(correctedOneSourceProbability)-1);
correctedOneSourceProbCI = correctedOneSourceProbCI(1:length(correctedOneSourceProbCI)-1,:);
%Remove bins that don't contain any data
correctedHistogramIndex = correctedHistogramIndex(~isnan(correctedOneSourceProbability));
correctedOneSourceProbCI = correctedOneSourceProbCI(~isnan(correctedOneSourceProbability),:);
correctedOneSourceProbability = correctedOneSourceProbability(~isnan(correctedOneSourceProbability));

%TODO: interpolate medial and lateral 50% points from corrected histogram
%Find the points bewteen which the probability estimate crosses 50%.

figure(1);
hold off;
%zero error reference line
plot([-1*maxEccentricity maxEccentricity], [0 0], ':','LineWidth',1,'Color',[0.5 0.5 0.5]);
hold on;
plot([0 0], [-1*maxError maxError], ':','LineWidth',1,'Color',[0.5 0.5 0.5]);
%Linear Fit Lines
plot([-1*maxEccentricity maxEccentricity], [-1*maxEccentricity * (AudFit.Coefficients.Estimate(2) - 1) + AudFit.Coefficients.Estimate(1),...
						maxEccentricity * (AudFit.Coefficients.Estimate(2) - 1) + AudFit.Coefficients.Estimate(1)],...
						'--','LineWidth',2,'Color',auditoryColor);
plot([-1*maxEccentricity maxEccentricity], [-1*maxEccentricity * (VisFit.Coefficients.Estimate(2) - 1) + VisFit.Coefficients.Estimate(1),...
						maxEccentricity * (VisFit.Coefficients.Estimate(2) - 1) + VisFit.Coefficients.Estimate(1)],...
						'r--','LineWidth',2,'Color',visualColor);
%Raw Data
plot(audTargetLocations(AuditoryIndex),pointingLocations(AuditoryIndex) - audTargetLocations(AuditoryIndex),...
	'o','MarkerSize',5,'MarkerEdgeColor','black','MarkerFaceColor',auditoryColor);
plot(visTargetLocations(VisualIndex),pointingLocations(VisualIndex) - visTargetLocations(VisualIndex),...
	'o','MarkerSize',5,'MarkerEdgeColor','black','MarkerFaceColor',visualColor);
box on;
set(gca,'FontSize',24);%set(gca,'YTick',[0.00 0.25 0.50 0.75 1.00]) 
title([subjectID ' ' sessionString ' Unimodal Pointing']);
axis([-1 * maxEccentricity maxEccentricity -1 * maxError maxError]);
ylabel('Error (Deg)');
xlabel('Target Location (Deg)');
set(gca,'YTick',-20:5:20);
set(gca,'XTick',-50:10:50);
set(gcf, 'PaperUnits','inches')
set(gcf, 'PaperSize',[6 11])
set(gcf, 'PaperPosition',[0 0 11 6])
set(gcf, 'PaperOrientation','portrait')
print('-dpng',['Figures\' subjectID ' ' sessionString ' Unimodal Localization Data.png']);


pointSize = choiceResponses(BimodalIndex) * 30 + 40;
%want 1s 'same location' responses to be black, want 0s to be white
pointColor= ((1-choiceResponses(BimodalIndex)) * [1 1 1]);


figure(2);
hold off;
bar(histogramIndex,[twoSourceCount oneSourceCount],'BarWidth',1,'BarLayout','grouped');
colormap([0.8 0.8 0.8; 0.2 0.2 0.2]);
set(gca,'FontSize',20);%set(gca,'YTick',[0.00 0.25 0.50 0.75 1.00]) 
title(['Subject ' subjectID ' ' sessionString ' Common Source Probability']);
axis([-40 40 0 max(max(twoSourceCount,oneSourceCount))]); 
ylabel('Count','fontsize',24);
xlabel('Audiovisual Disparity (Deg)','fontsize',24);
print('-dpng',['Figures\' subjectID ' ' sessionString ' DeltaAV Response Counts.png']);


figure(3);
hold off;
%plot(probabilitySplinePoints(1,:),probabilitySplinePoints(2,:),'--','color',[0.6 0.6 0.6]);
fill([min(histogramIndex) histogramIndex max(histogramIndex)],[0 oneSourceProbCI(:,2)' 0],[0.7 0.7 0.7],'LineStyle','none')
hold on;
fill([min(histogramIndex) histogramIndex max(histogramIndex)],[0 oneSourceProbCI(:,1)' 0],'w','LineStyle','none')
%scatter(deltaAV, choiceResponses(BimodalIndex),pointSize, pointColor,'fill','markeredgecolor','black');
plot(histogramIndex, oneSourceProbability,'k-','LineWidth',2);
set(gca,'FontSize',20);%set(gca,'YTick',[0.00 0.25 0.50 0.75 1.00]) 
title(['Subject ' subjectID ' ' sessionString ' Common Source Probability']);
axis([-1*maxDisparity maxDisparity 0 1]); 
ylabel('Probability of Common Source','fontsize',24);
xlabel('Audiovisual Disparity (Deg)','fontsize',24);
print('-dpng',['Figures\' subjectID ' ' sessionString ' DeltaAV Response Probability.png']);

figure(4);
hold off;
%plot(probabilitySplinePoints(1,:),probabilitySplinePoints(2,:),'--','color',[0.6 0.6 0.6]);
fill([min(correctedHistogramIndex) correctedHistogramIndex max(correctedHistogramIndex)],...
		[0 correctedOneSourceProbCI(:,2)' 0],[0.7 0.7 0.7],'LineStyle','none')
hold on;
fill([min(correctedHistogramIndex) correctedHistogramIndex max(correctedHistogramIndex)],...
		[0 correctedOneSourceProbCI(:,1)' 0],'w','LineStyle','none')
%scatter(deltaAV, choiceResponses(BimodalIndex),pointSize, pointColor,'fill','markeredgecolor','black');
plot(correctedHistogramIndex, correctedOneSourceProbability,'k-','LineWidth',2);
set(gca,'FontSize',20);%set(gca,'YTick',[0.00 0.25 0.50 0.75 1.00]) 
title(['Subject ' subjectID ' ' sessionString ' Common Source Probability']);
axis([-1*maxDisparity maxDisparity 0 1]); 
ylabel('Probability of Common Source','fontsize',24);
xlabel('Perceived Audiovisual Disparity (Deg)','fontsize',24);
set(gcf, 'PaperUnits','inches')
set(gcf, 'PaperSize',[6 11])
set(gcf, 'PaperPosition',[0 0 11 6])
set(gcf, 'PaperOrientation','portrait')
print('-dpng',['Figures\' subjectID ' ' sessionString ' corrected DeltaAV Response Probability.png']);

figure(5);
hold off;
scatter(audTargetLocations(BimodalIndex), visTargetLocations(BimodalIndex),pointSize,pointColor,'fill','markeredgecolor','black');
box on;
set(gca,'FontSize',20);%set(gca,'YTick',[0.00 0.25 0.50 0.75 1.00]) 
title([subjectID ' ' sessionString ' Common Source Responses']);
axis([-45 45 -45 45]); axis square;
ylabel('Visual Target Location (Deg)','fontsize',24);
xlabel('Auditory Target Location (Deg)','fontsize',24);
set(gcf, 'PaperUnits','inches')
set(gcf, 'PaperSize',[8.5 11])
set(gcf, 'PaperPosition',[0 0 11 8.5])
set(gcf, 'PaperOrientation','portrait')
print('-dpng',['Figures\' subjectID ' ' sessionString ' Raw Data.png']);

