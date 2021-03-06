% function ShowCoverMap
% This function is used to provde all land classification maps for each year
% Results for LCMAP
% Version 1.2  Acquire map from annual classfication map (04/09/2015)
% Version 1.1  Add disturbance in the annual map (04/01/2015);
% Version 1.0  No disturbance class in the cover map (11/06/2015)
% Tools
addpath('~/ccdc');

% INPUTS:
all_yrs = 1985:2014; % all of years for producing maps
v_input = ccdc_Inputs;
pwd

% structure to record statistics
rec_stat=struct('max_conf',[],'mean_conf',[],'num_class',[],'num_trans',[],'dev',[],...
    'start_end',[],'maj',[]);
num_fc = 0;

% dimension and projection of the image
nrows = v_input.ijdim(1);
ncols = v_input.ijdim(2);
jiDim = [ncols,nrows];
jiUL = v_input.jiul;
res = v_input.resolu;
zc = v_input.zc;
% number of coefficients
num_c = v_input.num_c;
% number of bands
nbands = v_input.nbands;
% max number of maps
max_n = length(all_yrs);
% all julidan dates
mm = 7;
dd = 1;
jul_d = datenummx(all_yrs,mm,dd);
jul_start = datenummx(all_yrs,1,1);
jul_end = datenummx(all_yrs,12,31);

% make Predict folder for storing predict images
n_map=v_input.name_map;% 'CCDCMap';
if isempty(dir(n_map))
    mkdir(n_map);
end

% cd to the folder for storing recored structure
cd(v_input.name_rst);

imf = dir('record_change*'); % folder names
num_line = size(imf,1);
line_pt = 0;
%%
for line = 1:10:num_line
    if 100*(line/num_line) - line_pt > 1
        fprintf('Processing %.0f percent\n',ceil(100*(line/num_line)));
        line_pt = 100*(line/num_line);
    end
    
    % load one line of time series models
    load(imf(line).name);
    
    % postions
    pos = [rec_cg.pos];
    
    % continue if there is no model available
    l_pos = length(pos);
    if l_pos == 0
        continue
    end
    
    % class
    class = [rec_cg.class];
    % classification QA
    class_qa = [rec_cg.classQA];
    
    % For Condition & Cover Map
    for i = 1:l_pos
        
        % id that has cover
        idc = class(:,i) ~= 0;
        
        if sum(idc) > 0
            % get class and class qa
            class_fc = class(idc,i);
            class_qa_fc = class_qa(idc,i);
            
            % add one structure
            num_fc = num_fc + 1;
            % record max confidence
            rec_stat(num_fc).max_conf = max(class_qa_fc);
            
            % record mean confidence
            rec_stat(num_fc).mean_conf = mean(class_qa_fc);
            
            % number of classes
            rec_stat(num_fc).num_class = length(unique(class_fc));
            
            % number of transition
            trans = class_fc(2:end) - class_fc(1:end-1);
            if ~isempty(trans)
                rec_stat(num_fc).num_trans = sum(trans~=0);
            else
                rec_stat(num_fc).num_trans = 0;
            end
            
            % develop exist
            rec_stat(num_fc).c1 = sum(class_fc(:) == 1) > 0;
            rec_stat(num_fc).c2 = sum(class_fc(:) == 2) > 0;
            rec_stat(num_fc).c5 = sum(class_fc(:) == 5) > 0;
            rec_stat(num_fc).c6 = sum(class_fc(:) == 6) > 0;
            rec_stat(num_fc).c7 = sum(class_fc(:) == 7) > 0;
            rec_stat(num_fc).c8 = sum(class_fc(:) == 8) > 0;
            rec_stat(num_fc).c9 = sum(class_fc(:) == 9) > 0;
            rec_stat(num_fc).c10 = sum(class_fc(:) == 10) > 0;
            rec_stat(num_fc).c11 = sum(class_fc(:) == 11) > 0;
            
            % start and end cover
            rec_stat(num_fc).start_end = class_fc(1)*100+class_fc(end);
            
            % majority class
            rec_stat(num_fc).maj = mode(class_fc(:));
        end
               
    end
end
cd ..
save('rec_stat_100','rec_stat');

% % spatial filter
% % temporal filter
% 
% 
% % write ENVI files for ARD
% % Cover Map
% ARD_enviwrite_bands([v_input.l_dir,'/',n_map,'/CoverMap1_4'],CoverMap,'uint8','bsq',all_yrs,'example_img');
% clear CoverMap
% ARD_enviwrite_bands([v_input.l_dir,'/',n_map,'/CoverQAMap1_4'],CoverQAMap,'uint8','bsq',all_yrs,'example_img');
% clear CoverQAMap

% %% Add change event 
% change_map = double(enviread('CCDCMap/ChangeMap'));
% % minimum mapping unit
% num_obj = 5;
% 
% % spatial filtering
% for i = 1:size(change_map,3)
%     i
%     tmp = change_map(:,:,i);
%     tmp(tmp > 0) = 1;
%     segm_tmp=bwlabeln(tmp,8);
%     L = segm_tmp;
%     s = regionprops(L,'area');
%     area = [s.Area];
%     
%     % filter out cloud object < than num_cldoj pixels
%     idx = find(area >= num_obj);
%     tmp(ismember(L,idx)==0) = 0;
%     copy_map = change_map(:,:,i);
%     copy_map(tmp==0) = 0;
%     change_map(:,:,i) = copy_map;
% end
% % write filtered change map
% ARD_enviwrite_bands([v_input.l_dir,'/',n_map,'/FChangeMap'],change_map,'uint16','bsq',all_yrs,'example_img');
% 
% %% change analysis
% max_n = 30;
% map = double(enviread('CCDCMap/CoverMap1_4'));
% change_stat = [];
% 
% for i = 1:max_n-1
%     i
%     change_map = map(:,:,i)*100 + map(:,:,i+1);
%     idstb = map(:,:,i+1)-map(:,:,i);
%     change_stat = [change_stat;change_map(idstb~=0)];
% end
% 
% % update class number
% all_class = unique(change_stat);
% % update number of class
% n_class = length(all_class);
% % calculate proportion based # for each class
% number = hist(change_stat,all_class);
% prct = number/sum(number);

% %% add disturbance (3) to the classification map
% for i = 1:max_n
%     change_tmp = change_map(:,:,i);
%     class_tmp = cover_map(:,:,i);
%     class_tmp(change_tmp>0) = 3;
%     cover_map(:,:,i) = class_tmp;
% end

%%
num_class = [rec_stat.num_class];
num_trans = [rec_stat.num_trans];
id_bad = num_trans + 1 > num_class;

max_conf = [rec_stat.max_conf];
mean_conf = [rec_stat.mean_conf];
dev = [rec_stat.dev];
start_end = [rec_stat.start_end];
maj = [rec_stat.maj];

c1 = [rec_stat.c1];
c2 = [rec_stat.c2];
c5 = [rec_stat.c5];
c6 = [rec_stat.c6];
c7 = [rec_stat.c7];
c8 = [rec_stat.c8];
c9 = [rec_stat.c9];
c10 = [rec_stat.c10];
c11 = [rec_stat.c11];
%%
type = 10;
ids = c10 == true;
figure;hist(maj(ids),unique(maj(ids)));
idsmaj = maj == type;
100*sum(idsmaj)/sum(ids)

%%
figure; hist(maj(id_bad),unique(maj(id_bad)));



