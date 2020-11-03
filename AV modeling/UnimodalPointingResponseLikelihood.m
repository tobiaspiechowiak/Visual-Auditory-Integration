% UnimodalPointingResponseLikelihood.m
% Started 8/21/13 by Adam Bosen
%
% Analytically compute the probability of the given pointing response

function [likelihood] = UnimodalPointingResponseLikelihood(modelParameters,visTargetLocation, audTargetLocation, response)
	if(~isnan(visTargetLocation) & isnan(audTargetLocation))
		%Visual Target
		SDx = modelParameters.SDV + modelParameters.SDVGain * abs(visTargetLocation);
		xTarget = visTargetLocation * modelParameters.SGV + modelParameters.offsetV;

	elseif(~isnan(audTargetLocation) & isnan(visTargetLocation))
		%Auditory target
		SDx = modelParameters.SDA + modelParameters.SDAGain * abs(audTargetLocation);
		xTarget = audTargetLocation * modelParameters.SGA + modelParameters.offsetA;

	end
	%Compute the SD of the combined cue and prior
	SD = (SDx.^-2 + modelParameters.SDP.^-2).^-0.5;
	%Add the bias toward zero from the prior
	meanPerceivedTargetLoc = (modelParameters.muP/(modelParameters.SDP.^2) + xTarget/(SDx.^2))/(SDx.^-2+modelParameters.SDP.^-2);

	%Calculate the likelihood of the current response as the weighted sum of two gaussians,
	%The range of probably localization responses and the range of inattentive guesses
	%This assumes that the mean of the prior expected location is zero.
	likelihood = (1-modelParameters.inattentionProbability) * ((SD*2.5066).^-1 * exp(-((response - meanPerceivedTargetLoc).^2)/(2*SD.^2))) +...
			modelParameters.inattentionProbability  * ((modelParameters.SDP*2.5066).^-1 *...
		       							exp(-((response - modelParameters.muP).^2)/(2*modelParameters.SDP.^2)));
end
