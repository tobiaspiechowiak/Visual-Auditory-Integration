% PlotSimulationResult.m
% Started 9/17/14 by Adam Bosen
%
% This script takes pointing responses from subject data and fit parameters
% from simulation results, then plots the results


%Flags to control program execution
%taskType can be 'Forced Choice' or 'AudLoc'
bimodalTaskType = 'AudLoc';
%modelType can be 'Averaging', 'Selection', or 'Matching', based on the three
%models positited by Wozny and Shams 2010.  If bimodalTaskType is 'Forced Choice',
%'Averaging' is an invalid option.
modelType = 'Averaging';
%useUnimodalData determines whether or not to incorporate unimodal pointing
%data into the Bayesian model fit. This should probably be 1 only if SDA and
%SDV are not fixed values. This also only really makes sense for AudLoc.
useUnimodalData = 1;
%Subject identifier, used for file read names and plot titles
subjectID = 'FAK';
%session is of the form {Binding|Visual_Capture}_Session{1|2|3|}
session = 'Visual_Capture_Session2';

%load the subject's data
load(['./Simulation Results/' subjectID ' ' session ' ' modelType ' 12 Free Params 1.mat']);

[numData,textData] = xlsread(['./Data/' subjectID ' Audloc_' session '.csv']);
%Parse relevant columns out of subject data.
audTargetLocations = numData(:,5);
visTargetLocations = numData(:,7);
pointingLocations = numData(:,9);
forcedChoiceResponses = 0 < numData(:,10);
stimType = textData(:,2);
%Chop off stimType header
stimType = stimType(2:length(stimType));

%build empty cell array
taskType = cell(1,size(audTargetLocations,1));
%populate cell array with corresponding task type strings
taskType(strcmp(stimType,'A') | strcmp(stimType,'V')) = {'Unimodal'};
taskType(strcmp(stimType,'B')) = {bimodalTaskType};


%for auditory localization and unimodal trials, response data is pointer azimuth
%for forced choice, response data is if pointer elevation is greater than zero
responseData =  cellfun(@(x) strcmp(x,'AudLoc'),taskType)' .* pointingLocations +...
		cellfun(@(x) strcmp(x,'Unimodal'),taskType)' .* pointingLocations +...
		cellfun(@(x) strcmp(x,'Forced Choice'),taskType)' .* forcedChoiceResponses;

%set input data based on useUnimodalData flag
if(useUnimodalData)
	visTargetData = visTargetLocations;
	audTargetData = audTargetLocations;
	%Insert NaNs for unimodal trials where no target was present
	visTargetData(strcmp(stimType,'A') == 1) = nan;
	audTargetData(strcmp(stimType,'V') == 1) = nan;
else
	responseData = responseData(strcmp(stimType,'B') == 1);
	visTargetData = visTargetLocations(strcmp(stimType,'B') == 1);
	audTargetData = audTargetLocations(strcmp(stimType,'B') == 1);
end


%Plot Unimodal likelihood data
PlotUnimodalLikelihoodFunctions(meanFitResult,modelType,visTargetLocations,audTargetLocations,pointingLocations,stimType,...
	[subjectID ' ' session ' Unimodal Vis ' num2str(length(meanFitResult.freeParameters)) ' Free Params ' num2str(useUnimodalData) ' Likelihood.png'],...
	[subjectID ' ' session ' Unimodal Aud ' num2str(length(meanFitResult.freeParameters)) ' Free Params ' num2str(useUnimodalData) ' Likelihood.png'],...
	subjectID);

%Call the appropriate plotting function to generate a raw data and likelihood figure
if(strcmp(bimodalTaskType,'AudLoc') == 1)
	PlotAudlocLikelihoodFunction(meanFitResult,modelType,visTargetLocations,audTargetLocations,pointingLocations,stimType,...
		[subjectID ' ' session ' ' modelType ' ' num2str(length(meanFitResult.freeParameters)) ' Free Params '...
		num2str(useUnimodalData) ' Likelihood.png'],subjectID);
elseif(strcmp(bimodalTaskType,'Forced Choice') == 1)
	Plot2AFCLikelihoodFunction(meanFitResult,modelType,visTargetLocations,audTargetLocations,forcedChoiceResponses,stimType,...
		[subjectID ' ' session ' ' modelType ' ' num2str(length(meanFitResult.freeParameters)) ' Free Params '...
		num2str(useUnimodalData) ' Likelihood.png'],subjectID); 
end

