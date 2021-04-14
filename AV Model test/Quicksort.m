function [response,uniqueRows] = Quicksort(audiovisual)
% data measurements points are not straight forward... this gets them in
% the proper setup for comparison with simulated data 
sorted = sortrows(audiovisual,[1,2]);
[uniqueRows,~,pairID] = unique(sorted(:,[1,2]), 'rows', 'stable'); 
response = nan(max(accumarray(pairID, 1)),size(uniqueRows,1)); 

for i = 1:max(pairID)
    temp = sorted(pairID == i,3);
    response(1:length(temp),i) = temp; 
end 
end 

