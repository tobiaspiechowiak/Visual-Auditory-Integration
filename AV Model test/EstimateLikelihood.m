function [sumLikelihood] = EstimateLikelihood(AVmodel, uniqueAVPos, response) 
    % calculates likelihood that current model explains the responses
    sumLikelihood = 0; 
    
    % simulate 10000 responses for each decision rule 
    [Averaging, Selection, Matching] = SimulateResponses(AVmodel, uniqueAVPos, 10000); 
    
    % Bin the pointing responses at an increment of 1 degree to estimate response count
    edges = floor(min(min([Averaging;Selection;Matching;response]))):1:ceil(max(max([Averaging;Selection;Matching;response]))); 
    for i = 1:length(uniqueAVPos)
        count_Averaging = histcounts(Averaging(:,i),edges)';
        count_Selection = histcounts(Selection(:,i),edges)';
        count_Matching = histcounts(Matching(:,i),edges)';

        %Interpolate the probability of the subject's response from the simulation histogram
        %Using linear interpolation instead of cubic splines, because splines can produce negative values
        likelihood = max(zeros(sum(~isnan(response(:,i))),1),interp1((edges(2:end)+0.5),count_Averaging/trapz((edges(2:end)+0.5),count_Averaging),response(~isnan(response(:,i)),i)));
    end 
    sumLikelihood = sumLikelihood - (sum(log(likelihood)));
    %Prevent the global optimization from failing by replacing infinites with large noninfinite numbers
    if(isinf(sumLikelihood))
        sumLikelihood = 10000;
    end
end 