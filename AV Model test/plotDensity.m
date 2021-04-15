function plotDensity(AVmodel, uniqueAVPos, response, decisionRule) 

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
    x = unique(uniqueAVPos(:,1) - uniqueAVPos(:,2)); 
    y = edges(2:end)'+0.5
    z = zeros(length(x),length(y)); 
    for i = 1:length(uniqueAVPos)
        count_Response = histcounts(simulatedResponse(:,i),edges)';
        temp_x = uniqueAVPos(i,1) - uniqueAVPos(i,2); 
        temp_y = (edges(2:end)+0.5)-uniqueAVPos(i,1);
        idx = find(ismember(y,temp_y)); 
        z(x == temp_x,idx) = z(x == temp_x,idx) + count_Response(idx)'; 
    end 
    z = z/sum(sum(z));
    mesh(x,y,z'); 
end