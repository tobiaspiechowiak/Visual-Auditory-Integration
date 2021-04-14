function AVmodel = InitiateModel(audio,visual)
% initiate's model parameters based on the unimodal data given by audio and
% visual 

% generate general model 
AVmodel = AV_model_struct();

% %% Fit unimodal data and adjust the model parameters
AVmodel.settings.uni_based_parameters = {'A_slope', 'V_slope', 'A_offset','V_offset','A_std','V_std'}; 

% Estimate a linear fit based on the unimodal localization data 
uni_audio_fit = Unimodal_Fit(audio(:,1),audio(:,2)); 
uni_visual_fit = Unimodal_Fit(visual(:,1),visual(:,2));

% adjust the fixed variables 
for i = 1:numel(AVmodel.settings.uni_based_parameters)
    if ~AVmodel.parameters.(AVmodel.settings.uni_based_parameters{i}).fixed  % check if the variable is set as fixed
        warning('%s is set as a free variable\n', AVmodel.settings.uni_based_parameters{i})
    else
        if ~AVmodel.settings.overwrite_iniated_parameters && ~isempty(AVmodel.parameters.(AVmodel.settings.uni_based_parameters{i}).value) % the variable is already initiated 
            warning('%s is already iniatiated, %s was not overwritten\n', AVmodel.settings.uni_based_parameters{i},AVmodel.settings.uni_based_parameters{i})
        else
            if ~isempty(AVmodel.parameters.(AVmodel.settings.uni_based_parameters{i}).value)
                warning('%s is already iniatiated, overwriting %s \n', AVmodel.settings.uni_based_parameters{i},AVmodel.settings.uni_based_parameters{i})
            end
            switch AVmodel.settings.uni_based_parameters{i}
                case 'A_slope'
                    AVmodel.parameters.(AVmodel.settings.uni_based_parameters{i}).value = uni_audio_fit.Coefficients.Estimate(2);         
                case 'V_slope'
                    AVmodel.parameters.(AVmodel.settings.uni_based_parameters{i}).value = uni_visual_fit.Coefficients.Estimate(2); 
                case 'A_offset'
                    AVmodel.parameters.(AVmodel.settings.uni_based_parameters{i}).value = uni_audio_fit.Coefficients.Estimate(1);             
                case 'V_offset'
                    AVmodel.parameters.(AVmodel.settings.uni_based_parameters{i}).value = uni_visual_fit.Coefficients.Estimate(1); 
                case 'A_std'
                    AVmodel.parameters.(AVmodel.settings.uni_based_parameters{i}).value = uni_audio_fit.Residuals.Raw;
                case 'V_std'
                    AVmodel.parameters.(AVmodel.settings.uni_based_parameters{i}).value = uni_visual_fit.Residuals.Raw;
            end 
        end 
    end
end 

%% 
% Verify that model is completed before use
VerifyModelParameters(AVmodel)
end 