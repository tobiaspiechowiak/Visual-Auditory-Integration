% CalculateR2.m
% Started 2/13/15 by Adam Bosen
%
% This program iterates through subject List and calculates R^2 values for the corresponding task types.

%Number of times to execute the model fit, results are stored in an array
numberOfIterations = 120;

%This only selects the appropriate data set, unimodal data isn't used in R^2 estimates
useUnimodalData = 1;

numParams = 12;

%TODO: Sort out who did what first, add to this list accordingly
%Subject identifiers, used for file read names and plot titles
%These subjects performed the Bimodal Auditory Localization task in sessions 1 and 3
%subjectList = {'NHS', 'OJA', 'RJ', 'SEH'};
%These subjects performed the audloc task as sessions 2
subjectList = {'FAK', 'KT', 'OC', 'OCA'};

for(subjectID = subjectList)
	disp(['Subject: ' subjectID{1}]);
	sessionList = {'Session1', 'Session2', 'Session3'};
	for(sessionNumber = sessionList)
		%Because half of the subjects completed the tasks in the opposite order, this conditional
		%needs to be flipped for subjects that performed the audloc task in session 2.
		if( strcmp(sessionNumber{1},'Session2') == 1)
		%if( strcmp(sessionNumber{1},'Session1') == 1 || strcmp(sessionNumber{1},'Session3') == 1)
			%modelType can be 'Averaging', 'Selection', or 'Matching', based on the three
			%models positited by Wozny and Shams 2010.  
			modelTypeList = {'Averaging','Selection','Matching'};
			%taskType can be 'Forced Choice' or 'AudLoc'
			bimodalTaskType = 'AudLoc';
			%session is of the form {Binding|Visual_Capture}_Session{1|2|3|}
			session = ['Visual_Capture_' sessionNumber{1}];
		else
			%If bimodalTaskType is 'Forced Choice', 'Averaging' is an invalid option,
			%since responses are binary.
			modelTypeList = {'Selection','Matching'};
			bimodalTaskType = 'Forced Choice';
			%session is of the form {Binding|Visual_Capture}_Session{1|2|3|}
			session = ['Binding_' sessionNumber{1}];
		end
		disp(['  Session: ' session]);
		for(modelType = modelTypeList)

%--------------------------------------------------------------------------------
%Main program loop, set up simulation for the session in this iteration of the program.
%To reduce the numbe of broken lines of code, the main loop isn't indented relative to loop level.

%Load an array of target locations
[numData,textData] = xlsread(['./Data/' subjectID{1} ' Audloc_' session '.csv']);
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

%Modify accordingly to split data into multiple sets with unlinked free parameters
setNumber = ones(size(audTargetLocations));


%fitParameterArray = struct('SDP',0,'pcommon',0);
%fval = zeros(1,numberOfIterations);


%for auditory localization and unimodal trials, response data is pointer azimuth
%for forced choice, response data is if pointer elevation is greater than zero
responseData =  cellfun(@(x) strcmp(x,'AudLoc'),taskType)' .* pointingLocations +...
		cellfun(@(x) strcmp(x,'Unimodal'),taskType)' .* pointingLocations +...
		cellfun(@(x) strcmp(x,'Forced Choice'),taskType)' .* forcedChoiceResponses;

%We don't use the unimodal data for R^2 estimation.
taskType = taskType(strcmp(stimType,'B') == 1);
responseData = responseData(strcmp(stimType,'B') == 1);
visTargetData = visTargetLocations(strcmp(stimType,'B') == 1);
audTargetData = audTargetLocations(strcmp(stimType,'B') == 1);

%Load the simulation result data for the current session and model type
load(['./Simulation Results/' subjectID{1} ' ' session ' ' modelType{1} ' ' num2str(numParams) ' Free Params '...
	num2str(useUnimodalData)]);


for(lcv1=1:numberOfIterations)

	%Calculate generalized coefficient of determination
	%Equation given by Nagelkerke 1991, R^2 = 1 - (L(null)/L(model))^(2/n)
	%Note: not the same as Wozny and Shams, R^2 = 1 - exp( -2/n (L(model) - L(null)))
	%Second Note: This must be because the end result is negative log likelihood, not likelihood itself.  Use the Wozny equation.
	%Third Note: Is the Wozny equatino correct?

	%Calculate the likelihood that would result from a "audio-visual disparity does not influence responses" model
	paramCell = [fieldnames(fitResult(lcv1).fixedParameters)' fitResult(lcv1).freeParamNames';...
		    struct2cell(fitResult(lcv1).fixedParameters)' num2cell(fitResult(lcv1).freeParameters)'];
	modelParameters = struct(paramCell{:});
	%TODO: This makes no sense for Congruence Judgment, should we even bother with this?
	if(strcmp(bimodalTaskType,'AudLoc') == 1)
%		noIntegrationParameters = modelParameters;
%		noIntegrationParameters.pcommon = 0;
%		noIntegrationSumLikelihood = EstimateSumLikelihood([],{},responseData,visTargetData,audTargetData,noIntegrationParameters,...
%						taskType,cellstr(modelType),setNumber,[]);
%		modelLikelihood = EstimateSumLikelihood([],{},responseData,visTargetData,audTargetData,modelParameters,...
%						taskType,cellstr(modelType),setNumber,[]);
%		fitResult(lcv1).Rsquared = 1 - (exp(-1 * noIntegrationSumLikelihood) / exp(-1 * modelLikelihood)) ^(2/length(visTargetData));
		randomGuessingParameters = modelParameters;
		randomGuessingParameters.inattentionProbability = 1;
		randomGuessingSumLikelihood = EstimateSumLikelihood([],{},responseData,visTargetData,audTargetData,randomGuessingParameters,...
						taskType,modelType{1},setNumber,[]);
		modelLikelihood = EstimateSumLikelihood([],{},responseData,visTargetData,audTargetData,modelParameters,...
						taskType,modelType{1},setNumber,[]);
		fitResult(lcv1).randomGuessingSumLikelihood = randomGuessingSumLikelihood;
		fitResult(lcv1).modelLikelihood = modelLikelihood;
		fitResult(lcv1).Rsquared = 1 - (exp(-1 * randomGuessingSumLikelihood) / exp(-1 * modelLikelihood)) ^(2/length(visTargetData));
	elseif(strcmp(bimodalTaskType,'Forced Choice') == 1)
		randomGuessingParameters = modelParameters;
		randomGuessingParameters.inattentionProbability = 1;
		randomGuessingSumLikelihood = EstimateSumLikelihood([],{},responseData,visTargetData,audTargetData,randomGuessingParameters,...
						taskType,modelType{1},setNumber,[]);
		modelLikelihood = EstimateSumLikelihood([],{},responseData,visTargetData,audTargetData,modelParameters,...
						taskType,modelType{1},setNumber,[]);
		fitResult(lcv1).randomGuessingSumLikelihood = randomGuessingSumLikelihood;
		fitResult(lcv1).modelLikelihood = modelLikelihood;
		fitResult(lcv1).Rsquared = 1 - (exp(-1 * randomGuessingSumLikelihood) / exp(-1 * modelLikelihood)) ^(2/length(visTargetData));
	end


end 

%Generate text report of data and figures

%average all fit results together, create plots based on average parameter values
meanFitResult = fitResult(1);
meanFitResult.freeParameters = mean([fitResult.freeParameters]')';
meanFitResult.medianFreeParameters = median([fitResult.freeParameters]')';
%Sort and chop off tails to get 95% confidence intervals
sortedParameters = sort([fitResult.freeParameters]'); 
meanFitResult.freeParameterConfInt = sortedParameters([floor(numberOfIterations/(100/2.5)) + 1, ceil(numberOfIterations/(100/97.5)) - 1],:)';
meanFitResult.likelihood = mean([fitResult.likelihood]);
meanFitResult.medianLikelihood = median([fitResult.likelihood]);
sortedLikelihoods = sort([fitResult.likelihood]);
meanFitResult.likelihoodConfInt = sortedLikelihoods([floor(numberOfIterations/(100/2.5)) + 1, ceil(numberOfIterations/(100/97.5)) - 1]);
RsquaredErrorsRemoved = [fitResult.Rsquared];
RsquaredErrorsRemoved = RsquaredErrorsRemoved(~isnan(RsquaredErrorsRemoved));
if(sum(isnan([fitResult.Rsquared])) > 0)
	disp(['WARNING: There were ' num2str(sum(isnan([fitResult.Rsquared]))) ' NANs']);
end
%Theoretically, an R^2 value of -inf is equivalent to a value of 1, since -inf means the null model log likelihood overflowed (which Matlab
%replaces with an infinite value).  NaNs mean the fitted model log likelihood overflowed, which essentially indicates that the fit failed.
%TODO: When this happens, should those fits be removed from the median and confidence interval estimates?
if(sum(isinf([fitResult.Rsquared])) > 0)
	disp(['WARNING: There were ' num2str(sum(isinf([fitResult.Rsquared]))) ' infinite values']);
end
RsquaredErrorsRemoved(isinf(RsquaredErrorsRemoved)) = 1;
randomGuessingSumLikelihoodErrorsRemoved = [fitResult.randomGuessingSumLikelihood];
randomGuessingSumLikelihoodErrorsRemoved = sort(randomGuessingSumLikelihoodErrorsRemoved(~isnan(RsquaredErrorsRemoved))); 
modelLikelihoodErrorsRemoved = [fitResult.modelLikelihood];
modelLikelihoodErrorsRemoved = sort(modelLikelihoodErrorsRemoved(~isnan(RsquaredErrorsRemoved))); 
meanFitResult.medianRandomGuessingSumLikelihood = median(randomGuessingSumLikelihoodErrorsRemoved);
meanFitResult.medianModelLikelihood = median(modelLikelihoodErrorsRemoved);
meanFitResult.medianRsquared = median(RsquaredErrorsRemoved);
sortedRsquared = sort([RsquaredErrorsRemoved]);
meanFitResult.RsquaredConfInt = sortedRsquared([floor(length(sortedRsquared)/(100/2.5)) + 1, ceil(length(sortedRsquared)/(100/97.5)) - 1]);
disp(['    Model type ' modelType{1}]);
disp(['      Median Random Guessing Likelihood is ' num2str(meanFitResult.medianRandomGuessingSumLikelihood)]);
disp(['      Median Model Likelihood is ' num2str(meanFitResult.medianModelLikelihood)]);
disp(['      Difference between best and next best likelihood is ' num2str(modelLikelihoodErrorsRemoved(2) - modelLikelihoodErrorsRemoved(1))]);
disp(['      Median R squared is ' num2str(meanFitResult.medianRsquared)]);
disp(['      Confidence interval is ' num2str(meanFitResult.RsquaredConfInt)]);
%--------------------------------------------------------------------------------


		%End of main execution loop, iterate over all model types for this session
		end
	%Iterate over all session numbers for this subject
	end
%Iterate over all subjects in subjectList
end

