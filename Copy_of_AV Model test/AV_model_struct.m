function [AVmodel] = AV_model_struct()
% This function creates a structure with the parameters used to model audiovisual
% localization data, including settings. 
% Changes to the model fitting parameters can be made here. 
% Note that value changes are only effective when they are fixed.
% Lower and upperbound values only affect the free variables.  

% Based on Bosen et al. 

% Set how often the model is fitted
AVmodel = struct();
%AVmodel.settings.iterations = [];
AVmodel.settings.subject = [];
AVmodel.settings.overwrite_iniated_parameters = 1; %If this is set to 1, then any changes made in this script might be overwritten later on. Otherwise iniated values will be maintained. A warning will occur if parameter conflicts occur. 

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
AVmodel.parameters.A_std.value = [];  
AVmodel.parameters.A_std.lowerbound = 0; 
AVmodel.parameters.A_std.upperbound = 30; 
AVmodel.parameters.A_std.fixed = 1; 

% Visual localization variance. 
AVmodel.parameters.V_std.value = []; 
AVmodel.parameters.V_std.lowerbound = 0; 
AVmodel.parameters.V_std.upperbound = 10; 
AVmodel.parameters.V_std.fixed = 1; 

% Eccentricity related change in auditory localization variance. 
AVmodel.parameters.A_std_gain.value = []; 
AVmodel.parameters.A_std_gain.lowerbound = 0; 
AVmodel.parameters.A_std_gain.upperbound = 2; 
AVmodel.parameters.A_std_gain.fixed = 1; 

% Eccentricity related change in visual localization variance. 
AVmodel.parameters.V_std_gain.value = []; 
AVmodel.parameters.V_std_gain.lowerbound = 0; 
AVmodel.parameters.V_std_gain.upperbound = 2; 
AVmodel.parameters.V_std_gain.fixed = 1; 

% Prior expectation of stimulus location.
AVmodel.parameters.P_mu.value = 0;  
AVmodel.parameters.P_mu.lowerbound = -45; 
AVmodel.parameters.P_mu.upperbound = 45; 
AVmodel.parameters.P_mu.fixed = 1; 

% Deviation of the prior expectation.
AVmodel.parameters.P_std.value = []; 
AVmodel.parameters.P_std.lowerbound = 0; 
AVmodel.parameters.P_std.upperbound = 100; 
AVmodel.parameters.P_std.fixed = 1; 

% Prior expectation of a common cause 
AVmodel.parameters.pcommon.value = [];  
AVmodel.parameters.pcommon.lowerbound = 0; 
AVmodel.parameters.pcommon.upperbound = 1; 
AVmodel.parameters.pcommon.fixed = 0; 

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

%% randomly generate the free parameters
for i = 1:numel(AVmodel.settings.free)
    AVmodel.parameters.(AVmodel.settings.free{i}).value = rand()*(AVmodel.parameters.(AVmodel.settings.free{i}).upperbound - AVmodel.parameters.(AVmodel.settings.free{i}).lowerbound) + AVmodel.parameters.(AVmodel.settings.free{i}).lowerbound;
end 
