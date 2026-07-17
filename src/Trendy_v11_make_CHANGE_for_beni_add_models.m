
% ##################################################################
% ##                          2020-03-01                          ##
% ##             Contact:huanyuan.zhang@ouce.ox.ac.uk             ##
% ##                  This is prepared for Beni,                  ##
% ##    in order to calculate Model_variables_ANN_INIT_MEAN.nc    ##
% ##            and Model_variables_ANN_FINAL_MEAN.nc             ##
% ##            as input data for collect_gdf_bymodl.R            ##
% ##################################################################



% ##################################################################################
% ##  because esmFixClim1 require models to increase CO2 concentration by 1%      ##
% ##  every year, to compare with NCC 2019 paper, we take the difference of Cveg  ##
% ##  between 28th year (372ppm) and 78th year (616ppm), then we calculate delta  ##
% ##  Cveg and delta Csoil Input data: CIMP5 esmFixClim1 Csoil or Cveg or Cwood   ##
% ##  or Croot or cLeaf or npp                                                    ##
% ##################################################################################

clc
clear
close all

%These models are selected because they have all variables available
%Model_list={'DLEM';'IBIS';'LPX-Bern';'YIBs';'SDGVM'};
%Model_list={'OCN'};
Model_list={'CABLE-POP';'CLASSIC';'CLM5.0';'DLEM';'ISAM';'IBIS';'LPX-Bern';'VISIT';'SDGVM';'ISBA-CTRIP';'JSBACH';'JULES';'LPJ';'LPJ-GUESS';'VISIT-NIES';'ORCHIDEE'};
Model_list={'JULES'};


%Model_list={'LPJ-GUESS'};%In case you want one model only
Variable_list={'cVeg','gpp','npp','cSoil','cRoot'};
Variable_list={'cWood'};


% file cVeg_Lmon_HadGEM2-ES_esmFixClim1_r1i1p1_185912-188411.nc is broken,
% need to replace with other file. This would not change our final result
% because we will use the 28th year.

%% read maps

%cd /Users/echo/E/RA/trendy_v9
cd J:\Trendy_v11_data_temporary

% All the nc files downloaded from CMIP5 database stored here
% To download input file, go to https://esgf-index1.ceda.ac.uk/search/cmip5-ceda/
% set filter as "esmfixclim1" and "cveg" / "csoil"

%% for each model and each variable do:
for Variable_to_read_num=1:length(Variable_list)
for Modelnum=1:length(Model_list)
    Variable_to_read=Variable_list{Variable_to_read_num};
    Model_name=Model_list{Modelnum};
    File = dir(strcat(Model_name,'_*',Variable_to_read,'*.nc'));
    if ~isempty(File) % note that if we can't find an input file. we will make fake files with 0 as its value
        
        for ii=1:length(File)
            filename=strcat(File(ii).folder,filesep,File(ii).name);
            disp(filename)
            if ii==1
                Csoil=ncread(filename,Variable_to_read);
            else
                Csoil=cat(3,Csoil,ncread(filename,Variable_to_read));
            end
            % read all the Csoil files of the given model, put them into a 3d matrix:
            % latitude*Longitude*year
        end
        %lets assume first year is 285ppm, so 372ppm should be year 28. amd 616ppm should be year 78 (well, if they do increase by 1% every year )
        %Csoil_before=nanmean(Csoil(:,:,325:358),3); % Average across the 27 28 29th years
        %Csoil_After=nanmean(Csoil(:,:,925:960),3);% Average across the 77 78 79th years
      
      
            
        if size(Csoil,3)>1000 % so time more than 1000, it is monthly data
               Csoil_before=nanmean(Csoil(:,:,end-119:end-119+11),3);% if we have 100 year, this is the 90th year
            Csoil_After=nanmean(Csoil(:,:,end-11:end),3);% Average across the last year
            
            elseif size(Csoil,3)<1000 % it is annual data
                Csoil_before=Csoil(:,:,end-9); % Average across the 1st to 10th years
                Csoil_After=Csoil(:,:,end);
            end
%         Csoil_before=Gap_fill_function(Csoil_before); %this is to fill as much NaN as possible, otherwise, average across several models will lost lots of grids.
%         Csoil_before=Gap_fill_function(Csoil_before); %this is to fill as much NaN as possible, otherwise, average across several models will lost lots of grids.
%         Csoil_After=Gap_fill_function(Csoil_After); %this is to fill as much NaN as possible, otherwise, average across several models will lost lots of grids.
%         Csoil_After=Gap_fill_function(Csoil_After); %this is to fill as much NaN as possible, otherwise, average across several models will lost lots of grids.

        %%%This part is used to remove NA value
        Na_to_remove=mode(Csoil_before(:));%my new idea is that the most common values must be the missing value
        if numel(Csoil_before(isnan(Csoil_before))) < numel(Csoil_before(Csoil_before==Na_to_remove)) %make sure that the amount of this value is larger than the amount of NAn
        Csoil_before(Csoil_before==Na_to_remove)=NaN;
        end  
        
        Na_to_remove=mode(Csoil_After(:));%my new idea is that the most common values must be the missing value
        if numel(Csoil_After(isnan(Csoil_After))) < numel(Csoil_After(Csoil_After==Na_to_remove)) %make sure that the amount of this value is larger than the amount of NAn
        Csoil_After(Csoil_After==Na_to_remove)=NaN;
        end 
        Csoil_delta_change=Csoil_After - Csoil_before;
        
            try
                Lon=ncread(filename,'lon');
                Lat=ncread(filename,'lat');
                
            catch
                try
                    Lon=ncread(filename,'x');
                    Lat=ncread(filename,'y');
                catch
                     try
                    Lon=ncread(filename,'lon_FULL');
                    Lat=ncread(filename,'lat_FULL');
                    catch
                    Lon=ncread(filename,'longitude');
                    Lat=ncread(filename,'latitude');
                     end
                end
            end
  
        [lon_num,lat_num]=size(Csoil_delta_change);
        New_file_name=strcat('processed',filesep,Model_name,'_',Variable_to_read,'_','CHANGE.nc');
        fprintf('for model %s lon_num is %d and lat_num is %d',Model_name,lon_num,lat_num)
        if exist(New_file_name,'file')==2
            delete(New_file_name)
        end
        nccreate(New_file_name,'lon','Dimensions',{'lon',lon_num},'Datatype','double')
        ncwrite(New_file_name,'lon',Lon);
        ncwriteatt(New_file_name,'lon','bnds','for bnds check CMIP5 metadata');
        
        nccreate(New_file_name,'lat','Dimensions',{'lat',lat_num},'Datatype','double')
        ncwrite(New_file_name,'lat',Lat);
        
        
        nccreate(New_file_name,Variable_to_read,'Dimensions',{'lon',lon_num,'lat',lat_num},'Datatype','single');
        ncwrite(New_file_name,Variable_to_read,Csoil_delta_change);
        ncwriteatt(New_file_name,Variable_to_read,'units','check CMIP5 metadata');
        ncwriteatt(New_file_name,Variable_to_read,'Description','this is referring to delta_csoil and delta_cveg, the different of 100th year and 110th year, not start and end');
        
        
    else
    %nothing here because they must have cSoil and Cveg
    end
    clear Csoil Csoil_After Csoil_before
    
end
end


