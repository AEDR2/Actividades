
%% Calculo de la climatologia (2003-2016)
%directorio='/media/satelites/PROCESSED/CUT_CIGOM_HITO/OC';
directorio='C:\Users\itil2\Desktop\AlejandraPerezMena\Actividades\LecturaNC';
directorioA = [directorio filesep 'AQUA'];
directorioT = [directorio filesep 'TERRA'];
postFijo = '.L2_LAC_OC.nc';
%matrices de anios, mes
anioInicio = 2003;
anioFin = 2003;
%generacion del cubo de datos
cubo = repmat(0, [anioFin-anioInicio+1 12 31*2]);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Lectura de los archivos por anio
for anio=anioInicio:anioFin
    auxA = [directorioA filesep  int2str(anio) filesep 'A' int2str(anio)];
    auxT = [directorioT filesep int2str(anio) filesep 'T' int2str(anio)];
    base=datenum(anio,1,1);%por cada mes del anio
    for mes = 1:1
        numDias = datenum(anio,mes+1,-0)-base+1;
        dia = 1;
       %for dia = datenum(anio,mes,1)-base+1: numDias
            archivoA = [auxA sprintf('%03d',dia) postFijo];
            archivoT = [auxT sprintf('%03d',dia) postFijo];
            %se abren los archivos
            try
                ncid_terra = netcdf.open(archivoA,'NOWRITE');
                ncid_aqua = netcdf.open(archivoT,'NOWRITE');
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%se verifica la integridad de los valores de los archivos
                varid_T=netcdf.inqVarID(ncid_terra,'chlor_a');
                varid_A=netcdf.inqVarID(ncid_aqua,'chlor_a');
                % revisar las dimensiones
                [~,~,dimT,~]=netcdf.inqVar(ncid_terra,varid_T);
                [~,~,dimA,~]=netcdf.inqVar(ncid_aqua,varid_A);
                if numel(dimT)~=numel(dimA)
                    error('Las variables no tienen las misma dimensiones');
                end
                for i=1:numel(dimT)
                    [~,dimlenT]=netcdf.inqDim(ncid_terra,dimT(i));
                    [~,dimlenA]=netcdf.inqDim(ncid_aqua,dimA(i));
                    if dimlenT~=dimlenA
                        error(' El numero de pixeles no es correcto');
                    end
                end
                % revisar la congruencia espacial de los datos
                lon_T=netcdf.getVar(ncid_terra,netcdf.inqVarID(ncid_terra,'lon'));
                lat_T=netcdf.getVar(ncid_terra,netcdf.inqVarID(ncid_terra,'lat'));
                lon_A=netcdf.getVar(ncid_aqua,netcdf.inqVarID(ncid_aqua,'lon'));
                lat_A=netcdf.getVar(ncid_aqua,netcdf.inqVarID(ncid_aqua,'lat'));
                if ~all((lon_T-lon_A)==0)
                    error('la georeferenciacion en lon no es correcta');
                end
                if ~all((lat_T-lat_A)==0)
                    error('la georeferenciacion en lon no es correcta');
                end
             
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%obtencion de promedios
                varid_T=netcdf.inqVarID(ncid_terra,'chlor_a');
                varid_A=netcdf.inqVarID(ncid_aqua,'chlor_a');
                % se obtienen los valores del dia        
                matT = netcdf.getVar(ncid_terra,varid_T);
                matA = netcdf.getVar(ncid_aqua,varid_A);
                %se dividen los datos en una matriz de celdas de 3x3
                [m,n] = size(matT);
                y = round(linspace(0,n,4));
                x = round(linspace(0, m, 4));
                A = mat2cell(matA,[x(2)-x(1),x(3)-x(2),x(4)-x(3)],[y(2)-y(1),y(3)-y(2),y(4)-y(3)]);
                T = mat2cell(matT,[x(2)-x(1),x(3)-x(2),x(4)-x(3)],[y(2)-y(1),y(3)-y(2),y(4)-y(3)]);
                
                [m,n] = size(A);
                %por cada una de las celdas se va a obtener la suma
                for i=1:m
                    for j=1:n
                        ax = sum(sum([A{m,n}]));
                        %se guarda el valor de aqua en el cubo
                        cubo(anioInicio - anio +1, mes, dia+dia-1) = cubo(anioInicio - anio +1, mes, dia+dia-1) + ax;
                        %se hace lo mismo con los datos del archivo terra
                        ax = sum(sum([T{m,n}]));
                        cubo(anioInicio - anio +1, mes, dia*2) = cubo(anioInicio - anio +1, mes, dia*2) + ax;
                    end
                end
            catch
                ['Error en el archivo: ', archivoA, ' y ',archivoT]
            end
        %end
    end
end

