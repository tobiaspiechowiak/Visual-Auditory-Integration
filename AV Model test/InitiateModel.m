function AVmodel = InitiateModel(audio,visual, subject)
% initiate's model parameters based on the unimodal data given by audio and
% visual 

% generate general model 
AVmodel = AV_model_struct();
AVmodel.settings.subject = subject; 
% %% Fit unimodal data and adjust the model parameters
AVmodel.settings.uni_based_parameters = {'A_slope', 'V_slope', 'A_offset','V_offset','A_std_slope','V_std_slope','A_std_offset','V_std_offset'}; 

% Estimate a linear fit based on the unimodal localization data 
uni_audio_fit = Unimodal_Fit(audio(:,1),audio(:,2)); 
uni_visual_fit = Unimodal_Fit(visual(:,1),visual(:,2));

% linear fit standard deviation to determine std and stdgain? 
[~, order] = sort(audio(:,1)); 
temp_aud_x = reshape(sqrt(reshape(audio(order,1),[5 7]).^2),[1,35]); 
temp_aud_y = reshape(sqrt((reshape(audio(order,2),[5 7]) - mean(reshape(audio(order,2),[5 7]),1)).^2),[1,35]); 
[~, order] = sort(visual(:,1)); 
temp_vis_x = reshape(sqrt(reshape(visual(order,1),[3 7]).^2),[1,21]); 
temp_vis_y = reshape(sqrt((reshape(visual(order,2),[3 7]) - mean(reshape(visual(order,2),[3 7]),1)).^2),[1,21]); 
uni_audio_std_fit = Unimodal_Fit(temp_aud_x,temp_aud_y); 
uni_visual_std_fit = Unimodal_Fit(temp_vis_x,temp_vis_y); 

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
                case 'A_std_slope'
                    AVmodel.parameters.(AVmodel.settings.uni_based_parameters{i}).value = uni_audio_std_fit.Coefficients.Estimate(2); 
                case 'V_std_slope'
                    AVmodel.parameters.(AVmodel.settings.uni_based_parameters{i}).value = uni_visual_std_fit.Coefficients.Estimate(2); 
                case 'A_std_offset'
                    AVmodel.parameters.(AVmodel.settings.uni_based_parameters{i}).value = uni_audio_std_fit.Coefficients.Estimate(1);
                case 'V_std_offset'
                    AVmodel.parameters.(AVmodel.settings.uni_based_parameters{i}).value = uni_visual_std_fit.Coefficients.Estimate(1);
            end 
        end 
    end
end 
end 