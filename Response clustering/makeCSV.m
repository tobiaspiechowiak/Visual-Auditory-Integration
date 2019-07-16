
filePath = 'data/NH/';

tmp = [];

for idx = 1:16
   
    load(strcat(filePath,sprintf('%03d',idx),'x'));
    load(strcat(filePath,sprintf('%03d',idx),'y'));
     
    tmp = [tmp;  [x(:) y(:)]...
        ones(length([x(:) y(:) ]),1)*idx];           
              
end

csvwrite(strcat(filePath,'NH.csv'),tmp);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

filePath = 'data/DR/';

tmp = [];

for idx = 1:16
   
    load(strcat(filePath,sprintf('%03d',idx),'x'));
    load(strcat(filePath,sprintf('%03d',idx),'y'));
     
    tmp = [tmp;  [x(:) y(:)]...
        ones(length([x(:) y(:) ]),1)*idx];           
              
end

csvwrite(strcat(filePath,'DR.csv'),tmp);


