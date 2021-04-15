function [sumLikelihood] = EstimateLikelihood(AVmodel, uniqueAVPos, response, decisionRule) 
    % calculates likelihood that current model explains the responses
    sumLikelihood = 0; 
    
    % simulate 10000 responses for each decision rule 
    %  [Averaging, Selection, Matching] = SimulateResponses(AVmodel, uniqueAVPos, 10000); 
    switch decisionRule 
        case 'Averaging'
            [simulatedResponse, ~, ~] = SimulateResponses(AVmodel, uniqueAVPos, 10000);  
        case 'Selection'
            [~,simulatedResponse, ~] = SimulateResponses(AVmodel, uniqueAVPos, 10000);  
        case 'Matching'
            [~,~, simulatedResponse] = SimulateResponses(AVmodel, uniqueAVPos, 10000);  
    end 
    
     % Bin the pointing responses at an increment of 1 degree and create
     % histogram for each unique audio visual combo
    edges = floor(min(min([simulatedResponse;response]))):1:ceil(max(max([simulatedResponse;response]))); 
 
    for i = 1:length(uniqueAVPos)
        count_Response = histcounts(simulatedResponse(:,i),edges)';
        
        %Interpolate the probability of the subject's response from the simulation histogram
        %Using linear interpolation instead of cubic splines, because splines can produce negative values
        likelihood = max(zeros(sum(~isnan(response(:,i))),1),interp1((edges(2:end)+0.5),count_Response/trapz((edges(2:end)+0.5),count_Response),response(~isnan(response(:,i)),i)));
    end 
    
    sumLikelihood = sumLikelihood - (sum(log(likelihood)));
    %Prevent the global optimization from failing by replacing infinites with large noninfinite numbers
    if(isinf(sumLikelihood))
        sumLikelihood = 10000;
    end
end 