% LinearUnimodalFit.m
% Created 9/17/14 by A. Bosen
%
% This function returns a linear best fit for unimodal pointing responses, with
% strong outliers (due to missed targets/inattention) removed.

function [fit] = LinearUnimodalFit(targetLoc, responseLoc)
	%Perform initial fit
	initialFit = LinearModel.fit(targetLoc, responseLoc);
	%Calculate the standard deviation and median of the residual
	sigma = std(initialFit.Residuals.Raw);
	residMedian = median(initialFit.Residuals.Raw);
	%Use residual statistics to identify outlier points (more than 4 standard deviations from median error)
	outliers = (initialFit.Residuals.Raw < (residMedian - 4 * sigma)) | ((residMedian + 4 * sigma) < initialFit.Residuals.Raw);
	%Print a message for every outlier removed
	for(pointIndex = 1:length(initialFit.Residuals.Raw))
		if(outliers(pointIndex))
			disp(['Removed outlier, Target Location: ' num2str(targetLoc(pointIndex)) ' Response Location: ' num2str(responseLoc(pointIndex))]);
		end
	end
	%Perform the final fit, without outliers
	fit = LinearModel.fit(targetLoc(~outliers),responseLoc(~outliers));
end
