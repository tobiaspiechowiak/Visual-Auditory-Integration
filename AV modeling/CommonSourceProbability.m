% CommonSourceProbability.m
% Created 1/8/13 by A. Bosen
%
% This function computes the probability of auditory and visual stimuli
% from a common source, given the visual and auditory mean and uncertainty,
% prior mean and uncertainty, and prior probability of a common source.
% This probability can be used to make perceptual decisions.
% The functions computed here were obtained from Wozny and Shams Nov. 2011,
% equations 9-13.

% SDA - auditory likelihood standard deviation
% SDV - visual likelihood standard deviation
% muP - prior mean
% SDP - prior standard deviation
% pcommon - prior probability of a common cause
% xV - sensation of visual location
% xA - sensation of auditory location

function [probability] = CommonSourceProbability(SDA, SDV, ...
					       	muP, SDP, pcommon, ...
						xV, xA)
	% Wozny and Shams Nov 2011 Equation 12
	% Probability of the signals originating from their respective locations
	% if they originate from a common source
	SDAsquared = SDA.^2;
	SDVsquared = SDV.^2;
	SDPsquared = SDP.^2;
	pxAxVGivenOneSource = (2.*3.14159.*(SDAsquared.*SDVsquared + SDAsquared.*SDPsquared + SDVsquared.*SDPsquared).^0.5).^-1 .* ...
				exp(-0.5.*((xV-xA).^2.*SDPsquared+(xV-muP).^2.*SDAsquared+(xA-muP).^2.*SDVsquared)./...
					 (SDAsquared.*SDVsquared+SDAsquared.*SDPsquared+SDVsquared.*SDPsquared));

	% Wozny and Shams Nov 2011 Equation 13
	% Probability of the signals originating from their respective locations
	% if they do not come from a common source
	% I suspect that the paper had a typo, a missing series of parentheses
	% for the -1/2 multiplication in the exponent
	pxAxVGivenTwoSource = (2.*3.14159.*((SDAsquared+SDPsquared).*(SDVsquared+SDPsquared)).^0.5).^-1 .* ...
				exp(-0.5.*((xA-muP).^2./(SDAsquared+SDPsquared) + (xV-muP).^2./(SDVsquared+SDPsquared)));

	% Wozny and Shams Nov 2011 Equation 9
	% Probability of a common cause, given the input signals.
	probability = (pxAxVGivenOneSource .* pcommon) ./ ...
		(pxAxVGivenOneSource .* pcommon + pxAxVGivenTwoSource .* (1-pcommon));
end
