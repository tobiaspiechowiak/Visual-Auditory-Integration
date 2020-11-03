% PlotAudlocLikelihoodFunction.m
% Started 3/9/14 by Adam Bosen
%
% Plot pointing responses on top of response likelihood estimated based on the model fit

function [] = PlotAudlocLikelihoodFunction(fitResult,modelType,visTargetLocations,audTargetLocations,pointingLocations,stimType,fileName,subjectID)

%take the model parameters from the fit Result and put them in a single struct
paramCell = [fieldnames(fitResult.fixedParameters)' fitResult.freeParamNames'; struct2cell(fitResult.fixedParameters)'...
		num2cell(fitResult.medianFreeParameters)'];
modelParameters = struct(paramCell{:});

AuditoryIndex = strcmp(stimType,'A') == 1;
VisualIndex = strcmp(stimType,'V') == 1;
BimodalIndex = strcmp(stimType,'B') == 1;

%Indices for breaking plot into right and left hemifields
rightIndex = audTargetLocations > 0 & visTargetLocations > 0;
leftIndex  = audTargetLocations < 0 & visTargetLocations < 0;

%Use model parameters, not a linear model, to corrected data
offsetA = modelParameters.offsetA;
SGA = modelParameters.SGA;
correctedTargetLocation = (audTargetLocations * SGA) + offsetA;



maxError = 25;
if(max(max(abs(pointingLocations(AuditoryIndex) - audTargetLocations(AuditoryIndex)))) > maxError ||...
	max(max(abs(pointingLocations(VisualIndex) - visTargetLocations(VisualIndex)))) > maxError)
	disp(['WARNING: pointing error is greater than plot maximum']);
end


%Build a mesh of likelihood estimates based on fitResult
rightVisTarget = 4:0.5:41;
rightAudTarget = fliplr(rightVisTarget);
rightDeltaRange = rightAudTarget - rightVisTarget;
leftVisTarget = -41:0.5:-4;
leftAudTarget = fliplr(leftVisTarget);
leftDeltaRange = leftAudTarget - leftVisTarget;
errorRange = -50:0.25:50;
rightLikelihood = [];
leftLikelihood = [];
for(lcv1 = 1:length(rightVisTarget))
	%simulate 10000 pointing responses
	simulatedPointingResponses = SimulatePointingResponses(modelParameters, rightVisTarget(lcv1), rightAudTarget(lcv1), modelType, 100000);
	%Use simulation to build a histogram to estimate likelihood
	histaxis = errorRange;
	count = histc(simulatedPointingResponses - (rightAudTarget(lcv1) * SGA + offsetA),histaxis);
	rightLikelihood = [rightLikelihood (count/trapz(histaxis,count))'];
end
for(lcv1 = 1:length(leftVisTarget))
	%simulate 10000 pointing responses
	simulatedPointingResponses = SimulatePointingResponses(modelParameters, leftVisTarget(lcv1), leftAudTarget(lcv1), modelType, 100000);
	%Use simulation to build a histogram to estimate likelihood
	histaxis = errorRange;
	count = histc(simulatedPointingResponses - (leftAudTarget(lcv1) * SGA + offsetA),histaxis);
	leftLikelihood = [leftLikelihood (count/trapz(histaxis,count))'];
end
pointSize = 40;
pointColor = 'black';
figure;
subplot(1,2,1);
%Plot the likelihood estimates
contourf(leftDeltaRange,errorRange,leftLikelihood,40,'LineStyle','none');
colormap(flipud(gray(200)));
hold on;
%plot the raw pointing data
scatter(audTargetLocations(BimodalIndex & leftIndex) - visTargetLocations(BimodalIndex & leftIndex),...
 	pointingLocations(BimodalIndex & leftIndex)  - correctedTargetLocation(BimodalIndex & leftIndex),...
	pointSize,pointColor,'c','fill','markeredgecolor','white');
hold off;
set(gca,'FontSize',16);%set(gca,'YTick',[0.00 0.25 0.50 0.75 1.00])
set(gca,'CLim',[0 max(max([leftLikelihood rightLikelihood]))])
set(gca,'XTick',-40:10:40);
%title('Left Hemifield');
axis([min(leftDeltaRange) max(rightDeltaRange) -1 * maxError maxError]);
ylabel('Perceived Error (Deg)','fontsize',16);
xlabel('Audiovisual Disparity (Deg)','fontsize',16);

%Repeat plot for right hemifield
subplot(1,2,2);
%Plot the likelihood estimates
contourf(rightDeltaRange,errorRange,rightLikelihood,40,'LineStyle','none');
colormap(flipud(gray(200)));
hold on;
%plot the raw pointing data
scatter(audTargetLocations(BimodalIndex & rightIndex) - visTargetLocations(BimodalIndex & rightIndex),...
 	pointingLocations(BimodalIndex & rightIndex)  - correctedTargetLocation(BimodalIndex & rightIndex),...
	pointSize,pointColor,'c','fill','markeredgecolor','white');
hold off;
set(gca,'FontSize',16);%set(gca,'YTick',[0.00 0.25 0.50 0.75 1.00])
set(gca,'XTick',-40:10:40); 
set(gca,'YTick',[-100]);
%title('Right Hemifield');
axis([min(rightDeltaRange) max(rightDeltaRange) -1 * maxError maxError]);
xlabel('Audiovisual Disparity (Deg)','fontsize',16);

%Create the color bar and move it off the plot
bar = colorbar('FontSize',16);
set(bar, 'Position', [0.92 .17 .01 .76]);
set(gca,'CLim',[0 max(max([leftLikelihood rightLikelihood]))])
ylabel(bar, 'Probability');

if(exist('fileName','var'))
	set(gcf,'color','white');
	set(gcf,'PaperUnits','inches','PaperSize',[14, 4],'PaperPosition',[0 0 14 4])
	set(gcf,'InvertHardCopy','off');
	print('-dpng',['Presentation Figures\' fileName]);
end

end
