classdef MyOverFeat < Features.GenericFeature
    
    properties
       
        InstallDir
        ComputMode
        
        NetModel
        WindowStride
        OutLayer

    end
    
    methods
        
        function obj = MyOverFeat(install_dir, mode, net_model, out_layer)
            
            obj = obj@Features.GenericFeature();
            
            if strcmp(net_model, 'large')
                obj.NetModel = '-l';
                obj.WindowStride = 36;
            elseif strcmp(net_model, 'small')
                obj.NetModel = '';
                obj.WindowStride = 32;
            else
                error('Invalid network type.');
            end
            
            if strcmp(out_layer, 'default')
                obj.OutLayer = '';
            else 
                obj.OutLayer = out_layer;
            end
            
            obj.InstallDir = install_dir;
            obj.ComputMode = mode;

        end
        
        function [feat, grid, im_size] = extract_image(obj, src, src_grid, im_size, mod_out, dst)
              
            if ~ischar(src)
                error('For OverFeat the input must be a character array representing an image path.');
            end

            [~, ~, src_ext] = fileparts(src);
            
            if strcmp(src_ext, '.txt')
                
                output_stream = dlmread(src, 'delimiter', ' ');

                feat_dim = output_stream(1,1);
                h = output_stream(2,1);
                w = output_stream(3,1);
                
                output_stream(1,:) = [];
                
            else
                
                if isempty(obj.OutLayer)
                    command = sprintf('%s/src/overfeat %s -f %s', obj.InstallDir, obj.NetModel, src);
                else
                    command = sprintf('%s/src/overfeat %s -L %s %s', obj.InstallDir, obj.NetModel, num2str(obj.OutLayer), src);
                end
                
                [status, output_stream] = system(command);

                if status~=0 || strcmp(output_stream, 'Segmentation fault (core dumped)')
                    error('Failed to extract OverFeat: probably the image is smaller than 231x231 (small net)');
                end
                
                output_stream = strsplit(output_stream);
                
                feat_dim = str2double(output_stream{1});
                h = str2double(output_stream{2});
                w = str2double(output_stream{3});
                
                output_stream(1:3) = [];
                output_stream(end) = [];
                
                output_stream = str2double(output_stream);
                
            end

            feat = zeros(feat_dim, h*w);
            grid = zeros(2, h*w);
            for ff=1:feat_dim
                for ii=1:h
                    for jj=1:w
                        feat(ff, (ii-1)*w + jj) = output_stream((ff-1)*w*h + (ii-1)*w + jj);
                        grid(1, (ii-1)*w + jj) = obj.WindowStride*(ii-1);
                        grid(2, (ii-1)*w + jj) = obj.WindowStride*(jj-1);
                    end
                end
            end
                
            % n*h*w floating point numbers (written in ascii) separated by spaces
            % number of features (n)
            % number of rows (h)
            % number of columns (w)
            %
            % the feature is the first dimension (so that to obtain the next feature, you must add w*h to your index)
            % followed by the row (to obtain the next row, add w to your index)
            % that means that if you want the features corresponding to the top-left window, you need to read pixels i*h*w for i=0..4095
            %
            % the output is going to be a 3D tensor
            % the first dimension correspond to the features
            % while dimensions 2 and 3 are spatial (y and x respectively)
            % the spatial dimension is reduced at each layer,
            % and, with the default network, using option -f,
            % the output has size nFeatures * h * w where
            %
            % for the small network,
            % nFeatures = 4096
            % h = ((H-11)/4 + 1)/8-6
            % w = ((W-11)/4 + 1)/8-6
            %
            % for the large network,
            % nFeatures = 4096
            % h = ((H-7)/2 + 1)/18-5
            % w = ((W-7)/2 + 1)/18-5
            %
            % if the input has size 3*H*W
            % each pixel in the feature map corresponds to a localized window in the input
            % with the small network, the windows are 231x231 pixels,
            % overlapping so that the i-th window begins at pixel 32*i,
            % while for the large network, the windows are 221x221,
            % and the i-th window begins at pixel 36*i.
            %

            feat_size = size(feat);
            grid_size = size(grid);
            
            if (strcmp(mod_out,'file') || strcmp(mod_out,'both'))
                
                [~, ~, dst_ext] = fileparts(dst);
                
                if strcmp(dst_ext,'.bin')
                    fid = fopen(dst, 'w', 'L');
                     if (fid==-1)
                       fprintf(2, 'Cannot open file: %s', dst);
                     end
                    % column major order (transpose before writing)
                    % format for Unix systems (i.e., L, big endian)
                    fwrite(fid, feat_size, 'double');
                    fwrite(fid, feat, 'double');
                    fwrite(fid, grid_size, 'double');
                    fwrite(fid, grid, 'double');
                    fclose(fid);
                    
                elseif strcmp(dst_ext,'.mat')
                    
                    save(dst,'feat', 'grid', 'feat_size', 'grid_size');
                    
                else
                    error('Error! Invalid extension.');
                end
                
            end
            
        end
        
    end

end

