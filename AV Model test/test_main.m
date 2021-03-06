% import data 
subject = 12; 
[audio,visual,audiovisual] = ImportData(subject, 'Ball'); %%%%%%%% THIS IS CURRENTLY HARDCODED 
% a & v: 1 = stim_pos, 2 = response, av: 1= aud, 2 = vis, 3 = response 

% Initiate parameters based on unimodal data 
AVmodel = InitiateModel(audio,visual, subject); 

[response,uniqueAVPos] = Quicksort(audiovisual); 
%% run the simulations
for i = 1:120%AVmodel.settings.iterations
    % randomly generate the free parameters (just p_common at this point) 
    AVmodel.parameters.prior_common.value = rand()*AVmodel.parameters.prior_common.upperbound - AVmodel.parameters.prior_common.lowerbound + AVmodel.parameters.prior_common.lowerbound;

    % Verify that model is completed before use
    AVmodel = VerifyModelParameters(AVmodel);

    % run the simulation multiple times, varying the starting point
    % Prior_common
    decisionRule = 'Matching'; % 'Averaging', 'Selection','Matching'
    fun = @(prior) EstimateLikelihood(AVmodel, uniqueAVPos, response, decisionRule);
    optimal_prior(i) = patternsearch(fun,... % function
        AVmodel.parameters.prior_common.value,... % parameter to optimize 
        [],... % inequality constraints A 
        [],... % inequality constaints B (outcome)
        [],... % 
        [],...
        [AVmodel.parameters.prior_common.lowerbound],...
        [AVmodel.parameters.prior_common.upperbound]);
    spatial_window(i) = CalculateIntegrationWindow(AVmodel, uniqueAVPos, 10000); 
end
