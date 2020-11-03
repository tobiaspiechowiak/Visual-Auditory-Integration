% Plot2AFCLikelihoodFunction.m
% Started 3/11/14 by Adam Bosen
%
% Plot forced choice responses on top of response likelihood estimated based on the model fit

function [] = PlotAudlocLikelihoodFunction(fitResult,modelType,visTargetLocations,audTargetLocations,forcedChoiceResponses,stimType,fileName,subjectID)

AuditoryIndex = strcmp(stimType,'A') == 1;
VisualIndex = strcmp(stimType,'V') == 1;
BimodalIndex = strcmp(stimType,'B') == 1;

%Indices for breaking plot into right and left hemifields
rightIndex = audTargetLocations > 0 & visTargetLocations > 0;
leftIndex  = audTargetLocations < 0 & visTargetLocations < 0;

%take the model parameters from the fit Result and put them in a single struct
paramCell = [fieldnames(fitResult.fixedParameters)' fitResult.freeParamNames'; struct2cell(fitResult.fixedParameters)' num2cell(fitResult.freeParameters)'];
modelParameters = struct(paramCell{:});


%Build a mesh of likelihood estimates based on fitResult
rightVisTarget = 4:0.5:41;
rightAudTarget = fliplr(rightVisTarget);
rightDeltaRange = rightAudTarget - rightVisTarget;
leftVisTarget = -41:0.5:-4;
leftAudTarget = fliplr(leftVisTarget);
leftDeltaRange = leftAudTarget - leftVisTarget;
rightLikelihood = [];
leftLikelihood = [];
for(lcv1 = 1:length(rightVisTarget))
	%simulate 10000 pointing responses
	simulated2AFCResponses = Simulate2AFCResponses(modelParameters, rightVisTarget(lcv1), rightAudTarget(lcv1), modelType, 100000);
	%Use simulation to build a histogram to estimate likelihood
	rightLikelihood = [rightLikelihood sum(simulated2AFCResponses == 1)/length(simulated2AFCResponses)];
end
for(lcv1 = 1:length(leftVisTarget))
	%simulate 10000 pointing responses
	simulated2AFCResponses = Simulate2AFCResponses(modelParameters, leftVisTarget(lcv1), leftAudTarget(lcv1), modelType, 100000);
	%Use simulation to build a histogram to estimate likelihood
	leftLikelihood = [leftLikelihood sum(simulated2AFCResponses == 1)/length(simulated2AFCResponses)];
end
			
pointSize = forcedChoiceResponses * 30 + 40;
%want 1s 'same location' responses to be black, want 0s to be white
pointColor= (1-forcedChoiceResponses) * [1 1 1];
figure;
subplot(1,2,1);
%Plot the likelihood estimates
plot(leftDeltaRange,leftLikelihood,'LineWidth',5,'Color','Black');
hold on;
%plot the raw pointing data
scatter(audTargetLocations(BimodalIndex & leftIndex) - visTargetLocations(BimodalIndex & leftIndex),...
	forcedChoiceResponses(BimodalIndex & leftIndex),...
	pointSize(BimodalIndex & leftIndex), pointColor(BimodalIndex & leftIndex,:),'filled','markeredgecolor','black'); 
hold off;
set(gca,'FontSize',16);%set(gca,'YTick',[0.00 0.25 0.50 0.75 1.00])
set(gca,'XTick',-40:10:40); 
%title('Left Hemifield');
axis([min(leftDeltaRange) max(leftDeltaRange) 0 1]);
ylabel('Probability of Common Source','fontsize',16);

xlabel('Audiovisual Disparity (Deg)','fontsize',16);

%Repeat plot for right hemifield
subplot(1,2,2);
plot(rightDeltaRange,rightLikelihood,'LineWidth',5,'Color','Black');
hold on;
%plot the raw pointing data
scatter(audTargetLocations(BimodalIndex & rightIndex) - visTargetLocations(BimodalIndex & rightIndex),...
	forcedChoiceResponses(BimodalIndex & rightIndex),...
	pointSize(BimodalIndex & rightIndex), pointColor(BimodalIndex & rightIndex,:),'filled','markeredgecolor','black'); 
hold off;
set(gca,'FontSize',16);
set(gca,'XTick',-40:10:40); 
set(gca,'YTick',[2]);
%title('Right Hemifield');
axis([min(rightDeltaRange) max(rightDeltaRange) 0 1]);
xlabel('Audiovisual Disparity (Deg)','fontsize',16);


if(exist('fileName','var'))
	set(gcf,'PaperUnits','inches','PaperSize',[14, 4],'PaperPosition',[0 0 14 4])
	print('-dpng',['Presentation Figures\' fileName]);
end

end
