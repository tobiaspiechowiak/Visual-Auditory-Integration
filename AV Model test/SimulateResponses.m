function [Averaging, Selection, Matching] = SimulateResponses(AVmodel, uniqueAVPos, nrOfResponses)
% Simulate dataset based on model parameters, stimuli positions and a
% decision making strategy (i.e. Wozny et al., averaging, model selection)
% and probability matching 
audioPos = uniqueAVPos(:,1); 
visualPos = uniqueAVPos(:,2); 

% increase readability a little 
prior_mu = AVmodel.parameters.prior_mu.value;
prior_mu_std = AVmodel.parameters.prior_mu_std.value; 
prior_common = AVmodel.parameters.prior_common.value; 

%% calculate sigma_aud & sigma_vis per location
A_std = AVmodel.parameters.A_std_offset.value + AVmodel.parameters.A_std_slope.value*abs(audioPos)'; 
V_std = AVmodel.parameters.V_std_offset.value + AVmodel.parameters.V_std_slope.value*abs(visualPos)'; 

%% simulate nrOfResponses unimodal percepts for each location, using a
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

%% now calculate the auditory percept for a common and separate source
A_percept_common = (A_percept./A_std.^2 + V_percept./V_std.^2 + prior_mu./prior_mu_std.^2)./ ...
    (1./A_std.^2 + 1./V_std.^2 + 1./prior_mu_std.^2);

A_percept_seperate = (A_percept./A_std.^2 + prior_mu./prior_mu_std.^2)./ ...
    (1./A_std.^2 + 1./prior_mu_std.^2);

%% now (finally) model the responses based on the decision making criteria 
% random probabilities for probability matching 
prob_match = rand(nrOfResponses,size(p_common,2)); 

% responses per model
Averaging = A_percept_common .* p_common + A_percept_seperate .* (1 - p_common);  
Selection = A_percept_common .* (p_common > 0.5) + A_percept_seperate .* (p_common <= 0.5);  % either first term or second term is 0 
Matching = A_percept_common .* (p_common > prob_match) + A_percept_seperate .* (p_common <= prob_match);  % either first term or second term is 0   

%% add some inattention trials, although instead of based on prior only, it
% could also be a visual response... 
lapseTrials = rand(size(Averaging,1),size(Averaging,2));
guess = randn(size(Averaging,1),size(Averaging,2)) * prior_mu_std + prior_mu;

Averaging(lapseTrials < AVmodel.parameters.inattentionProbability.value) = guess(lapseTrials < AVmodel.parameters.inattentionProbability.value);
Selection(lapseTrials < AVmodel.parameters.inattentionProbability.value) = guess(lapseTrials < AVmodel.parameters.inattentionProbability.value);
Matching(lapseTrials < AVmodel.parameters.inattentionProbability.value) = guess(lapseTrials < AVmodel.parameters.inattentionProbability.value);
end

