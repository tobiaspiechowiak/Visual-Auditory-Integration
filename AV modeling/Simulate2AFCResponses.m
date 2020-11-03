% Simulate2AFCResponses.m
% Started 8/21/13 by Adam Bosen
%
% Produce a pointing response based on model averaging

function [simulated2AFCResponses] = Simulate2AFCResponses(modelParameters,visTargetLocation, audTargetLocation, modelType, numberOfResponses)
	%Calculate the uncertainty at these target locations
	SDV = (modelParameters.SDV + modelParameters.SDVGain * abs(visTargetLocation));
	SDA = (modelParameters.SDA + modelParameters.SDAGain * abs(audTargetLocation));
	%Roll numberOfResponses random perceived target locations
	visPerceived = randn(1,numberOfResponses) * SDV + modelParameters.SGV * visTargetLocation + modelParameters.offsetV;
	audPerceived = randn(1,numberOfResponses) * SDA + modelParameters.SGA * audTargetLocation + modelParameters.offsetA;

	%Compute p(C=1|xV,xA)
	commonSourceProbability = CommonSourceProbability(SDA, SDV, modelParameters.muP,...
					modelParameters.SDP, modelParameters.pcommon, visPerceived, audPerceived);

	%Compute odds ratio, compare to model threshold
	if(strcmp(modelType,'Averaging') == 1)
		error('InvalidModelParameter','ERROR: Averaging is not a valid selection for the forced choice model.');
	elseif(strcmp(modelType,'Selection') == 1)
		simulated2AFCResponses = commonSourceProbability > modelParameters.oddsRatio;
	elseif(strcmp(modelType,'Matching') == 1)
		variableSelectionCriteria = rand(1,numberOfResponses);
		simulated2AFCResponses = commonSourceProbability > variableSelectionCriteria;
	end

	%Apply inattention probability
	inattentionCriteria = rand(1,numberOfResponses);
	guessCriteria = rand(1,numberOfResponses);
	%if model was inattentive, guess solely based on prior expectation
	simulated2AFCResponses(inattentionCriteria < modelParameters.inattentionProbability) =...
		guessCriteria(inattentionCriteria < modelParameters.inattentionProbability) < modelParameters.pcommon;
end
