classdef MyBOW < Features.GenericFeature
    
    properties   
    end
    
    methods
        
        function obj = MyBOW(path, extension)
             
        end
        
        function descriptors = extract_image(obj, modality, src, dst)
          
            if (strcmp(modality,'file_file') || strcmp(modality,'file_wspace') || strcmp(modality,'file_both'))
                % load src
            elseif(strcmp(modality,'wspace_file') || strcmp(modality,'wspace_wspace') || strcmp(modality,'wspace_both'))
                % use src
            end
            
            % ...
            
            descriptors = descriptors';
            if (strcmp(modality,'file_file') || strcmp(modality,'wspace_file') || strcmp(modality,'file_both') || strcmp(modality,'wspace_both'))
                save(dst,'descriptors');     
            end
        end
   
        function init()
            
%             p.bow.dictionary_size=256;
%             p.bow.dictionary_path='/home/icub/Experiments/dictionaries/kmeans.dict';
%             p.bow.n_rand_features=2*1e5;
%             
%             p.bow.img_w=160;
%             p.bow.img_h=160;
%             
%             
%             if(p.mode=='robot')
%                 p.bow.img_w=320;
%                 p.bow.img_h=320;
%             end
%             
%             
%             p.bow.pyramid=[1 2 4];
%             
%             %for the locations
%             gridSpacing= p.sift.step;
%             patchSize=p.sift.scale;
%             
%             remX = mod(p.bow.img_w-patchSize,gridSpacing);
%             offsetX = floor(remX/2)+1;
%             remY = mod(p.bow.img_h-patchSize,gridSpacing);
%             offsetY = floor(remY/2)+1;
%             
%             [gridX,gridY] = meshgrid(offsetX:gridSpacing:p.bow.img_w-patchSize+1, offsetY:gridSpacing:p.bow.img_h-patchSize+1);
%             
%             locx=gridX(:) + patchSize/2 - 0.5;
%             locy=gridY(:) + patchSize/2 - 0.5;
%             p.bow.locs=[locx locy]';
        end

        function p=dict_bow(p)
            
            %if asked to ignore... ignore
            if(isfield(p,'ignore_sift') || isfield(p,'ignore_bow'))
                return;
            end
            
            %subsample the descriptors that will be used to learn the dictionary
            tmp_desc = vl_colsubset(p.sift.desc,p.bow.n_rand_features);
            
            %dictionarize!
            p.bow.dictionary = vl_kmeans(tmp_desc,p.bow.dictionary_size, 'verbose', 'algorithm', 'elkan');
            
            %save the dictionary
            dictionary=p.bow.dictionary;
            save(p.bow.dictionary_path,'dictionary');
            
            clear tmp_dsc;
        end
        
        function beta=code_bow(p)
            
            dictionary=p.dictionary;
            dSize = size(dictionary, 2);
            descriptors=p.feaArr;
            pyramid=p.pyramid;
            locs=p.locs;
            img_w=p.img_w;
            img_h=p.img_h;
            
            codes=zeros(size(dictionary,2),size(descriptors,2));
            
            distances=vl_alldist2(descriptors,dictionary);
            
            [~,idxs]=min(distances,[],2);
            
            for i=1:size(descriptors,2)
                codes(idxs(i),i)=1;
            end
            
            pLevels = length(pyramid);
            % spatial bins on each level
            pBins = pyramid.^2;
            % total spatial bins
            tBins = sum(pBins);
            
            beta = zeros(dSize, tBins);
            bId = 0;
            
            for iter1 = 1:pLevels,
                
                nBins = pBins(iter1);
                
                wUnit = img_w / pyramid(iter1);
                hUnit = img_h / pyramid(iter1);
                
                % find to which spatial bin each local descriptor belongs
                xBin = ceil(locs(1,:) / wUnit);
                yBin = ceil(locs(2,:) / hUnit);
                idxBin = (yBin - 1)*pyramid(iter1) + xBin;
                
                for iter2 = 1:nBins,
                    bId = bId + 1;
                    sidxBin = find(idxBin == iter2);
                    if isempty(sidxBin),
                        continue;
                    end
                    beta(:, bId) = mean(codes(:,sidxBin),2);
                end
            end
            
            
            beta = beta(:);
            beta = beta./sqrt(sum(beta.^2));
        end
        
        function p=code_bow_dataset(p)
            
            %if asked to ignore... ignore.
            if(isfield(p,'ignore_sift') || isfield(p,'ignore_bow'))
                return;
            end
            
            l=load(p.bow.dictionary_path,'-mat');
            p.bow.dictionary=l.dictionary;
            
            n_samples=length(p.sift.registry);
            
            %create the empty matrix for the coded vectors
            %spatial bins on each level
            pBins = p.bow.pyramid.^2;
            % total spatial bins
            tBins = sum(pBins);
            p.bow.codes=zeros(size(p.bow.dictionary,2)*tBins,n_samples);
            
            fprintf('Bag of Words\n');
            fprintf('0%%              100%%\n');
            percent_module=uint32(n_samples/20);
            for idx_sample = 1 : n_samples
                
                if mod(idx_sample-1,percent_module)==0
                    fprintf('*');
                end
                
                %set the temporary descriptor in the parameter structure
                l=load(p.sift.registry{idx_sample}{end});
                p.bow.feaArr=l.tmp_descriptors;
                
                p.bow.codes(:,idx_sample)=code_bow(p.bow);
            end
            fprintf('\n\n');
            
            codes=p.bow.codes;
            save(p.bow.codes_path,'codes','-v7.3');
        end
        
    end
    
end

