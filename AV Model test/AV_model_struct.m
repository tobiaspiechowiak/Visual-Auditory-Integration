function [AVmodel] = AV_model_struct()
% This function creates a structure with the parameters used to model audiovisual
% localization data, including settings. 
% Changes to the model fitting parameters can be made here. 
% Note that value changes are only effective when they are fixed.
% Lower and upperbound values only affect the free variables.  

% Based on Bosen et al. 

% Set how often the model is fitted
AVmodel = struct();
AVmodel.settings.iterations = 120;
AVmodel.settings.subject = [];
AVmodel.settings.overwrite_iniated_parameters = 0; %If this is set to 1, then any changes made in this script might be overwritten later on. Otherwise iniated values will be maintained. A warning will occur if parameter conflicts occur. 

% Auditory localization slope. Perfect localization would give 1. 
AVmodel.parameters.A_slope.value = []; 
AVmodel.parameters.A_slope.lowerbound = 0; 
AVmodel.parameters.A_slope.upperbound = 2; 
AVmodel.parameters.A_slope.fixed = 1; 

% Visual localization slope. Perfect localization would give 1.
AVmodel.parameters.V_slope.value = []; 
AVmodel.parameters.V_slope.lowerbound = 0; 
AVmodel.parameters.V_slope.upperbound = 2; 
AVmodel.parameters.V_slope.fixed = 1; 

% Auditory localization offset at 0. 
AVmodel.parameters.A_offset.value = []; 
AVmodel.parameters.A_offset.lowerbound = -20; 
AVmodel.parameters.A_offset.upperbound = 20; 
AVmodel.parameters.A_offset.fixed = 1; 

% Visual localization offset at 0. 
AVmodel.parameters.V_offset.value = []; 
AVmodel.parameters.V_offset.lowerbound = -20; 
AVmodel.parameters.V_offset.upperbound = 20; 
AVmodel.parameters.V_offset.fixed = 1; 

% Auditory localization variance. 
AVmodel.parameters.A_std_offset.value = [];  
AVmodel.parameters.A_std_offset.lowerbound = 0; 
AVmodel.parameters.A_std_offset.upperbound = 15; 
AVmodel.parameters.A_std_offset.fixed = 1; 

% Visual localization variance. 
AVmodel.parameters.V_std_offset.value = []; 
AVmodel.parameters.V_std_offset.lowerbound = 0; 
AVmodel.parameters.V_std_offset.upperbound = 15; 
AVmodel.parameters.V_std_offset.fixed = 1; 

% Eccentricity related change in auditory localization variance. 
AVmodel.parameters.A_std_slope.value = []; 
AVmodel.parameters.A_std_slope.lowerbound = 0; 
AVmodel.parameters.A_std_slope.upperbound = 2; 
AVmodel.parameters.A_std_slope.fixed = 1; 

% Eccentricity related change in visual localization variance. 
AVmodel.parameters.V_std_slope.value = []; 
AVmodel.parameters.V_std_slope.lowerbound = 0; 
AVmodel.parameters.V_std_slope.upperbound = 2; 
AVmodel.parameters.V_std_slope.fixed = 1; 

% Prior expectation of stimulus location.
AVmodel.parameters.prior_mu.value = 0;  
AVmodel.parameters.prior_mu.lowerbound = -45; 
AVmodel.parameters.prior_mu.upperbound = 45; 
AVmodel.parameters.prior_mu.fixed = 1; 

% Deviation of the prior expectation of stimulus location.
AVmodel.parameters.prior_mu_std.value = 45; 
AVmodel.parameters.prior_mu_std.lowerbound = 0; 
AVmodel.parameters.prior_mu_std.upperbound = 100; 
AVmodel.parameters.prior_mu_std.fixed = 1; 

% Prior expectation of a common cause 
AVmodel.parameters.prior_common.value = [];  
AVmodel.parameters.prior_common.lowerbound = 0; 
AVmodel.parameters.prior_common.upperbound = 1; 
AVmodel.parameters.prior_common.fixed = 0; 

% Probability that subject did not see the stimulus and answers based on
% prior expectation i.e. P_mu & P_std
AVmodel.parameters.inattentionProbability.value = 0.01;
AVmodel.parameters.inattentionProbability.lowerbound = 0; 
AVmodel.parameters.inattentionProbability.upperbound = 1; 
AVmodel.parameters.inattentionProbability.fixed = 1; 

%% find the fixed parameters and free parameters and store them for later 
fixed_fields = {}; 
free_fields = {}; 
fields = fieldnames(AVmodel.parameters);
for i = 1:numel(fields)
    if AVmodel.parameters.(fields{i}).fixed == 1
        fixed_fields{end +1} = fields{i};
    else
        free_fields{end +1} = fields{i};
    end 
end

AVmodel.settings.fixed = fixed_fields;
AVmodel.settings.free = free_fields; 
