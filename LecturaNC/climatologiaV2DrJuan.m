global ncid
try
    netcdf.close(ncid)
catch
end
%% Calculo de la climatologia (2003-2016)
%directorio='/media/satelites/PROCESSED/CUT_CIGOM_HITO/OC';
directorio='C:\Users\itil2\Desktop\AlejandraPerezMena\Actividades\LecturaNC';
directorioA = [directorio filesep 'AQUA'];
directorioT = [directorio filesep 'TERRA'];
postFijo = '.L2_LAC_OC.nc';
%matrices de anios, mes
anioInicio = 2003;
anioFin = 2003;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Lectura de los archivos por anio
for anio=anioInicio:anioFin
    base = datenum(anio,1,1);%por cada mes del anio
    %Se va a abrir un archivo para obtener su informacion
    archivoA = [directorioA filesep  int2str(anio) filesep 'A' int2str(anio) sprintf('%03d',1) postFijo];
    ncid_aqua = netcdf.open(archivoA,'NOWRITE');
    varid_A=netcdf.inqVarID(ncid_aqua,'chlor_a');
    [~,~,dimA,~]=netcdf.inqVar(ncid_aqua,varid_A);
    %Se obtendran los nombres de las variables que se van a guardar en el
    %archivo nc
    [~,dimA_]=sort(dimA);
    dimlenA=zeros(size(dimA));
    dimlen_name=cell(size(dimA));
    for i=1:numel(dimA)
        [dimlen_name{i},dimlenA(i)]=netcdf.inqDim(ncid_aqua,dimA(dimA_(i)));
    end
    variables=struct('varname',{},'xtype',{},'dimids',{},'natts',{});
    idlon=netcdf.inqVarID(ncid_aqua,'lon');
    idlat=netcdf.inqVarID(ncid_aqua,'lat');
    [variables(1).varname,variables(1).xtype,variables(1).dimids,variables(1).natts]=netcdf.inqVar(ncid_aqua,idlon);
    [variables(2).varname,variables(2).xtype,variables(2).dimids,variables(2).natts]=netcdf.inqVar(ncid_aqua,idlat);
    [variables(3).varname,variables(3).xtype,variables(3).dimids,variables(3).natts]=netcdf.inqVar(ncid_aqua,varid_A);
    lon_master=netcdf.getVar(ncid_aqua,idlon);
    lat_master=netcdf.getVar(ncid_aqua,idlat);    
     netcdf.close(ncid_aqua);
    y = round(linspace(0,dimlenA(1),4));
    x = round(linspace(0, dimlenA(2), 4));
    cuantosx=diff(x);
    cuantosy=diff(y);
    if sum(cuantosx)~=dimlenA(2)
        keyboard
    end
    if sum(cuantosy)~=dimlenA(1)
        keyboard
    end
    [X,Y]=meshgrid(x(1:end-1),y(1:end-1));
    [cuantosX,cuantosY]=meshgrid(cuantosx,cuantosy);
       
    for mes = 1:12
        %['mes' int2str(mes)]
        numDias = datenum(anio,mes+1,-0)-base+1;
        %% creo el archivo nc de la climatorogia del mes "mes"
        % creo la estructura del archivo
        archivoclima=fullfile(directorio,'CLIMATOLOGIA',[sprintf('mes%02d',mes) '.nc']);
        if exist(archivoclima,'file')==2
            delete(archivoclima);
        end
        ncid=netcdf.create(archivoclima,'NETCDF4');
        % definir las dimensiones        
        for i=1:length(dimlenA)
            netcdf.defDim(ncid,dimlen_name{i},dimlenA(i));
        end
        % defino las variables
        for i=1:length(variables)
            netcdf.defVar(ncid,variables(i).varname,variables(i).xtype,variables(i).dimids);
        end        
        
        netcdf.endDef(ncid);
        netcdf.close(ncid);
        ncid_clima=netcdf.open(archivoclima,'WRITE');
        netcdf.putVar(ncid_clima,netcdf.inqVarID(ncid_clima,'lon'),lon_master);
        netcdf.putVar(ncid_clima,netcdf.inqVarID(ncid_clima,'lat'),lat_master);
        id_clorofila=netcdf.inqVarID(ncid_clima,'chlor_a');
        for ii=1:9
            %['modulo:' int2str(ii)]
            cubo = nan(cuantosX(ii),cuantosY(ii),numDias*2);
            cuentadia=1;
            for dia=1:numDias
                %['dia' int2str(dia)]
                archivoA = [directorioT filesep int2str(anio) filesep 'T' int2str(anio) sprintf('%03d',dia) postFijo];
                archivoT = [directorioT filesep int2str(anio) filesep 'T' int2str(anio) sprintf('%03d',dia) postFijo];
                try
                    ncid_aqua = netcdf.open(archivoA,'NOWRITE');
                catch
                    ncid_aqua=0;
                end
                try
                    ncid_terra = netcdf.open(archivoT,'NOWRITE');
                catch
                    ncid_terra=0;
                end
                if ncid_terra
                    varid_T=netcdf.inqVarID(ncid_terra,'chlor_a');
                    [~,~,dimT,~]=netcdf.inqVar(ncid_terra,varid_T);
                    dimT=sort(dimT);
                    for i=1:numel(dimT)
                        [~,dummy]=netcdf.inqDim(ncid_terra,dimT(i));
                        if dimlenA(i)~=dummy
                            error(' El numero de pixeles no es correcto');
                        end
                    end
                    lon_T=netcdf.getVar(ncid_terra,netcdf.inqVarID(ncid_terra,'lon'));
                    lat_T=netcdf.getVar(ncid_terra,netcdf.inqVarID(ncid_terra,'lat'));
                    if ~all((lon_T-lon_master)==0)
                        error('la georeferenciacion en lon no es correcta');
                    end
                    if ~all((lat_T-lat_master)==0)
                        error('la georeferenciacion en lon no es correcta');
                    end
                    matT = netcdf.getVar(ncid_terra,varid_T,[X(ii) Y(ii)],[cuantosX(ii),cuantosY(ii)]);
                    matT(matT==0)=nan;
                else
                    matT = nan(cuantosX(ii),cuantosY(ii));
                end
                if ncid_aqua
                    varid_A=netcdf.inqVarID(ncid_aqua,'chlor_a');
                    [~,~,dimA,~]=netcdf.inqVar(ncid_aqua,varid_A);
                    dimA=sort(dimA);
                    for i=1:numel(dimT)
                        [~,dummy]=netcdf.inqDim(ncid_aqua,dimA(i));
                        if dimlenA(i)~=dummy
                            error(' El numero de pixeles no es correcto');
                        end
                    end
                    lon_A=netcdf.getVar(ncid_aqua,netcdf.inqVarID(ncid_aqua,'lon'));
                    lat_A=netcdf.getVar(ncid_aqua,netcdf.inqVarID(ncid_aqua,'lat'));
                    if ~all((lon_master-lon_A)==0)
                        error('la georeferenciacion en lon no es correcta');
                    end
                    if ~all((lat_master-lat_A)==0)
                        error('la georeferenciacion en lon no es correcta');
                    end
                    matA = netcdf.getVar(ncid_aqua,varid_A,[X(ii) Y(ii)],[cuantosX(ii),cuantosY(ii)]);
                    matA(matA==0)=nan;
                else
                    matA = nan(cuantosX(ii),cuantosY(ii));
                end
                cubo(:,:,cuentadia)=matT;
                cuentadia=cuentadia+1;
                cubo(:,:,cuentadia)=matA;
                cuentadia=cuentadia+1;
                if ncid_aqua
                    netcdf.close(ncid_aqua);
                end
                if ncid_terra
                    netcdf.close(ncid_terra);
                end
            end
            clima=nanmean(cubo,3);
            %% Guardar los resultados en un archivo nc
            netcdf.putVar(ncid_clima,id_clorofila,[X(ii) Y(ii) ],[cuantosX(ii),cuantosY(ii)],clima);
        end        
        netcdf.close(ncid_clima);
    end 
end