% CompareSimulationResults.m
% Created 9/16/2014 by A. Bosen
%
% This script reads the data in the Simulation Results folder and plots a
% comparison of fit parameters for each subject across tasks

%Set filter for all simulation results that have the desired number of model parameters
numParams = 1;
%Set filter for all simulation results that use unimodal data
useUnimodal = 1;

%Find all the data files in .\Simulation Results\ that match number of paramters and unimodal data
fileList = dir(['.\Simulation Results\*' num2str(numParams) ' Free Params*' num2str(useUnimodal) '.mat']);

%Parse out unique subject identifiers
subjectData = struct('ID',{},'Sessions',{});
for (fileListIndex = 1:length(fileList))
	%Check if the file matches the number of parameters and unimodal data
	%Pull the subjectID off the front of the file
	subjectID = fileList(fileListIndex).name(1:strfind(fileList(fileListIndex).name,' ')-1);
	%If this subjectID isn't already in the subjects array, add it.
	if(sum([strcmp({subjectData.ID},subjectID)]) == 0)
		%Get the number of files for this subject, allocate space in subjectData for that many sessions worth of data.
		numFiles = sum(strncmp({fileList.name},[subjectID ' '],length(subjectID) + 1));
		subjectData = [subjectData, struct('ID',subjectID,'Sessions',struct('fitResult',cell(1,numFiles),'meanFitResult',cell(1,numFiles)))];
	end
end

%Select the best (smallest negative log likelihood) model for each session
bestInSession = [];
likelihoods = [];
for (subjectIndex = 1:length(subjectData))
	fileNumber = 1;
	for(sessionNumber = 1:3)
		%trim based on numParams and useUnimodal
		sessionFiles = dir(['.\Simulation Results\' subjectData(subjectIndex).ID ' *Session' num2str(sessionNumber)...
	       				'*' num2str(numParams) ' Free Params*' num2str(useUnimodal) '.mat']);
		sessionLikelihoods = [];
		for(sessionFileIndex = 1:length(sessionFiles))
			sessionData = load(['.\Simulation Results\' sessionFiles(sessionFileIndex).name]);
			subjectData(subjectIndex).Sessions(fileNumber).fitResult = sessionData.fitResult; 
			subjectData(subjectIndex).Sessions(fileNumber).meanFitResult = sessionData.meanFitResult;
			%Add the session, model type, and session number to the data struct
			fileNameSpaces = strfind(sessionFiles(sessionFileIndex).name,' ');
			fileNameUnderscores = strfind(sessionFiles(sessionFileIndex).name,'_');
			subjectData(subjectIndex).Sessions(fileNumber).sessionType =...
				sessionFiles(sessionFileIndex).name(fileNameSpaces(1)+1:fileNameUnderscores(length(fileNameUnderscores))-1);
			subjectData(subjectIndex).Sessions(fileNumber).modelType =...
		       		sessionFiles(sessionFileIndex).name(fileNameSpaces(2)+1:fileNameSpaces(3)-1);
			sessionLikelihoods = [sessionLikelihoods sessionData.meanFitResult.medianLikelihood];
			subjectData(subjectIndex).Sessions(fileNumber).sessionNumber =...
		       		str2num(sessionFiles(sessionFileIndex).name(fileNameSpaces(2)-1:fileNameSpaces(2)));
			fileNumber = fileNumber + 1;
		end
		%we define the "best" model as one that is significantly better than other models (likelihood at least three less than another model)
		bestInSession = [bestInSession ((min(sessionLikelihoods) + 3) > sessionLikelihoods)];
		likelihoods = [likelihoods sessionLikelihoods];
	end

	%Test if the model parameters for this subject are equal across sessions using Dunn's Test
        %(nonparametric test for differences across multiple group pairs)
	%Two questions we're trying to answer:
	%1. Are the median model parameters equal across repeat sessions, 1 and 3?
	%2. Are the median model parameters equal across task types, 1 and 2?

	%I feel like I'm losing my mind with this indexing.
	%grab the best sessions for this subject for stat testing	
	bestInSessionSubjectIndex = bestInSession(length(bestInSession) - length(subjectData(subjectIndex).Sessions) + 1:length(bestInSession));
	%grab the fit results for the best sessions for this subject and pack it all into one array
	bestFitResults = [subjectData(subjectIndex).Sessions(logical(bestInSessionSubjectIndex)).fitResult];
	dunnTestFreeParameterData = [bestFitResults.freeParameters]';
	dunnGroupIndex = (floor((0:(length([bestFitResults.freeParameters])- 1))/length(subjectData(1).Sessions(1).fitResult)) + 1)';


	%disp(' ');
	%disp(' ');
	%disp('********************************************************************************');
	%disp(['Subject: ' cell2str(subjectData(subjectIndex).ID)]);
	%disp('Groups are:');
	%disp(['	' mat2str(bestInSessionSubjectIndex)]);
	%for(parameterIndex = 1:length(subjectData(1).Sessions(1).meanFitResult.freeParameters))
		%disp(' ');
		%disp(['Testing Parameter: ' cell2str(subjectData(1).Sessions(1).meanFitResult.freeParamNames(parameterIndex))]);
		%Run Dunn's Test on the sample data for the best model fit.
		%If there are multiple bests for a session, chuck both of them in, see what happens.
		%This implementation of the test was developed by Giuseppe Cardillo and published through Matlab Central in 2009

		%Select the data for this parameter for each subject and pack it into a matrix.
		%Column 1 is the samples
		%Column 2 is the index for which group the sample belongs to
		%dunnTestMatrix = [dunnTestFreeParameterData(:,parameterIndex) dunnGroupIndex];
		%dunn(dunnTestMatrix);
	%end
end

%Build a color map for verifying the plots work, map index of the color matrix to a subjectIndex
subjectColor = jet(length(subjectData));
subjectColor(5,:) = [0.85 0.85 0]; %Make yellow darker for ease of visibility
subjectColor(2,:) = [1 0 1]; %Make medium blue magenta to distinguish it from dark blue
subjectColor(8,:) = [0.3 0 0]; %Darken the dark red to distinguish from bright red
%Specify model type symbols
averagingMarker = 'o';
matchingMarker = 'd';
selectionMarker = 's';


%Create a plot for each free parameter of its median and confidence interval for each subject and session
paramMatrix = [];
for (parameterIndex = 1)
%for (parameterIndex = 1:length(subjectData(1).Sessions(1).meanFitResult.freeParameters))
	%NOTE: This assumes that all files we're comparing have the same number and order of free paramters.
	%This plot doesn't make much sense if this isn't the case
	paramName = subjectData(1).Sessions(1).meanFitResult.freeParamNames(parameterIndex);
	paramValues = [];
	plotAxis = [];
	paramConfInt = [];
	sessionType = [];
	sessionNumber = [];
	modelType = cell(0,0);
	subjectID = cell(0,0);
	plotColor = [];
	averagingIndex = [];
	%SGAarray = [];
	%SGVarray = [];
	%SDAarray = [];
	%SDVarray = [];
	for(subjectIndex = 1:length(subjectData))
		for(fileNumber = 1:length(subjectData(subjectIndex).Sessions))
			%Append data to the plot, if it exists
			if(isstruct(subjectData(subjectIndex).Sessions(fileNumber).meanFitResult))
				%plotAxis groups points from the same subject as a mock x axis
				plotAxis = [plotAxis subjectIndex*25 + 2*fileNumber];
				paramValues = [paramValues...
					subjectData(subjectIndex).Sessions(fileNumber).meanFitResult.medianFreeParameters(parameterIndex)];
				paramConfInt = [paramConfInt...
					subjectData(subjectIndex).Sessions(fileNumber).meanFitResult.freeParameterConfInt(parameterIndex,:)'];
				sessionType = [sessionType strcmp(subjectData(subjectIndex).Sessions(fileNumber).sessionType,'Binding')];
				sessionNumber = [sessionNumber subjectData(subjectIndex).Sessions(fileNumber).sessionNumber];
				modelType = [modelType subjectData(subjectIndex).Sessions(fileNumber).modelType];
				averagingIndex = [averagingIndex strcmp(subjectData(subjectIndex).Sessions(fileNumber).modelType,'Averaging')];
				subjectID = [subjectID subjectData(subjectIndex).ID];
				plotColor = [plotColor ; subjectColor(subjectIndex,:)];
				%TODO: Remove this hack, temporary test
				%SGAarray = [SGAarray subjectData(subjectIndex).Sessions(fileNumber).meanFitResult.fixedParameters.SGA];
				%SGVarray = [SGVarray subjectData(subjectIndex).Sessions(fileNumber).meanFitResult.fixedParameters.SGV];
				%SDAarray = [SDAarray subjectData(subjectIndex).Sessions(fileNumber).meanFitResult.fixedParameters.SDA];
				%SDVarray = [SDVarray subjectData(subjectIndex).Sessions(fileNumber).meanFitResult.fixedParameters.SDV];
			end
		end
	end
	%Hackishness, stuff all the paramValues into a single matrix so I can check for correlations Gary wants me to look for
	paramMatrix = [paramMatrix; paramValues];
	%errorbar defines upper and lower bounds as being added to the central point, so we need to subtract the center before plotting
	paramLowerBound = paramValues - paramConfInt(1,:);
	paramUpperBound = paramConfInt(2,:) - paramValues;

	%Determine the upper bound for the parameter plots
	if(strcmp(cell2str(paramName),'pcommon') == 1)
		maxParamBound = 1;
		minParamBound = 0;
	elseif(sum(strcmp(cell2str(paramName),{'offsetA','offsetV','muP'})) > 0)
		%All mean values can be negative, so the bounds need to incorporate positive and negative values
		maxParamBound = max(abs([paramConfInt(1,:) paramConfInt(2,:)])) * 1.05;
		minParamBound = maxParamBound * -1;
	else
		maxParamBound = max(paramConfInt(2,:)) * 1.05;
		minParamBound = min(paramConfInt(1,:)) * (1/1.05);
	end

	%convert sessionType to a logical so we can index by it
	sessionType = logical(sessionType);
	%Plot parameters for each session and subject
	figure;
	%errorbar(plotAxis(~sessionType),paramValues(~sessionType),...
	%	paramLowerBound(~sessionType),paramUpperBound(~sessionType),...
	%	'.','Color',[0.5 0.5 0.5],'MarkerSize',20,'LineWidth',3);
	bar(1:3:3*7+1,paramValues(strcmp(modelType,'Matching') &  sessionType & sessionNumber ~= 3),0.3,'FaceColor',[0.2 0.2 0.2],'EdgeColor',[0 0 0]);
	hold on;
	bar(2:3:3*7+2,paramValues(strcmp(modelType,'Matching') & ~sessionType & sessionNumber ~= 3),0.3,'FaceColor',[0.6 0.6 0.6],'EdgeColor',[0 0 0]);
	errorbar(1:3:3*7+1,paramValues(strcmp(modelType,'Matching') &  sessionType & sessionNumber ~= 3),...
		paramLowerBound(strcmp(modelType,'Matching') &  sessionType & sessionNumber ~= 3),...
		paramUpperBound(strcmp(modelType,'Matching') &  sessionType & sessionNumber ~= 3),'k','LineStyle','none','LineWidth',2);
	errorbar(2:3:3*7+2,paramValues(strcmp(modelType,'Matching') &  ~sessionType & sessionNumber ~= 3),...
		paramLowerBound(strcmp(modelType,'Matching') &  ~sessionType & sessionNumber ~= 3),...
		paramUpperBound(strcmp(modelType,'Matching') &  ~sessionType & sessionNumber ~= 3),'k','LineStyle','none','LineWidth',2);
	%bar(plotAxis(strcmp(modelType,'Selection')),paramValues(strcmp(modelType,'Selection')),70,plotColor(strcmp(modelType,'Selection'),:),...
	%	'filled','Marker',selectionMarker);
	axis([0 24 minParamBound maxParamBound]);
	ylabel('Prior Expectation','fontsize',24);
	set(gca,'FontSize',20);
	set(gca,'YTick',-20:0.25:20); 
	set(gca,'XTick',25 * [1:length(subjectData)] + (length(subjectData(subjectIndex).Sessions) + 1),'fontsize',24);
	%set(gca,'XTickLabel', {subjectData(:).ID},'fontsize',24);
	%title(paramName);
	set(gcf, 'PaperUnits','inches')
	set(gcf, 'PaperSize',[5 7])
	set(gcf, 'PaperPosition',[0 0 7 5])
	set(gcf, 'PaperOrientation','portrait')
	if(strcmp(paramName,'pcommon') == 1)
		print('-dpng',['Presentation Figures\paramValues ' cell2str(paramName) ' ' num2str(numParams) ' parameters.png']);
	end


	%Create a second plot that scatters the parameter in sessions 2 and 3 as a function of the parameter in session 1
	figure;
	%Needs to be model 2 regression, since we have errors on both X and Y axes.
	%This implementation of GM Model II regression  was developed by Antonio Trujillo-Ortiz and published through Matlab Central in 2014
	%This implementation of horizontal error bars was developed by Jos and published through Matlab Central in 2006

	subplot(2,2,1);
	xindex = sessionNumber == 1;
	yindex = sessionNumber == 3;
	plot([minParamBound maxParamBound], [minParamBound maxParamBound],'LineStyle',':','Color', 'black', 'LineWidth', 0.75);
	hold on;
	fitS1S3 = fitlm(paramValues(xindex),paramValues(yindex));
	disp(fitS1S3);
	S1S3Difference = paramValues(yindex) - paramValues(xindex);
	%plot(paramValues(xindex),predict(fitS1S3,paramValues(xindex)'),'k','LineWidth',2);
	%Check if the least squares regression is significant.  If not, don't perform SMA regression
	if(coefTest(fitS1S3) < 0.05)
		[fitSMAS1S3 SMAS1S3ConfInt] = gmregress(paramValues(xindex),paramValues(yindex));
		%disp('Session 1 Vs Session 3:');
		%disp(['     SMA Confidence Intervals for intercept: ' num2str(SMAS1S3ConfInt(1,:))]);
		%disp(['     SMA Confidence Intervals for slope:     ' num2str(SMAS1S3ConfInt(2,:))]);
		plot([minParamBound maxParamBound], fitSMAS1S3(1) + fitSMAS1S3(2)*[minParamBound maxParamBound],'k','LineWidth',2);
	end
	
	errorbar(paramValues(xindex & ~sessionType),paramValues(yindex & ~sessionType),...
		paramLowerBound(yindex & ~sessionType),paramUpperBound(yindex & ~sessionType),...
		'.','Color',[0.5 0.5 0.5],'LineWidth',2);
	hbar = herrorbar(paramValues(xindex & ~sessionType),paramValues(yindex & ~sessionType),...
		paramLowerBound(xindex & ~sessionType),paramUpperBound(xindex & ~sessionType),...
		'.');
	set(hbar,'Color',[0.5 0.5 0.5],'LineWidth',2);
	errorbar(paramValues(xindex & sessionType),paramValues(yindex & sessionType),...
		paramLowerBound(xindex & sessionType),paramUpperBound(xindex & sessionType),...
		'.k','LineWidth',2);
	hbar = herrorbar(paramValues(xindex & sessionType),paramValues(yindex & sessionType),...
		paramLowerBound(xindex & sessionType),paramUpperBound(xindex & sessionType),...
		'.k');
	set(hbar,'LineWidth',2);
	%Separate scatter by modelType and which task came first
	scatter(paramValues(xindex & ~sessionType & strcmp(modelType,'Averaging')),paramValues(yindex & ~sessionType & strcmp(modelType,'Averaging')),...
		100,[0.5 0.5 0.5],...plotColor(xindex & ~sessionType & strcmp(modelType,'Averaging'),:),
		'filled','Marker',averagingMarker,'MarkerEdgeColor',[0.5 0.5 0.5]);
	scatter(paramValues(xindex & ~sessionType & strcmp(modelType,'Matching')),paramValues(yindex & ~sessionType & strcmp(modelType,'Matching')),...
		100,[0.5 0.5 0.5],...plotColor(xindex & ~sessionType & strcmp(modelType,'Matching'),:),
		'filled','Marker',matchingMarker,'MarkerEdgeColor',[0.5 0.5 0.5]);
	scatter(paramValues(xindex & ~sessionType & strcmp(modelType,'Selection')),paramValues(yindex & ~sessionType & strcmp(modelType,'Selection')),...
		100,[0.5 0.5 0.5],...plotColor(xindex & ~sessionType & strcmp(modelType,'Selection'),:),
		'filled','Marker',selectionMarker,'MarkerEdgeColor',[0.5 0.5 0.5]);
	scatter(paramValues(xindex & sessionType & strcmp(modelType,'Averaging')),paramValues(yindex & sessionType & strcmp(modelType,'Averaging')),...
		100,'black',...plotColor(xindex & sessionType & strcmp(modelType,'Averaging'),:),
		'filled','Marker',averagingMarker,'MarkerEdgeColor','black');
	scatter(paramValues(xindex & sessionType & strcmp(modelType,'Matching')),paramValues(yindex & sessionType & strcmp(modelType,'Matching')),...
		100,'black',...plotColor(xindex & sessionType & strcmp(modelType,'Matching'),:),
		'filled','Marker',matchingMarker,'MarkerEdgeColor','black');
	scatter(paramValues(xindex & sessionType & strcmp(modelType,'Selection')),paramValues(yindex & sessionType & strcmp(modelType,'Selection')),...
		100,'black',...plotColor(xindex & sessionType & strcmp(modelType,'Selection'),:),
		'filled','Marker',selectionMarker,'MarkerEdgeColor','black');
	axis([minParamBound maxParamBound minParamBound maxParamBound]);
	axis square;
	%title(paramName);
	set(gca,'YTick',-20:0.25:20);
	set(gca,'XTick',-50:0.25:50);
	set(gca,'FontSize',10);
	ylabel('Session 3 ','fontsize',12);
	xlabel('Session 1 ','fontsize',12);

	subplot(2,2,2);
	%TODO: Get all the audloc and CJ sessions on the same axis
	xindex = (sessionNumber == 2 | sessionNumber == 3) &  sessionType & ~averagingIndex;
	yindex = (sessionNumber == 2 | sessionNumber == 3) & ~sessionType & ~averagingIndex;
	plot([minParamBound maxParamBound], [minParamBound maxParamBound],'LineStyle',':','Color', 'black', 'LineWidth', 0.75);
	hold on;
	fitS2S3 = fitlm(paramValues(xindex),paramValues(yindex));
	disp(fitS2S3);
	S2S3Difference = paramValues(yindex) - paramValues(xindex);
	%plot(paramValues(xindex),predict(fitS2S3,paramValues(xindex)'),'k','LineWidth',2);
	%Check if the least squares regression is significant.  If not, don't perform SMA regression
	if(coefTest(fitS2S3) < 0.05)
		[fitSMAS2S3 SMAS2S3ConfInt] = gmregress(paramValues(xindex),paramValues(yindex));
		%disp('Session 1 Vs Session 3:');
		%disp(['     SMA Confidence Intervals for intercept: ' num2str(SMAS2S3ConfInt(1,:))]);
		%disp(['     SMA Confidence Intervals for slope:     ' num2str(SMAS2S3ConfInt(2,:))]);
		plot([minParamBound maxParamBound], fitSMAS2S3(1) + fitSMAS2S3(2)*[minParamBound maxParamBound],'k','LineWidth',2);
	end

	%Error bars are colored by session number, gray is auditory localization in session 1
	errorbar(paramValues(xindex & sessionNumber == 2),paramValues(yindex & sessionNumber == 3),...
		paramLowerBound(yindex & sessionNumber == 3),paramUpperBound(yindex & sessionNumber == 3),...
		'.','Color',[0.5 0.5 0.5],'LineWidth',2);
	hbar = herrorbar(paramValues(xindex & sessionNumber == 2),paramValues(yindex & sessionNumber == 3),...
		paramLowerBound(xindex & sessionNumber == 2),paramUpperBound(xindex & sessionNumber == 2),...
		'.');
	set(hbar,'Color',[0.5 0.5 0.5],'LineWidth',2);
	errorbar(paramValues(xindex & sessionNumber == 3),paramValues(yindex & sessionNumber == 2),...
		paramLowerBound(yindex & sessionNumber == 2),paramUpperBound(yindex & sessionNumber == 2),...
		'.k','LineWidth',2);
	hbar = herrorbar(paramValues(xindex & sessionNumber == 3),paramValues(yindex & sessionNumber == 2),...
		paramLowerBound(xindex & sessionNumber == 3),paramUpperBound(xindex & sessionNumber == 3),...
		'.k');
	set(hbar,'LineWidth',2);
	%Separate scatter by modelType and which task came first
	scatter(paramValues(xindex & sessionNumber == 2 & strcmp(modelType,'Averaging')),...
		paramValues(yindex & sessionNumber == 3 & strcmp(modelType,'Averaging')),...
		100,[0.5 0.5 0.5],...plotColor(xindex & sessionNumber == 2 & strcmp(modelType,'Averaging'),:),...
		'filled','Marker',averagingMarker,'MarkerEdgeColor',[0.5 0.5 0.5]);
	scatter(paramValues(xindex & sessionNumber == 2 & strcmp(modelType,'Matching')),...
		paramValues(yindex & sessionNumber == 3 & strcmp(modelType,'Matching')),...
		100,[0.5 0.5 0.5],...plotColor(xindex & sessionNumber == 2 & strcmp(modelType,'Matching'),:),...
		'filled','Marker',matchingMarker,'MarkerEdgeColor',[0.5 0.5 0.5]);
	scatter(paramValues(xindex & sessionNumber == 2 & strcmp(modelType,'Selection')),...
		paramValues(yindex & sessionNumber == 3 & strcmp(modelType,'Selection')),...
		100,[0.5 0.5 0.5],...plotColor(xindex & sessionNumber == 2 & strcmp(modelType,'Selection'),:),...
		'filled','Marker',selectionMarker,'MarkerEdgeColor',[0.5 0.5 0.5]);
	scatter(paramValues(xindex & sessionNumber == 3 & strcmp(modelType,'Averaging')),...
		paramValues(yindex & sessionNumber == 2 & strcmp(modelType,'Averaging')),...
		100,'black',...plotColor(xindex & sessionNumber == 3 & strcmp(modelType,'Averaging'),:),...
		'filled','Marker',averagingMarker,'MarkerEdgeColor','black');
	scatter(paramValues(xindex & sessionNumber == 3 & strcmp(modelType,'Matching')),...
		paramValues(yindex & sessionNumber == 2 & strcmp(modelType,'Matching')),...
		100,'black',...plotColor(xindex & sessionNumber == 3 & strcmp(modelType,'Matching'),:),...
		'filled','Marker',matchingMarker,'MarkerEdgeColor','black');
	scatter(paramValues(xindex & sessionNumber == 3 & strcmp(modelType,'Selection')),...
		paramValues(yindex & sessionNumber == 2 & strcmp(modelType,'Selection')),...
		100,'black',...plotColor(xindex & sessionNumber == 3 & strcmp(modelType,'Selection'),:),...
		'filled','Marker',selectionMarker,'MarkerEdgeColor','black');
	axis([minParamBound maxParamBound minParamBound maxParamBound]);
	axis square; 
	set(gca,'YTick',-20:0.25:20);
	set(gca,'XTick',-50:0.25:50);
	set(gca,'FontSize',10);
	ylabel('Auditory Localization','fontsize',12);
	xlabel('Congruence Judgment','fontsize',12);
	%title('Session 2 vs Session 3');
	
	subplot(2,2,3);
	xindex = (sessionNumber == 1 | sessionNumber == 2) &  sessionType & ~averagingIndex;
	yindex = (sessionNumber == 1 | sessionNumber == 2) & ~sessionType & ~averagingIndex;
	hold off;
	plot([minParamBound maxParamBound], [minParamBound maxParamBound],'LineStyle',':','Color', 'black', 'LineWidth', 0.75);
	hold on;
	fitS1S2 = fitlm(paramValues(xindex),paramValues(yindex));
	disp(fitS1S2);
	S1S2Difference = paramValues(yindex) - paramValues(xindex);
	%plot(paramValues(xindex),predict(fitS1S2,paramValues(xindex)'),'k','LineWidth',2);
	%Check if the least squares regression is significant.  If not, don't perform SMA regression
	if(coefTest(fitS1S2) < 0.05)
		[fitSMAS1S2 SMAS1S2ConfInt] = gmregress(paramValues(xindex),paramValues(yindex));
		%disp('Session 1 Vs Session 2:');
		%disp(['     SMA Confidence Intervals for intercept: ' num2str(SMAS1S2ConfInt(1,:))]);
		%disp(['     SMA Confidence Intervals for slope:     ' num2str(SMAS1S2ConfInt(2,:))]);
		plot([minParamBound maxParamBound], fitSMAS1S2(1) + fitSMAS1S2(2)*[minParamBound maxParamBound],'k','LineWidth',3);
	end
	
	errorbar(paramValues(xindex & sessionNumber == 1),paramValues(yindex & sessionNumber == 2),...
		paramLowerBound(yindex & sessionNumber == 2),paramUpperBound(yindex & sessionNumber == 2),...
		'.k','LineWidth',2);
	hbar = herrorbar(paramValues(xindex & sessionNumber == 1),paramValues(yindex & sessionNumber == 2),...
		paramLowerBound(xindex & sessionNumber == 1),paramUpperBound(xindex & sessionNumber == 1),...
		'.k');
	set(hbar,'LineWidth',2);
	errorbar(paramValues(xindex & sessionNumber == 2),paramValues(yindex & sessionNumber == 1),...
		paramLowerBound(yindex & sessionNumber == 1),paramUpperBound(yindex & sessionNumber == 1),...
		'.','Color',[0.5 0.5 0.5],'LineWidth',2);
	hbar = herrorbar(paramValues(xindex & sessionNumber == 2),paramValues(yindex & sessionNumber == 1),...
		paramLowerBound(xindex & sessionNumber == 2),paramUpperBound(xindex & sessionNumber == 2),...
		'.');
	set(hbar,'Color',[0.5 0.5 0.5],'LineWidth',2);
	set(hbar,'LineWidth',2);
	%Separate scatter by modelType and which task came first
	scatter(paramValues(xindex & sessionNumber == 2 & strcmp(modelType,'Averaging')),...
		paramValues(yindex & sessionNumber == 1 & strcmp(modelType,'Averaging')),...
		100,[0.5 0.5 0.5],...plotColor(xindex & sessionNumber == 2 & strcmp(modelType,'Averaging'),:),...
		'filled','Marker',averagingMarker,'MarkerEdgeColor',[0.5 0.5 0.5]);
	scatter(paramValues(xindex & sessionNumber == 2 & strcmp(modelType,'Matching')),...
		paramValues(yindex & sessionNumber == 1 & strcmp(modelType,'Matching')),...
		100,[0.5 0.5 0.5],...plotColor(xindex & sessionNumber == 2 & strcmp(modelType,'Matching'),:),...
		'filled','Marker',matchingMarker,'MarkerEdgeColor',[0.5 0.5 0.5]);
	scatter(paramValues(xindex & sessionNumber == 2 & strcmp(modelType,'Selection')),...
		paramValues(yindex & sessionNumber == 1 & strcmp(modelType,'Selection')),...
		100,[0.5 0.5 0.5],...plotColor(xindex & sessionNumber == 2 & strcmp(modelType,'Selection'),:),...
		'filled','Marker',selectionMarker,'MarkerEdgeColor',[0.5 0.5 0.5]);
	scatter(paramValues(xindex & sessionNumber == 1 & strcmp(modelType,'Averaging')),...
		paramValues(yindex & sessionNumber == 2 & strcmp(modelType,'Averaging')),...
		100,'black',...plotColor(xindex & sessionNumber == 1 & strcmp(modelType,'Averaging'),:),...
		'filled','Marker',averagingMarker,'MarkerEdgeColor','black');
	scatter(paramValues(xindex & sessionNumber == 1 & strcmp(modelType,'Matching')),...
		paramValues(yindex & sessionNumber == 2 & strcmp(modelType,'Matching')),...
		100,'black',...plotColor(xindex & sessionNumber == 1 & strcmp(modelType,'Matching'),:),...
		'filled','Marker',matchingMarker,'MarkerEdgeColor','black');
	scatter(paramValues(xindex & sessionNumber == 1 & strcmp(modelType,'Selection')),...
		paramValues(yindex & sessionNumber == 2 & strcmp(modelType,'Selection')),...
		100,'black',...plotColor(xindex & sessionNumber == 1 & strcmp(modelType,'Selection'),:),...
		'filled','Marker',selectionMarker,'MarkerEdgeColor','black');
	axis([minParamBound maxParamBound minParamBound maxParamBound]);
	axis square;
	set(gca,'YTick',-20:0.25:20);
	set(gca,'XTick',-50:0.25:50);
	set(gca,'FontSize',10);
	ylabel('Auditory Localization','fontsize',12);
	xlabel('Congruence Judgment','fontsize',12);
	%title('Session 1 vs Session 2');
	%title(paramName);


	set(gcf, 'PaperUnits','inches')
	set(gcf, 'PaperSize',[7 6])
	set(gcf, 'PaperPosition',[0 0 7 6])
	set(gcf, 'PaperOrientation','portrait')
	if(strcmp(paramName,'pcommon') == 1)
		print('-dpng',['Presentation Figures\paramValues ' cell2str(paramName) ' ' num2str(numParams) ' parameters session correlations.png']);
	end

	%[p,tlb,stats] = kruskalwallis([S1S3Difference S2S3Difference S1S2Difference],...
	%	[zeros(1,length(S1S3Difference)) ones(1,length(S2S3Difference)) ones(1,length(S1S2Difference))]);
	%multcompare(stats);
	

end
