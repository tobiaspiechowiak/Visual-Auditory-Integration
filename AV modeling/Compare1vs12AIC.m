% Compare1vs12AIC
% Created 8/20/2015 by A. Bosen
%
% This script reads the data in the Simulation Results folder and compares AICc values
% of fits for each subject across tasks

%Set filter for all simulation results that have the desired number of model parameters
numParams = 12;
%Set filter for all simulation results that use unimodal data
useUnimodal = 1;

%Find all the data files in .\Simulation Results\ that match number of paramters and unimodal data
fileList = dir(['.\Simulation Results\*' num2str(numParams) ' Free Params*' num2str(useUnimodal) '.mat']);

%Parse out unique subject identifiers
subjectData = struct('ID',{},'Sessions',{});
for (fileListIndex = 1:length(fileList))
	%Check if the file matches the number of parameters and unimodal data
	%Pull the subjectID off the front of the file
	subjectID = fileList(fileListIndex).name(1:strfind(fileList(fileListIndex).name,' ')-1);
	%If this subjectID isn't already in the subjects array, add it.
	if(sum([strcmp({subjectData.ID},subjectID)]) == 0)
		%Get the number of files for this subject, allocate space in subjectData for that many sessions worth of data.
		numFiles = sum(strncmp({fileList.name},[subjectID ' '],length(subjectID) + 1));
		subjectData = [subjectData, struct('ID',subjectID,'Sessions',struct('fitResult',cell(1,numFiles),'meanFitResult',cell(1,numFiles)))];
	end
end

%Get the likelihoods for each session
param12Likelihoods = [];
for (subjectIndex = 1:length(subjectData))
	fileNumber = 1;
	for(sessionNumber = 1:3)
		%trim based on numParams and useUnimodal
		sessionFiles = dir(['.\Simulation Results\' subjectData(subjectIndex).ID ' *Session' num2str(sessionNumber)...
	       				'*' num2str(numParams) ' Free Params*' num2str(useUnimodal) '.mat']);
		sessionLikelihoods = [];
		for(sessionFileIndex = 1:length(sessionFiles))
			sessionData = load(['.\Simulation Results\' sessionFiles(sessionFileIndex).name]);
			subjectData(subjectIndex).Sessions(fileNumber).fitResult = sessionData.fitResult; 
			subjectData(subjectIndex).Sessions(fileNumber).meanFitResult = sessionData.meanFitResult;
			%Add the session, model type, and session number to the data struct
			fileNameSpaces = strfind(sessionFiles(sessionFileIndex).name,' ');
			fileNameUnderscores = strfind(sessionFiles(sessionFileIndex).name,'_');
			subjectData(subjectIndex).Sessions(fileNumber).sessionType =...
				sessionFiles(sessionFileIndex).name(fileNameSpaces(1)+1:fileNameUnderscores(length(fileNameUnderscores))-1);
			subjectData(subjectIndex).Sessions(fileNumber).modelType =...
		       		sessionFiles(sessionFileIndex).name(fileNameSpaces(2)+1:fileNameSpaces(3)-1);
			sessionLikelihoods = [sessionLikelihoods sessionData.meanFitResult.medianLikelihood];
			subjectData(subjectIndex).Sessions(fileNumber).sessionNumber =...
		       		str2num(sessionFiles(sessionFileIndex).name(fileNameSpaces(2)-1:fileNameSpaces(2)));
			fileNumber = fileNumber + 1;
		end
		param12Likelihoods = [param12Likelihoods sessionLikelihoods];
	end

end


%Set filter for all simulation results that have the desired number of model parameters
numParams = 1;
%Set filter for all simulation results that use unimodal data
useUnimodal = 1;

%Find all the data files in .\Simulation Results\ that match number of paramters and unimodal data
fileList = dir(['.\Simulation Results\*' num2str(numParams) ' Free Params*' num2str(useUnimodal) '.mat']);

%Parse out unique subject identifiers
subjectData = struct('ID',{},'Sessions',{});
for (fileListIndex = 1:length(fileList))
	%Check if the file matches the number of parameters and unimodal data
	%Pull the subjectID off the front of the file
	subjectID = fileList(fileListIndex).name(1:strfind(fileList(fileListIndex).name,' ')-1);
	%If this subjectID isn't already in the subjects array, add it.
	if(sum([strcmp({subjectData.ID},subjectID)]) == 0)
		%Get the number of files for this subject, allocate space in subjectData for that many sessions worth of data.
		numFiles = sum(strncmp({fileList.name},[subjectID ' '],length(subjectID) + 1));
		subjectData = [subjectData, struct('ID',subjectID,'Sessions',struct('fitResult',cell(1,numFiles),'meanFitResult',cell(1,numFiles)))];
	end
end

%Get the likelihoods for each session
param1Likelihoods = [];
for (subjectIndex = 1:length(subjectData))
	fileNumber = 1;
	for(sessionNumber = 1:3)
		%trim based on numParams and useUnimodal
		sessionFiles = dir(['.\Simulation Results\' subjectData(subjectIndex).ID ' *Session' num2str(sessionNumber)...
	       				'*' num2str(numParams) ' Free Params*' num2str(useUnimodal) '.mat']);
		sessionLikelihoods = [];
		for(sessionFileIndex = 1:length(sessionFiles))
			sessionData = load(['.\Simulation Results\' sessionFiles(sessionFileIndex).name]);
			subjectData(subjectIndex).Sessions(fileNumber).fitResult = sessionData.fitResult; 
			subjectData(subjectIndex).Sessions(fileNumber).meanFitResult = sessionData.meanFitResult;
			%Add the session, model type, and session number to the data struct
			fileNameSpaces = strfind(sessionFiles(sessionFileIndex).name,' ');
			fileNameUnderscores = strfind(sessionFiles(sessionFileIndex).name,'_');
			subjectData(subjectIndex).Sessions(fileNumber).sessionType =...
				sessionFiles(sessionFileIndex).name(fileNameSpaces(1)+1:fileNameUnderscores(length(fileNameUnderscores))-1);
			subjectData(subjectIndex).Sessions(fileNumber).modelType =...
		       		sessionFiles(sessionFileIndex).name(fileNameSpaces(2)+1:fileNameSpaces(3)-1);
			sessionLikelihoods = [sessionLikelihoods sessionData.meanFitResult.medianLikelihood];
			subjectData(subjectIndex).Sessions(fileNumber).sessionNumber =...
		       		str2num(sessionFiles(sessionFileIndex).name(fileNameSpaces(2)-1:fileNameSpaces(2)));
			fileNumber = fileNumber + 1;
		end
		param1Likelihoods = [param1Likelihoods sessionLikelihoods];
	end

end

param12AIC = param12Likelihoods

%For 1 parameter fit to be better (by AIC) its log likelihood value must be less than 11 greater than the 12 param fit
numBetter1Param = sum(param1Likelihoods - param12Likelihoods < 11)
