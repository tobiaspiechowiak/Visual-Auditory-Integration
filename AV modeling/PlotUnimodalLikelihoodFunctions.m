% PlotUnimodalLikelihoodFunctions.m
% Started 3/9/14 by Adam Bosen
%
% Plot pointing responses on top of response likelihood estimated based on the model fit

function [] = PlotUnimodalLikelihoodFunctions(fitResult,modelType,visTargetLocations,audTargetLocations,pointingLocations,stimType,...
						visFileName,audFileName,subjectID)

AuditoryIndex = strcmp(stimType,'A') == 1;
VisualIndex = strcmp(stimType,'V') == 1;
BimodalIndex = strcmp(stimType,'B') == 1;

%take the model parameters from the fit Result and put them in a single struct
paramCell = [fieldnames(fitResult.fixedParameters)' fitResult.freeParamNames'; struct2cell(fitResult.fixedParameters)' num2cell(fitResult.freeParameters)'];
modelParameters = struct(paramCell{:});

maxError = 25;
if(max(max(abs(pointingLocations(AuditoryIndex) - audTargetLocations(AuditoryIndex)))) > maxError ||...
	max(max(abs(pointingLocations(VisualIndex) - visTargetLocations(VisualIndex)))) > maxError)
	disp(['WARNING: pointing error is greater than plot maximum']);
end

%Build a mesh of likelihood estimates based on fitResult
targetRange = -42.5:0.5:42.5;
pointingRange = -70:0.25:70;
visPointingResponseLikelihood = [];
audPointingResponseLikelihood = [];
targetRangeMatrix = repmat(targetRange,length(pointingRange),1);
responseRange = [];
for(target = targetRange)
	visPointingResponseLikelihood = [visPointingResponseLikelihood UnimodalPointingResponseLikelihood(modelParameters,target,NaN,pointingRange)'];
	responseRange = [responseRange (pointingRange - target)'];
end
for(target = targetRange)
	audPointingResponseLikelihood = [audPointingResponseLikelihood UnimodalPointingResponseLikelihood(modelParameters,NaN,target,pointingRange)'];
end
			
pointSize = 20;
pointColor = 'black';
figure;
%Plot the visual likelihood estimates
contourf(targetRangeMatrix,responseRange,visPointingResponseLikelihood,40,'LineStyle','none');
colormap(flipud(gray(200)));
hold on;
%plot the raw pointing data
scatter(visTargetLocations(VisualIndex),...
 	pointingLocations(VisualIndex) - visTargetLocations(VisualIndex),...
	pointSize,pointColor,'c','fill','markeredgecolor','white');
hold off;
set(gca,'FontSize',24);%set(gca,'YTick',[0.00 0.25 0.50 0.75 1.00])
bar = colorbar('FontSize',14);
%set(gca,'CLim',[0 max(max([visPointingResponseLikelihood audPointingResponseLikelihood]))])
ylabel(bar, 'Probability');
if(exist('subjectID','var'))
	title(['Subject ' subjectID ' Pointing Error']);
end
axis([min(targetRange) max(targetRange) -1*maxError maxError]);
ylabel('Pointing Error (Deg)','fontsize',28);
xlabel('Visual Target Location (Deg)','fontsize',28);
set(gca,'YTick',-20:5:20);
set(gca,'XTick',-50:10:50); 
if(exist('visFileName','var'))
	set(gcf, 'PaperUnits','inches');
	set(gcf, 'PaperSize',[6 11]);
	set(gcf, 'PaperPosition',[0 0 11 6]);
	set(gcf, 'PaperOrientation','portrait');
	print('-dpng',['Figures\' visFileName]);
end

figure;
%Plot the auditory likelihood estimates
contourf(targetRangeMatrix,responseRange,audPointingResponseLikelihood,40,'LineStyle','none');
colormap(flipud(gray(200)));
hold on;
%plot the raw pointing data
scatter(audTargetLocations(AuditoryIndex),...
 	pointingLocations(AuditoryIndex) - audTargetLocations(AuditoryIndex),...
	pointSize,pointColor,'c','fill','markeredgecolor','white');
hold off;
set(gca,'FontSize',24);%set(gca,'YTick',[0.00 0.25 0.50 0.75 1.00])
bar = colorbar('FontSize',14);
%set(gca,'CLim',[0 max(max([visPointingResponseLikelihood audPointingResponseLikelihood]))])
ylabel(bar, 'Probability');
if(exist('subjectID','var'))
	title(['Subject ' subjectID ' Pointing Error']);
end
axis([min(targetRange) max(targetRange) -1*maxError maxError]);
ylabel('Pointing Error (Deg)','fontsize',28);
xlabel('Auditory Target Location (Deg)','fontsize',28);
set(gca,'YTick',-20:5:20);
set(gca,'XTick',-50:10:50); 
if(exist('audFileName','var'))
	set(gcf, 'PaperUnits','inches');
	set(gcf, 'PaperSize',[6 11]);
	set(gcf, 'PaperPosition',[0 0 11 6]);
	set(gcf, 'PaperOrientation','portrait');
	print('-dpng',['Figures\' audFileName]);
end

end
