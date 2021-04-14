function AVmodel = VerifyModelParameters(AVmodel)
% Quickly verify that all the parameters have a value, otherwise throw an
% error and calculate variable (if bounds are given)

% settings check is hardcoded
if ~isfield(AVmodel.settings, 'iterations') || isempty(AVmodel.settings.iterations)
     warning('Number of iterations not set. Defaulting to 120\n')
     AVmodel.settings.iterations = 120;
end

if ~isfield(AVmodel.settings, 'subject')|| isempty(AVmodel.settings.subject)
    warning('Subject not set. Defaulting to 0\n')
    AVmodel.settings.subject = 0;
end

fields = fieldnames(AVmodel.parameters);
for i = 1:numel(fields)
    if isempty(AVmodel.parameters.(fields{i}).value)
        warning('%s not set',fields{i})
    end 
end 
            
            
