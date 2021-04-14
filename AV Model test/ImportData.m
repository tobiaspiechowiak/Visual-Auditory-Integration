function [audio,visual,audiovisual] = ImportData(subjectnr,condition)
%data from subject 12 is probably as close to ideal as we get...
temp = readtable('012.xls');

% convert 360 x and y data to -75 to 
temp{temp{:,6}< 180,6} = -1*temp{temp{:,6}< 180,6};
temp{temp{:,6}> 180,6} = 360-temp{temp{:,6}> 180,6};
temp{temp{:,7}< 180,7} = -1*temp{temp{:,7}< 180,7};
temp{temp{:,7}> 180,7} = 360-temp{temp{:,7}> 180,7};
temp{temp{:,8}< 180,8} = -1*temp{temp{:,8}< 180,8};
temp{temp{:,8}> 180,8} = 360-temp{temp{:,8}> 180,8};

% hardcoded here, replace this!!!!!!!!!!!!
audio = temp{strcmp(temp{:,2}, 'unimodal_audio'),[6,8]}; 
visual = temp{strcmp(temp{:,2}, 'unimodal_visual'),[6,8]}; 
audiovisual = temp{strcmp(temp{:,2}, 'bimodal_ball') & temp{:,10} == 1,[6,7,8]};
end 