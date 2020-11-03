% FitModelToData.m
% Started 8/26/13 by Adam Bosen
%
% This script takes pointing responses from subject data, then estimates
% model parameters from the pointing response. Prior to execution, the flags
% prior to the main execution loop must be set to the desired value.

%Flags to control program execution

%Number of times to execute the model fit, results are stored in an array
numberOfIterations = 120;

%useUnimodalData determines whether or not to incorporate unimodal pointing
%data into the Bayesian model fit.
useUnimodalData = 1;

%TODO: Sort out who did what first, add to this list accordingly
%Subject identifiers, used for file read names and plot titles
%These subjects performed the Bimodal Auditory Localization task in sessions 1 and 3
%subjectList = {'NHS', 'OJA', 'RJ', 'SEH'};
%These subjects performed the audloc task as sessions 2
subjectList = {'FAK', 'KT', 'OC', 'OCA'};

for(subjectID = subjectList)
	sessionList = {'Session1', 'Session2', 'Session3'};
	for(sessionNumber = sessionList)
		%Because half of the subjects completed the tasks in the opposite order, this conditional
		%needs to be flipped for subjects that performed the audloc task in session 2.
		if( strcmp(cell2str(sessionNumber),'Session2') == 1)
		%if( strcmp(cell2str(sessionNumber),'Session1') == 1 || strcmp(cell2str(sessionNumber),'Session3') == 1)
			%modelType can be 'Averaging', 'Selection', or 'Matching', based on the three
			%models positited by Wozny and Shams 2010.  
			modelTypeList = {'Averaging','Selection','Matching'};
			%taskType can be 'Forced Choice' or 'AudLoc'
			bimodalTaskType = 'AudLoc';
			%session is of the form {Binding|Visual_Capture}_Session{1|2|3|}
			session = ['Visual_Capture_' cell2str(sessionNumber)];
		else
			%If bimodalTaskType is 'Forced Choice', 'Averaging' is an invalid option,
			%since responses are binary.
			modelTypeList = {'Selection','Matching'};
			bimodalTaskType = 'Forced Choice';
			%session is of the form {Binding|Visual_Capture}_Session{1|2|3|}
			session = ['Binding_' cell2str(sessionNumber)];
		end
		for(modelType = modelTypeList)

%--------------------------------------------------------------------------------
%Main program loop, set up simulation for the session in this iteration of the program.
%To reduce the numbe of broken lines of code, the main loop isn't indented relative to loop level.

%Load an array of target locations
[numData,textData] = xlsread(['./Data/' cell2str(subjectID) ' Audloc_' session '.csv']);
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

%Estimate fixed model parameters from subject unimodal pointing data
AudFit = LinearUnimodalFit(audTargetLocations(strcmp(stimType,'A') == 1),pointingLocations(strcmp(stimType,'A') == 1));
VisFit = LinearUnimodalFit(visTargetLocations(strcmp(stimType,'V') == 1),pointingLocations(strcmp(stimType,'V') == 1));


%the fixedParameters structs defines set values for each model parameter.  Any
%parameter NOT set here must be set as a free parameter below
fixedParameters.SGA = AudFit.Coefficients.Estimate(2);		%Auditory Spatial Gain
fixedParameters.SGV = VisFit.Coefficients.Estimate(2);		%Visual Spatial Gain
fixedParameters.offsetA = AudFit.Coefficients.Estimate(1);	%Auditory Spatial Offset
fixedParameters.offsetV = VisFit.Coefficients.Estimate(1);	%Visual Spatial Offset
fixedParameters.SDA = std(AudFit.Residuals.Raw);		%Auditory Uncertainty
fixedParameters.SDAGain = 0;					%Change in Auditory Uncertainty that scales with eccentricity
fixedParameters.SDV = std(VisFit.Residuals.Raw);		%Visual Uncertainty
fixedParameters.SDVGain = 0;					%Change in Visual Uncertainty that scales with eccentricity
fixedParameters.muP = 0;					%prior expectation for the mean of the target distribution
fixedParameters.SDP = 40;					%Prior expectation for target distribution around straight ahead
%fixedParameters.pcommon = 0.1;					%prior expectation of a common cause for auditory and visual signals
fixedParameters.inattentionProbability = 0.01;			%Probability that the subject didn't see the target and will respond based on prior alone
%oddsRatio is ONLY fit in forced choice selection model
%TODO: oddsRatio should be implemented in the manner suggested by Knill
fixedParameters.oddsRatio = 0.5;				%odds ratio required for forced choice selection model to say 'same location'


%fitParameterArray = struct('SDP',0,'pcommon',0);
%fval = zeros(1,numberOfIterations);


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
	taskType = taskType(strcmp(stimType,'B') == 1);
	responseData = responseData(strcmp(stimType,'B') == 1);
	visTargetData = visTargetLocations(strcmp(stimType,'B') == 1);
	audTargetData = audTargetLocations(strcmp(stimType,'B') == 1);
end


disp(['Starting fit for subject ' cell2str(subjectID) ' ' session ', model type: ' cell2str(modelType)]);

fitResult = struct([]);
for(lcv1=1:numberOfIterations)

	%parameter lower bounds MUST be in the same order as they are added to freeParameters
	%freeParamLowerBound = [0, 0, -20, -20,  0,  0,   0, 0, -40,   0, 0, 0];
	%freeParamUpperBound = [2, 2,  20,  20, 30,  2,  10, 2,  40, 100, 1, 1];
	freeParamLowerBound = [0];
	freeParamUpperBound = [1];
	%Calculate the range between the upper and lower bounds
	scaleFactors = (freeParamUpperBound - freeParamLowerBound)';

	%initalize free parameters
	%if you want a free parameter to not be linked across data sets, its name should end
	%with 'Set#', where # is the corresponding set number (assigned when data is read)
	%Initialize all free parameters to start at random location
	%freeParameters.SGA 			= rand() * scaleFactors(1)  + freeParamLowerBound(1);%AudFit.Coefficients.Estimate(2);
	%freeParameters.SGV 			= rand() * scaleFactors(2)  + freeParamLowerBound(2);%VisFit.Coefficients.Estimate(2);
	%freeParameters.offsetA 		= rand() * scaleFactors(3)  + freeParamLowerBound(3);%AudFit.Coefficients.Estimate(1);
	%freeParameters.offsetV 		= rand() * scaleFactors(4)  + freeParamLowerBound(4);%VisFit.Coefficients.Estimate(1);
	%freeParameters.SDA 			= rand() * scaleFactors(1)  + freeParamLowerBound(1);
	%freeParameters.SDAGain			= rand() * scaleFactors(2)  + freeParamLowerBound(2);
	%freeParameters.SDV 			= rand() * scaleFactors(3)  + freeParamLowerBound(3);
	%freeParameters.SDVGain			= rand() * scaleFactors(4)  + freeParamLowerBound(4); 
	%freeParameters.muP			= rand() * scaleFactors(1) + freeParamLowerBound(1);
	%freeParameters.SDP 			= rand() * scaleFactors(1) + freeParamLowerBound(1);
	freeParameters.pcommon 			= rand() * scaleFactors(1) + freeParamLowerBound(1);
	%freeParameters.inattentionProbability 	= rand() * scaleFactors(3) + freeParamLowerBound(3);
	%freeParameters.oddsRatio = 1;
	freeParamNames = fieldnames(freeParameters);
	%Scale parameters to be of identical magnitude, helps the numerical solver do intelligent things
	scaledFreeParams = cell2mat(struct2cell(freeParameters)) ./ scaleFactors;
	scaledLowerBound = freeParamLowerBound ./ scaleFactors';
	scaledUpperBound = freeParamUpperBound ./ scaleFactors';


	fitStartTime = cputime;

	tic		
	%Set pattern search options
	%TODO: Figure out a good method for setting the tolerance values
	options = psoptimset('UseParallel','always','CompletePoll','on','ScaleMesh','off','TolMesh',1e-4,'TolX',1e-4,'TolFun',1e-2,'TolBind',1e-5);
	%Create pool of cores for use in parallel computation
	pool = parpool();
	%run pattern search algorithm
	[xmin,fval] = patternsearch(@(freeParameters) EstimateSumLikelihood(freeParameters,freeParamNames,...
						responseData, visTargetData, audTargetData,...
						fixedParameters,taskType,cell2str(modelType),setNumber,scaleFactors),...
					scaledFreeParams,...
					[],[],[],[],...
					scaledLowerBound,...
					scaledUpperBound,...
					[],options);
	%Release the pool	
	delete(pool);
	toc

	disp(['Finished iteration ' num2str(lcv1) ' after ' num2str(cputime-fitStartTime) ]);
	%record results of search
	fitResult(lcv1).fixedParameters = fixedParameters;
	fitResult(lcv1).freeParameters = xmin .* scaleFactors;
	fitResult(lcv1).freeParamNames = freeParamNames;
	fitResult(lcv1).likelihood = fval;

	%Calculate generalized coefficient of determination
	%Equation given by Nagelkerke 1991, R^2 = 1 - (L(null)/L(model))^(2/n)
	%Note: not the same as Wozny and Shams, R^2 = 1 - exp( -2/n (L(model) - L(null)))
	%Second Note: This must be because the end result is negative log likelihood, not likelihood itself.  Use the Wozny equation.
	%Third Note: Is the Wozny equatino correct?

	%Calculate the likelihood that would result from an auditory only model
	%paramCell = [fieldnames(fitResult(lcv1).fixedParameters)' fitResult(lcv1).freeParamNames';...
	%	    struct2cell(fitResult(lcv1).fixedParameters)' num2cell(fitResult(lcv1).freeParameters)'];
	%bestModelParameters = struct(paramCell{:});
	%TODO: This makes no sense for Congruence Judgment, should we even bother with this?
	%if(strcmp(bimodalTaskType,'AudLoc') == 1)
		%noIntegrationParameters = bestModelParameters;
		%noIntegrationParameters.pcommon = 0;
		%noIntegrationSumLikelihood = EstimateSumLikelihood([],{},responseData,visTargetData,audTargetData,noIntegrationParameters,...
		%				taskType,cell2str(modelType),setNumber,[]);
		%TODO: Updated Rsquared computation based on whether or not unimodal data is incorporated
		%fitResult(lcv1).Rsquared = 1 - (exp(-1 * noIntegrationSumLikelihood) / exp(-1 * fitResult(lcv1).likelihood)) ^(2/length(visTargetData))
		%What to do about the problem of the occasional "impossible" events in the model?  likelihood values stop being meaningful
	%elseif(strcmp(bimodalTaskType,'Forced Choice') == 1)
		%randomGuessingParameters = bestModelParameters;
		%TODO: Break this estimation into two pieces, for localization SDV = inf, for congruence jugment inattention = 1
		%randomGuessingParameters.inattentionProbability = 1;
		%randomGuessingParameters.SDV = inf;
		%randomGuessingSumLikelihood = EstimateSumLikelihood([],{},responseData,visTargetData,audTargetData,randomGuessingParameters,...
		%				taskType,cell2str(modelType),setNumber,[]);
		%fitResult(lcv1).Rsquared = 1 - (exp(-1 * noIntegrationSumLikelihood) / exp(-1 * fitResult(lcv1).likelihood)) ^(2/length(visTargetData))
	%end


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

%Save fit result
save(['./Simulation Results/' cell2str(subjectID) ' ' session ' ' cell2str(modelType) ' ' num2str(length(meanFitResult.freeParameters)) ' Free Params '...
	num2str(useUnimodalData)],'fitResult','meanFitResult');
%Plot Unimodal likelihood data
if(useUnimodalData)
	PlotUnimodalLikelihoodFunctions(meanFitResult,cell2str(modelType),visTargetLocations,audTargetLocations,pointingLocations,stimType,...
	[cell2str(subjectID) ' ' session ' Unimodal Vis ' num2str(length(meanFitResult.freeParameters)) ' Free Params ' num2str(useUnimodalData)...
       	' Likelihood.png'],...
       	[cell2str(subjectID) ' ' session ' Unimodal Aud ' num2str(length(meanFitResult.freeParameters)) ' Free Params ' num2str(useUnimodalData)...
       	' Likelihood.png'],...
	cell2str(subjectID));
end

%Call the appropriate plotting function to generate a raw data and likelihood figure
if(strcmp(bimodalTaskType,'AudLoc') == 1)
	PlotAudlocLikelihoodFunction(meanFitResult,cell2str(modelType),visTargetLocations,audTargetLocations,pointingLocations,stimType,...
		[cell2str(subjectID) ' ' session ' ' cell2str(modelType) ' ' num2str(length(meanFitResult.freeParameters)) ' Free Params '...
		num2str(useUnimodalData) ' Likelihood.png'],cell2str(subjectID));
elseif(strcmp(bimodalTaskType,'Forced Choice') == 1)
	Plot2AFCLikelihoodFunction(meanFitResult,cell2str(modelType),visTargetLocations,audTargetLocations,forcedChoiceResponses,stimType,...
		[cell2str(subjectID) ' ' session ' ' cell2str(modelType) ' ' num2str(length(meanFitResult.freeParameters)) ' Free Params '...
		num2str(useUnimodalData) ' Likelihood.png'],cell2str(subjectID)); 
end
%--------------------------------------------------------------------------------


		%End of main execution loop, iterate over all model types for this session
		end
	%Iterate over all session numbers for this subject
	end
%Iterate over all subjects in subjectList
end

