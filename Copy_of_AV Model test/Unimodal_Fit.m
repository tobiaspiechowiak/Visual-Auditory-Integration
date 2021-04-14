function [uni_fit] = Unimodal_Fit(x, y)
% This function calculates best linear fit parameters from unimodal data using a linear
% Based on LinearUnimodalFit by A. Bosen 

% fit a linear model to localization data 
linear_fit = LinearModel.fit(x,y); 
% calculate stddev of the residuals and the median residual 
sigma = std(linear_fit.Residuals.Raw);
residMedian = median(linear_fit.Residuals.Raw);
%Use residual statistics to identify outlier points (more than 4 standard deviations from median error)
% ## What is the basis for this outlier detection method? 
% ## Since variance increases with angle, this would increase outliers at outer angles
% ## Why not use interquartile range? i.e. 1.5 IQR or 3* IQR (strong outliers)
% ## try log transforming the data to compress the error 
outliers = (linear_fit.Residuals.Raw < (residMedian - 4 * sigma)) | ((residMedian + 4 * sigma) < linear_fit.Residuals.Raw);
%Print a message for every outlier removed
for(pointIndex = 1:length(linear_fit.Residuals.Raw))
    if(outliers(pointIndex))
        disp(['Removed outlier, Target Location: ' num2str(x(pointIndex)) ' Response Location: ' num2str(y(pointIndex))]);
    end
end
%Perform the final fit, without outliers
uni_fit = LinearModel.fit(x(~outliers),y(~outliers));
end

