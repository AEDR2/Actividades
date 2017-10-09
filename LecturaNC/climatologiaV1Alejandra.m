%% Calculo de la climatologia (2003-2016)
directorio='C:\Users\itil2\Desktop\AlejandraPerezMena\Actividades\LecturaNC'
% Lectura de los archivos.

% Recuperar la informaciòn general del archivo NC
yearsp=2003:2016;
mesp=1:12;
for i=1:length(yearsp)
    rutaT=['/media/satelites/PROCESSED/CUT_CIGOM_HITO/OC/TERRA/' num2str(yearsp(i))];
    rutaA=['/media/satelites/PROCESSED/CUT_CIGOM_HITO/OC/AQUA/' num2str(yearsp(i))];
    base=datenum(yearsp(i),1,1);
    for j=1:length(mesp)
        iddia=datenum(yearsp(i),mesp(j),1)-base+1:datenum(yearsp(i),mesp(j+1),-0)-base+1;
        for n=1:length(iddia)
            file_terra='/media/satelites/PROCESSED/CUT_CIGOM_HITO/OC/TERRA/2003/T2003001.L2_LAC_OC.nc';
            file_aqua='/media/satelites/PROCESSED/CUT_CIGOM_HITO/OC/AQUA/2003/A2003001.L2_LAC_OC.nc';
        end
    end
end

file_terra='/media/satelites/PROCESSED/CUT_CIGOM_HITO/OC/TERRA/2003/T2003001.L2_LAC_OC.nc';
file_aqua='/media/satelites/PROCESSED/CUT_CIGOM_HITO/OC/AQUA/2003/A2003001.L2_LAC_OC.nc';

% abrir el archivo
% alto nivel
% ncread
ncid_terra=netcdf.open(file_terra,'NOWRITE');
ncid_aqua=netcdf.open(file_aqua,'NOWRITE');
varid_T=netcdf.inqVarID(ncid_terra,'chlor_a');
varid_A=netcdf.inqVarID(ncid_aqua,'chlor_a');
% revisar las dimensiones
[~,~,dimT,~]=netcdf.inqVar(ncid_terra,varid_T);
[~,~,dimA,~]=netcdf.inqVar(ncid_aqua,varid_A);
if numel(dimT)~=numel(dimA)
    error('Las variables no tienen las misma dimensiones')
end
for i=1:numel(dimT)
    [~,dimlenT]=netcdf.inqDim(ncid_terra,dimT(i));
    [~,dimlenA]=netcdf.inqDim(ncid_aqua,dimA(i));
    if dimlenT~=dimlenA
        error(['La dimension: ' str2double(i) ' El numero de pixeles no es correcto'])
    end
end
% revisar la congruencia espacial de los datos
lon_T=netcdf.getVar(ncid_terra,netcdf.inqVarID(ncid_terra,'lon'));
lat_T=netcdf.getVar(ncid_terra,netcdf.inqVarID(ncid_terra,'lat'));
lon_A=netcdf.getVar(ncid_aqua,netcdf.inqVarID(ncid_aqua,'lon'));
lat_A=netcdf.getVar(ncid_aqua,netcdf.inqVarID(ncid_aqua,'lat'));
if ~all((lon_T-lon_A)==0)
    error('la georeferenciacion en lon no es correcta')
end
if ~all((lat_T-lat_A)==0)
    error('la georeferenciacion en lon no es correcta')
end


varid=netcdf.inqVarID(ncid_terra,'chlor_a');

dataT=netcdf.getVar(ncid_terra,varid);

netcdf.close(ncid_terra);
netcdf.close(ncid_aqua);