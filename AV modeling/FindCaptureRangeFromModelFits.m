% FindCaptureRangeFromModelFits.m
% Created 8/8/16 by Adam Bosen
%
% This function loads a model fit result and uses the median fit values to
% calculate a common source probability curve over a range of AV separations
% and finds the p(C=1) = 0.5 crossing points, to report as the range of capture.

%TODO: Load target file

%build the array of test points, XV + XA = 45
xV = 22.5:0.05:40;
xA = 45 - xV;
deltaAV = xV - xA;

%Calculate SDA and SDV for these target locations
%12 free parameters
SDA = meanFitResult.medianFreeParameters(5) + meanFitResult.medianFreeParameters(6) * 22.5;
SDV = meanFitResult.medianFreeParameters(7) + meanFitResult.medianFreeParameters(8) * 22.5;
SDP = meanFitResult.medianFreeParameters(10);
pcommon = meanFitResult.medianFreeParameters(11);

%one free parameter
%SDA = meanFitResult.fixedParameters.SDA + meanFitResult.fixedParameters.SDAGain * 22.5;
%SDV = meanFitResult.fixedParameters.SDV + meanFitResult.fixedParameters.SDVGain * 22.5;
%SDP = meanFitResult.fixedParameters.SDP;
%pcommon = meanFitResult.medianFreeParameters(1);

%Call CommonSourceProbability to get the corresponding value for this point
commonSourceProbability = CommonSourceProbability(SDA, SDV, 0, SDP, pcommon, xV, xA); 

%Find the crossing location
[~,captureRangeIndex] = min(abs(commonSourceProbability - 0.5));
captureRange = deltaAV(captureRangeIndex)
%TODO: Display the results for this fit
