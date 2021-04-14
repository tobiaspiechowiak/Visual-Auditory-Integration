% SimulatePointingResponses.m
% Started 8/21/13 by Adam Bosen
%
% Produce a pointing response based on the selected model type
function [simulatedPointingResponses] = SimulatePointingResponses(modelParameters,visTargetLocation, audTargetLocation, modelType, numberOfResponses)
	%Calculate the uncertainty at these target locations
	SDV = (modelParameters.SDV + modelParameters.SDVGain * abs(visTargetLocation));
	SDA = (modelParameters.SDA + modelParameters.SDAGain * abs(audTargetLocation));
	%Roll numberOfResponses random perceived target locations
	visPerceived = randn(1,numberOfResponses) * SDV + modelParameters.SGV * visTargetLocation + modelParameters.offsetV;
	audPerceived = randn(1,numberOfResponses) * SDA + modelParameters.SGA * audTargetLocation + modelParameters.offsetA;

	%Compute p(C=1|xV,xA)
	if (~isnan(SDV) & ~isnan(SDA))
		commonSourceProbability = CommonSourceProbability(SDA, SDV, modelParameters.muP,...
	       					modelParameters.SDP, modelParameters.pcommon, visPerceived, audPerceived);
		%Generate the pointing locations for C=1 and C=2 conditions.
		separateSourceResponse = (modelParameters.muP/(modelParameters.SDP^2) + audPerceived/(SDA^2))/((SDA^-2)+(modelParameters.SDP^-2));
		commonSourceResponse = (modelParameters.muP/(modelParameters.SDP^2) + audPerceived/(SDA^2) + visPerceived/(SDV^2))/...
						((SDA^-2)+(SDV^-2)+(modelParameters.SDP^-2));
	else
		commonSourceProbability = 0;
		commonSourceResponse = 0;
		if(isnan(SDV))
			separateSourceResponse = audPerceived;
		elseif(isnan(SDA))
			separateSourceResponse = visPerceived;
		end
	end
	

	if(strcmp(modelType,'Averaging') == 1)
		%Perform model averaging to produce response location
		simulatedPointingResponses = commonSourceProbability .* commonSourceResponse + (1 - commonSourceProbability) .* separateSourceResponse;
	elseif(strcmp(modelType,'Selection') == 1)
		%Always choose the most probable explanation
		simulatedPointingResponses = (commonSourceProbability > modelParameters.oddsRatio) .* commonSourceResponse +...
		 			     (commonSourceProbability <= modelParameters.oddsRatio) .* separateSourceResponse;
	elseif(strcmp(modelType,'Matching') == 1)
		%Choose each model with a probability equal to their respective probabilities
		variableSelectionCriteria = rand(1,numberOfResponses);
		simulatedPointingResponses = (commonSourceProbability > variableSelectionCriteria) .* commonSourceResponse +...
		 			     (commonSourceProbability <= variableSelectionCriteria) .* separateSourceResponse;

	end

	%Apply inattention probability
	inattentionCriteria = rand(1,numberOfResponses);
	guessLocation = randn(1,numberOfResponses) * modelParameters.SDP + modelParameters.muP;
	%if model was inattentive, guess solely based on prior expectation
	simulatedPointingResponses(inattentionCriteria < modelParameters.inattentionProbability) =...
       		guessLocation(inattentionCriteria < modelParameters.inattentionProbability);
end
