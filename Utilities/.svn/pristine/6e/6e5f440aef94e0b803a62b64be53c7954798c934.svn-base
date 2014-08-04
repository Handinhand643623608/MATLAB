function writeimg(filename, data, dtype, voxSize, dataSize)
%function writeimg(filename, data, dtype, voxSize, dataSize)
%filename is name with or whithout .hdr/img
%data is image data
%dtype is data type
%voxSize is voxel size
%dataSize is matrix size

if ~exist('dtype')
    dtype = 'int16';      
end
if ~exist('voxSize')
    voxSize = [3,3,20];      
end
if ~exist('dataSize')
    dataSize = size(data);
end
if max(size(dataSize))==2,
    dataSize=[dataSize,1];
end
%% 
if filename(end-3:end) == '.hdr'
    filename = filename(1:end-4);
elseif filename(end-3:end) == '.img'
    filename = filename(1:end-4);
end

%% .img
fid = fopen([filename,'.img'], 'w');
fwrite(fid, data, dtype);
fclose(fid);

switch dtype
    case 'double'
        dataType = 64;
        bitVox = 64;
    case 'int16'
        dataType = 4;
        bitVox = 4;
    case 'float'
        dataType = 16;
        bitVox = 16;
    case 'float32'
        dataType = 32;
        bitVox = 32;
    case 'uint8'
        dataType = 8;
        bitVox = 8;
    otherwise % need to add other decription
        error('unsupported data format now.');
end

%% .hdr
scale = 1;
fid = fopen([filename,'.hdr'], 'w');
fwrite(fid, zeros(1,348), 'uint8');
fseek(fid, 0, 'bof');
fwrite(fid, 348, 'int16');
fseek(fid, 32, 'bof');
fwrite(fid, 16384, 'int16');
fseek(fid, 38, 'bof');
fwrite(fid, 'r', 'char');
fseek(fid, 40, 'bof');
fwrite(fid, [4,dataSize,1], 'int16');
fseek(fid, 40+30, 'bof');
fwrite(fid, dataType, 'int16');
fseek(fid, 40+32, 'bof');
fwrite(fid, bitVox, 'int16');
fseek(fid, 40+36, 'bof');
fwrite(fid, [0,voxSize], 'float32');
fseek(fid, 40+72, 'bof');
fwrite(fid, scale, 'float');

if length(dataSize) == 4
    dataSize = dataSize(1:3);
end

if dataSize==[79 95 69]   % 'default''[2 2 2]'
    if voxSize(1)==2 & voxSize(2)==2 & voxSize(3)==2 
        origin = [40 57 26];
    else
        error ('invalid voxel size.');
    end
elseif dataSize==[53 63 46]   % 'default''[3 3 3]'
    if voxSize(1)==3 & voxSize(2)==3 & voxSize(3)==3 
        origin = [27 38 18];
    else
        error ('invalid voxel size.');
    end     
elseif dataSize==[91 109 91]  % 'template''[2 2 2]'
    if voxSize(1)==2 & voxSize(2)==2 & voxSize(3)==2 
        origin = [46 64 37];
    else
        error ('invalid voxel size.');
    end                     
elseif dataSize==[61 73 61]   % 'template' '[3 3 3]'
    if voxSize(1)==3 & voxSize(2)==3 & voxSize(3)==3 
        origin = [31 43 25];
    else
        error ('invalid voxel size.');
    end
elseif dataSize==[181 217 181]    % 'template' '[1 1 1]'
    if voxSize(1)==1 & voxSize(2)==1 & voxSize(3)==1 
        origin = [91 127 73];
    else
        error ('invalid voxel size.');
    end
elseif dataSize==[46 55 46]    % 'template' '[4 4 4]'
     if voxSize(1)==4 & voxSize(2)==4 & voxSize(3)==4 
        origin = [24 33 19];
     else
        error ('invalid voxel size.');
     end
elseif dataSize==[71 52 86]    % mice
     if voxSize(1)==1.5 & voxSize(2)==1.5 & voxSize(3)==1.5 
        origin = [37 22 62];
     else
        error ('invalid voxel size.');
     end
else
     origin = [0 0 0];
     %error('There are no appropriate template.');
end

fseek(fid, 148+105, 'bof');
fwrite(fid, [origin,0,0], 'int16');
fclose(fid);