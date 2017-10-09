
%% Calculo de la climatologia (2003-2016)
directorio='/media/satelites/PROCESSED/CUT_CIGOM_HITO/OC';
%directorio='C:\Users\itil2\Desktop\AlejandraPerezMena\Actividades\LecturaNC';
directorioA = [directorio filesep 'AQUA'];
directorioT = [directorio filesep 'TERRA'];
postFijo = '.L2_LAC_OC.nc';
%matrices de anios, mes
anioInicio = 2003;
anioFin = 2003;
%generacion del cubo de datos
numyear=anioFin-anioInicio+1;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Lectura de los archivos por anio
primer=true;
for mes = 1:12
    crear=true;
    disp(['Procesando el mes: ' num2str(mes)])
    for ii=1:9
        cuentadia=1;
        crearcubo=true;
        disp(['Procesando parte: ' num2str(ii) '/9...'])
        for anio=anioInicio:anioFin
            auxA = [directorioA filesep  int2str(anio) filesep 'A' int2str(anio)];
            auxT = [directorioT filesep int2str(anio) filesep 'T' int2str(anio)];
            base=datenum(anio,1,1);%por cada mes del anio
            if primer
                archivoA = [auxA sprintf('%03d',1) postFijo];
                ncid_terra = netcdf.open(archivoA,'NOWRITE');
                varid_T=netcdf.inqVarID(ncid_terra,'chlor_a');
                [~,~,dimT,~]=netcdf.inqVar(ncid_terra,varid_T);
                dimT=sort(dimT);
                dimlenT=zeros(size(dimT));
                dimlen_name=cell(size(dimT));
                for i=1:numel(dimT)
                    [dimlen_name{i},dimlenT(i)]=netcdf.inqDim(ncid_terra,dimT(i));
                end
                variables=struct('varname',{},'xtype',{},'dimids',{},'natts',{});
                idlon=netcdf.inqVarID(ncid_terra,'lon');
                idlat=netcdf.inqVarID(ncid_terra,'lat');
                [variables(1).varname,variables(1).xtype,variables(1).dimids,variables(1).natts]=netcdf.inqVar(ncid_terra,idlon);
                [variables(2).varname,variables(2).xtype,variables(2).dimids,variables(2).natts]=netcdf.inqVar(ncid_terra,idlat);
                [variables(3).varname,variables(3).xtype,variables(3).dimids,variables(3).natts]=netcdf.inqVar(ncid_terra,varid_T);
                variables(end+1)=variables(3);
                variables(end).varname='cuantos';
                lon_master=netcdf.getVar(ncid_terra,idlon);
                lat_master=netcdf.getVar(ncid_terra,idlat);
                y = round(linspace(0,dimlenT(1),4));
                x = round(linspace(0, dimlenT(2), 4));
                cuantosx=diff(x);
                cuantosy=diff(y);
                if sum(cuantosx)~=dimlenT(2)
                    keyboard
                end
                if sum(cuantosy)~=dimlenT(1)
                    keyboard
                end
                [X,Y]=meshgrid(x(1:end-1),y(1:end-1));
                [cuantosX,cuantosY]=meshgrid(cuantosx,cuantosy);
                netcdf.close(ncid_terra);
                primer=false;
            end
            numDias = (datenum(anio,mes+1,-0)-base+1)-(datenum(anio,mes,1)-base+1)+1;
            
            %% creo el archivo nc de la climatorogia del mes "mes"
            % creo la estructura
            if crear
                archivoclima=fullfile(directorio,'CLIMATOLOGIA',[sprintf('mes%02d',mes) '.nc']);
                if exist(archivoclima,'file')==2
                    delete(archivoclima)
                end
                ncid=netcdf.create(archivoclima,'NETCDF4');
                % definir mis dimensiones
                for i=1:length(dimlenT)
                    netcdf.defDim(ncid,dimlen_name{i},dimlenT(i));
                end
                % defino mis variables
                for i=1:length(variables)
                    netcdf.defVar(ncid,variables(i).varname,variables(i).xtype,variables(i).dimids);
                end
                
                netcdf.endDef(ncid)
                netcdf.close(ncid)
                ncid_clima=netcdf.open(archivoclima,'WRITE');
                netcdf.putVar(ncid_clima,netcdf.inqVarID(ncid_clima,'lon'),lon_master)
                netcdf.putVar(ncid_clima,netcdf.inqVarID(ncid_clima,'lat'),lat_master)
                id_clorofila=netcdf.inqVarID(ncid_clima,'chlor_a');
                crear=false;
            end
            
            if crearcubo
                cubo = nan(cuantosX(ii),cuantosY(ii),numDias*2*numyear); 
                crearcubo=false;
            end
            
            for dia = datenum(anio,mes,1)-base+1:datenum(anio,mes+1,-0)-base+1;
                archivoA = [auxA sprintf('%03d',dia) postFijo];
                archivoT = [auxT sprintf('%03d',dia) postFijo];
                try
                    ncid_terra = netcdf.open(archivoA,'NOWRITE');
                catch
                    ncid_terra=0;
                end
                try
                    ncid_aqua = netcdf.open(archivoT,'NOWRITE');
                catch
                    ncid_aqua=0;
                end
                if ncid_terra
                    varid_T=netcdf.inqVarID(ncid_terra,'chlor_a');
                    [~,~,dimT,~]=netcdf.inqVar(ncid_terra,varid_T);
                    dimT=sort(dimT);
                    for i=1:numel(dimT)
                        [~,dummy]=netcdf.inqDim(ncid_terra,dimT(i));
                        if dimlenT(i)~=dummy
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
                        if dimlenT(i)~=dummy
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
            
        end
        cubo1=reshape(cubo,size(cubo,1)*size(cubo,2),size(cubo,3));
        dummy=prctile(cubo1,[3 97]);
        cubo1(cubo1<repmat(dummy(1,:),size(cubo1,1),1)|cubo1>repmat(dummy(2,:),size(cubo1,1),1))=nan;
        clima=reshape(nanmean(cubo1,2),size(cubo,1),size(cubo,2));        
        %% Guardar los resultados en un archivo nc
        if any(clima(:)<0)
            keyboard
        end
        netcdf.putVar(ncid_clima,id_clorofila,[X(ii) Y(ii)],[cuantosX(ii),cuantosY(ii)],clima);
        netcdf.putVar(ncid_clima,3,[X(ii) Y(ii)],[cuantosX(ii),cuantosY(ii)],reshape(sum(~isnan(cubo1),2),size(cubo,1),size(cubo,2)));
    end
    netcdf.close(ncid_clima)
end

