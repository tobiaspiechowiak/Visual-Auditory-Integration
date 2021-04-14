% EstimateSumLikelihood.m
% Started 10/29/13 by Adam Bosen
%
% Calculate the sum negative log likelihood of the given model parameters being
% the parameters that describe the subject's task performance

function [sumLikelihood] = EstimateSumLikelihood(freeParametersVector,freeParameterNames, responses, visTargetLocations, audTargetLocations,...
						 fixedParameters, taskTypes, modelType, setNumbers, scaleFactors)
	%Combine free parameters and fixed parameters into one struct
	paramCell = [fieldnames(fixedParameters)' freeParameterNames'; struct2cell(fixedParameters)' num2cell(freeParametersVector.*scaleFactors)'];
	%Useful note for manual scripting, don't actually uncomment this:
	%paramCell = [fieldnames(fitResult.fixedParameters)' fitResult.freeParamNames'; struct2cell(fitResult.fixedParameters)' num2cell(fitResult.freeParameters)']
	modelParameters = struct(paramCell{:});

	sumLikelihood = 0;
	%For each unique pair of target locations, estimate the probability of that pointing response occurring given the current model parameters
	for(lcv1 = 1:length(visTargetLocations))
		currentModelParameters = modelParameters;
		%find any 'Set#' strings in freeParameterNames that match the set for this trial,
		parameterSetIndex = ~cellfun(@isempty,strfind(freeParameterNames,['Set' num2str(setNumbers(lcv1))]));
		if(sum(parameterSetIndex))
			%if we have any matching 'Set#' strings, rename those parameters to not include set number
			currentModelParameters = setfield(currentModelParameters,...
						cellfun(@(x) x(1:strfind(x,'Set')-1), freeParameterNames(parameterSetIndex)),...
						freeParametersVector(parameterSetIndex)...
						);
		end
		%Remove all fields with 'Set' in the name
		currentModelParameters = rmfield(currentModelParameters,freeParameterNames(~cellfun(@isempty,strfind(freeParameterNames,'Set'))));
		%DEBUG: display the value in currentModelParameters to see if I got this bit right
		currentModelParameters;

		%Simulate subject responses based on the task type for this trial
		if(strcmp(taskTypes(lcv1),'Unimodal') == 1)
			%Because unimodal localization doesn't depend on causal inference, we can compute the likelihood analytically
			likelihood = UnimodalPointingResponseLikelihood(currentModelParameters,visTargetLocations(lcv1),audTargetLocations(lcv1),...
									responses(lcv1));
		elseif(strcmp(taskTypes(lcv1),'AudLoc') == 1)
			%Simulate responses to the target pair 10,000 times
			simulatedPointingResponses = SimulatePointingResponses(currentModelParameters,visTargetLocations(lcv1),audTargetLocations(lcv1),...
		       								modelType, 10000);
			%Bin the pointing responses at an increment of 1 degree to estimate response count
			histaxis = -70:1:70;
			count = histc(simulatedPointingResponses,histaxis);
			%Interpolate the probability of the subject's response from the simulation histogram
			%Using linear interpolation instead of cubic splines, because splines can produce negative values
			likelihood = max(0,interp1(histaxis,count/trapz(histaxis,count),responses(lcv1)));

		elseif(strcmp(taskTypes(lcv1),'Forced Choice') == 1)
			simulated2AFCResponses = Simulate2AFCResponses(currentModelParameters,visTargetLocations(lcv1),audTargetLocations(lcv1),...
									modelType, 10000);
			if(responses(lcv1) == 0)
				likelihood = sum(simulated2AFCResponses == 0)/length(simulated2AFCResponses);
			else
				likelihood = sum(simulated2AFCResponses == 1)/length(simulated2AFCResponses);
			end 
		else
			warning('Task type "' + taskTypes(lcv1) + '" is not valid.');
		end
		%Add negative log response likelihood to sum likelihood for each pointing response to this target pair
		sumLikelihood = sumLikelihood - log(likelihood);
		%Prevent the global optimization from failing by replacing infinites with large noninfinite numbers
		if(isinf(sumLikelihood))
			sumLikelihood = 10000;
		end
	end
end 
