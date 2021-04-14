% import data 
subject = 12; 
[audio,visual,audiovisual] = ImportData(subject, 'Ball'); %%%%%%%% THIS IS CURRENTLY HARDCODED 
% a & v: 1 = stim_pos, 2 = response, av: 1= aud, 2 = vis, 3 = response 

% Initiate parameters based on unimodal data 
AVmodel = InitiateModel(audio,visual, subject); 

[response,uniqueAVPos] = Quicksort(audiovisual); 
%% run the simulations 
% for i = 1:nrOfP_Common_tries 

% randomly generate the free parameters (just p_common at this point) 
AVmodel.parameters.prior_common.value = rand()*AVmodel.parameters.prior_common.upperbound - AVmodel.parameters.prior_common.lowerbound + AVmodel.parameters.prior_common.lowerbound;

% Verify that model is completed before use
AVmodel = VerifyModelParameters(AVmodel)


% run the simulation 
fitStartTime = cputime;

tic		
%Set pattern search options
%TODO: Figure out a good method for setting the tolerance values
options = psoptimset('UseParallel','always','CompletePoll','on','ScaleMesh','off','TolMesh',1e-4,'TolX',1e-4,'TolFun',1e-2,'TolBind',1e-5);
%Create pool of cores for use in parallel computation
pool = parpool();
% %run pattern search algorithm
% [xmin,fval] = patternsearch(@(AVmodel.settings.free) EstimateSumLikelihood(freeParameters,freeParamNames,...
%                     responseData, visTargetData, audTargetData,...
%                     fixedParameters,taskType,cell2str(modelType),setNumber,scaleFactors),...
%                 scaledFreeParams,...
%                 [],[],[],[],...
%                 scaledLowerBound,...
%                 scaledUpperBound,...
%                 [],options);
%Release the pool	
delete(pool);
toc

	disp(['Finished iteration ' num2str(lcv1) ' after ' num2str(cputime-fitStartTime) ]);
	%record results of search
	fitResult(lcv1).fixedParameters = fixedParameters;
	fitResult(lcv1).freeParameters = xmin .* scaleFactors;
	fitResult(lcv1).freeParamNames = freeParamNames;
	fitResult(lcv1).likelihood = fval;