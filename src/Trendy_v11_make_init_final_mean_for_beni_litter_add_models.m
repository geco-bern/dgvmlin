
% ##################################################################
% ##                          2024-06-16                          ##
% ##             Contact:huanyuan.zhang@ouce.ox.ac.uk             ##
% ##                  This is prepared for Beni,                  ##
% ##    in order to calculate Model_variables_ANN_INIT_MEAN.nc    ##
% ##            and Model_variables_ANN_FINAL_MEAN.nc             ##
% ##            as input data for collect_gdf_bymodl.R            ##
% ##################################################################



% ##################################################################################
% ## TRENDY V11                                             ##
% ##################################################################################

clc
clear
close all

%These models are selected because they have all variables available
Model_list={'CABLE-POP';'CLASSIC';'CLM5.0';'DLEM';'ISAM';'IBIS';'LPX-Bern';'VISIT';'SDGVM';'ISBA-CTRIP';'JSBACH';'JULES';'LPJ';'LPJ-GUESS';'VISIT-NIES';'ORCHIDEE'};
Model_list={'JULES'};
%Model_list={'LPJ-GUESS'};%In case you want one model only
Variable_list={'gpp','npp'};
Variable_list={'cVeg'};
Variable_list={'rh','cSoil','cVeg','gpp','npp','cLitter','cWood','cLeaf','cRoot'};
Variable_list={'cWood'};

% VISIT don't have npp, we made it from gpp-ra
% SDGVM land cover frac is too large to be read, I do it by cdo

%Variable_list={'arh'};
% A list of model we could use (available on the database),
% file cVeg_Lmon_HadGEM2-ES_esmFixClim1_r1i1p1_185912-188411.nc is broken,
% need to replace with other file. This would not change our final result
% because we will use the 28th year.

%% read maps

cd J:\Trendy_v11_data_temporary
diary on
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
                %nanmean needs the statistic toolbox
                Csoil_before=mean(Csoil(:,:,1:120),3,'omitnan'); % Average across the 1st to 10th years
                Csoil_After=mean(Csoil(:,:,end-119:end),3,'omitnan');% Average across the 51st to 60th years
            elseif size(Csoil,3)<1000 % it is annual data
                Csoil_before=mean(Csoil(:,:,1:10),3,'omitnan'); % Average across the 1st to 10th years
                Csoil_After=mean(Csoil(:,:,end-9:end),3,'omitnan');
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
            
            [lon_num,lat_num,time_num]=size(Csoil);
            New_file_name=strcat('processed',filesep,Model_name,'_',Variable_to_read,'_','INIT_MEAN.nc');
            fprintf('for model %s lon_num is %d and lat_num is %d and time is %d \n',Model_name,lon_num,lat_num,time_num)
            if exist(New_file_name,'file')==2
                delete(New_file_name)
            end
            nccreate(New_file_name,'lon','Dimensions',{'lon',lon_num},'Datatype','double')
            ncwrite(New_file_name,'lon',Lon);
            ncwriteatt(New_file_name,'lon','bnds','for bnds check TRENDYv11 S1 metadata');
            
            nccreate(New_file_name,'lat','Dimensions',{'lat',lat_num},'Datatype','double')
            ncwrite(New_file_name,'lat',Lat);
            
            
            nccreate(New_file_name,Variable_to_read,'Dimensions',{'lon',lon_num,'lat',lat_num},'Datatype','double');
            ncwrite(New_file_name,Variable_to_read,Csoil_before);
            ncwriteatt(New_file_name,Variable_to_read,'units','check TRENDYv11 S1 metadata');
            ncwriteatt(New_file_name,Variable_to_read,'Description','this is a mean value Average across the 24 25 26 27 28 29 30 31 32th years, CMIP5 esmfixclim1');
            
            %% write the second nc file
            
            New_file_name=strcat('processed',filesep,Model_name,'_',Variable_to_read,'_','FINAL_MEAN.nc');
            fprintf('for model %s lon_num is %d and lat_num is %d and time is %d \n',Model_name,lon_num,lat_num,time_num)
            if exist(New_file_name,'file')==2
                delete(New_file_name)
            end
            nccreate(New_file_name,'lon','Dimensions',{'lon',lon_num},'Datatype','double')
            ncwrite(New_file_name,'lon',Lon);
            ncwriteatt(New_file_name,'lon','bnds','for bnds check TRENDYv11 S1 metadata');
            
            
            nccreate(New_file_name,'lat','Dimensions',{'lat',lat_num},'Datatype','double')
            ncwrite(New_file_name,'lat',Lat);
            
            nccreate(New_file_name,Variable_to_read,'Dimensions',{'lon',lon_num,'lat',lat_num},'Datatype','double');
            ncwrite(New_file_name,Variable_to_read,Csoil_After);
            ncwriteatt(New_file_name,Variable_to_read,'units','check TRENDYv11 S1 metadata');
            ncwriteatt(New_file_name,Variable_to_read,'Description','this is a mean value Average across the 74 75 76 77 78 79 80 81 82th years, CMIP5 esmfixclim1');
        else
            %%% no file found, we have to make fake file for this variable,
            %%% GPP is the most complete so we read the GPP file as
            %%% template, then multiply all values with 0
            Model_name=Model_list{Modelnum};
            fprintf('Warning, fake file has to be made, for model %s variable %s \n',Model_name,Variable_to_read)

            Variable_to_read='gpp';
            File = dir(strcat(Model_name,'_*',Variable_to_read,'.nc'));
            
            
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

            
            if size(Csoil,3)>1000 % so time more than 1000, it is monthly data
                
                Csoil_before=mean(Csoil(:,:,1:120),3,'omitnan'); % Average across the 1st to 10th years
                Csoil_After=mean(Csoil(:,:,end-119:end),3,'omitnan');% Average across the 51st to 60th years
            elseif size(Csoil,3)<1000 % it is annual data
                Csoil_before=mean(Csoil(:,:,1:10),3,'omitnan'); % Average across the 1st to 10th years
                Csoil_After=mean(Csoil(:,:,end-9:end),3,'omitnan');
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
            
            Csoil_before=Csoil_before*0; %we are making fake value because cLitter is not provided.
            Csoil_After=Csoil_After*0;
            
            Variable_to_read=Variable_list{Variable_to_read_num};
            
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
            
            [lon_num,lat_num,time_num]=size(Csoil);
            New_file_name=strcat('processed',filesep,Model_name,'_',Variable_to_read,'_fake_','INIT_MEAN.nc');
            fprintf('for model %s lon_num is %d and lat_num is %d and time is %d \n',Model_name,lon_num,lat_num,time_num)
            if exist(New_file_name,'file')==2
                delete(New_file_name)
            end
            nccreate(New_file_name,'lon','Dimensions',{'lon',lon_num},'Datatype','double')
            ncwrite(New_file_name,'lon',Lon);
            ncwriteatt(New_file_name,'lon','bnds','for bnds check TRENDYv11 S1 metadata');
            
            nccreate(New_file_name,'lat','Dimensions',{'lat',lat_num},'Datatype','double')
            ncwrite(New_file_name,'lat',Lat);
            
            
            nccreate(New_file_name,Variable_to_read,'Dimensions',{'lon',lon_num,'lat',lat_num},'Datatype','single');
            ncwrite(New_file_name,Variable_to_read,Csoil_before);
            ncwriteatt(New_file_name,Variable_to_read,'units','check TRENDYv11 S1 metadata');
            ncwriteatt(New_file_name,Variable_to_read,'Description','this is a mean value Average across the 24 25 26 27 28 29 30 31 32th years, CMIP5 esmfixclim1');
            
            %% write the second nc file
            
            New_file_name=strcat('processed',filesep,Model_name,'_',Variable_to_read,'_fake_','FINAL_MEAN.nc');
            fprintf('for model %s lon_num is %d and lat_num is %d and time is %d \n',Model_name,lon_num,lat_num,time_num)
            if exist(New_file_name,'file')==2
                delete(New_file_name)
            end
            nccreate(New_file_name,'lon','Dimensions',{'lon',lon_num},'Datatype','double')
            ncwrite(New_file_name,'lon',Lon);
            ncwriteatt(New_file_name,'lon','bnds','for bnds check TRENDYv11 S1 metadata');
            
            
            nccreate(New_file_name,'lat','Dimensions',{'lat',lat_num},'Datatype','double')
            ncwrite(New_file_name,'lat',Lat);
            
            nccreate(New_file_name,Variable_to_read,'Dimensions',{'lon',lon_num,'lat',lat_num},'Datatype','single');
            ncwrite(New_file_name,Variable_to_read,Csoil_After);
            ncwriteatt(New_file_name,Variable_to_read,'units','check TRENDYv11 S1 metadata');
            ncwriteatt(New_file_name,Variable_to_read,'Description','this is a mean value Average across the 74 75 76 77 78 79 80 81 82th years, CMIP5 esmfixclim1');
            
        end
        clear Csoil Csoil_After Csoil_before
        
    end
end

diary off
