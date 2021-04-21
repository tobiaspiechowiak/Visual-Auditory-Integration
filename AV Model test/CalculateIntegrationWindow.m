function [spatialwindow] = CalculateIntegrationWindow(AVmodel,uniqueAVPos, nrOfResponses)
audioPos = uniqueAVPos(:,1); 
visualPos = uniqueAVPos(:,2); 

% increase readability a little 
prior_mu = AVmodel.parameters.prior_mu.value;A
prior_mu_std = AVmodel.parameters.prior_mu_std.value; 
prior_common = AVmodel.parameters.prior_common.value; 

%% calculate sigma_aud & sigma_vis per location  equ. after 3 +4 
A_std = AVmodel.parameters.A_std_offset.value + AVmodel.parameters.A_std_slope.value*abs(audioPos)'; 
V_std = AVmodel.parameters.V_std_offset.value + AVmodel.parameters.V_std_slope.value*abs(visualPos)'; 

%% simulate nrOfResponses unimodal percepts for each location, using a  (How to sample from gaussian distribution?)
% linear gain based on location with a bias/offset at zero.
% the variance of the distribution from which we sample varies with
% location (see above) 
A_percept = randn(nrOfResponses,1) * A_std + AVmodel.parameters.A_slope.value.*audioPos' + AVmodel.parameters.A_offset.value;
V_percept = randn(nrOfResponses,1) * V_std + AVmodel.parameters.V_slope.value.*visualPos' + AVmodel.parameters.V_offset.value;

%% calculate probability of the percepts for common source p(Xv, Xa|C==1)
%%% in the paper 1/2 is only for the first term, but this may be a mistake 
p_percept_common = 1./(2.*pi.*sqrt(...
    A_std.^2.*V_std.^2 +...
    A_std.^2.*prior_mu_std.^2 +...
    V_std.^2.*prior_mu_std.^2 ))... % root function and first term ends here 
    .* exp(-1/2*(...
    (A_percept - V_percept).^2.*prior_mu_std.^2 + ...
    (A_percept - prior_mu).^2.*V_std.^2 + ...
    (V_percept - prior_mu).^2.*A_std.^2) ...
    ./(...
    A_std.^2.*V_std.^2 +...
    A_std.^2.*prior_mu_std.^2 +...
    V_std.^2.*prior_mu_std.^2 )); 

% calculate probability of the percepts for separate sources p(Xv, Xa|C==2)
p_percept_seperate = 1./(2.*pi.*sqrt(...
    (A_std.^2 + prior_mu_std.^2).* ...
    (V_std.^2 + prior_mu_std.^2)))... % root function and first term ends here 
     .* exp(-1/2*(...
    (A_percept - prior_mu).^2./ ...
    (A_std.^2 + prior_mu_std.^2) +...
    (V_percept - prior_mu).^2./ ...
    (V_std.^2 + prior_mu_std.^2)));  

%% calculate the probability of a common source p(C == 1, Xv, Xa) 
p_common = p_percept_common .* prior_common./(p_percept_common .* prior_common + p_percept_seperate.*(1-prior_common)); 

avg_p_common = mean(p_common,1); 
%% calculate av distance 
x = uniqueAVPos(:,1)-uniqueAVPos(:,2); 

[uniqueRows,~,pairID] = unique(x, 'stable'); 
range = nan(max(accumarray(pairID, 1)),size(uniqueRows,1)); 

for i = 1:max(pairID)
    temp = avg_p_common(pairID == i);
    range(1:length(temp),i) = temp; 
end 

avg_range = nanmean(range,1); 
spatialwindow = max(x(avg_range >= 0.5)) - min(x(avg_range >= 0.5));   
if isempty(spatialwindow)
    spatialwindow = 0; 
end 
    
end 