function [locs, descriptors] = extractSIFT(Images, dense, normalize, useLowe,loadImages)
    stepSift=8;
    sizeSift=16;
    
    if(nargin==1)
        dense=1;
        normalize=1;
        useLowe=0;
    end
    if(nargin==3)
        useLowe=0;
    end
    
    if(nargin<5)
        loadImages=0;
    end

    descriptors=cell(size(Images,1),1);
    locs=cell(size(Images,1),1);

    for i=1:size(Images,1)

       locs{i}=cell(size(Images{i},1),1);
       descriptors{i}=cell(size(Images{i},1),1);
       for j=1:size(Images{i},1)
          img=Images{i}{j};
          if(loadImages)
              img=imread(img);
          end
          d=size(img);
          if(useLowe==0)
              if(size(d,2)==3)
                  I=single(rgb2gray(img));     
              else
                  I=single(img);
              end
              if(dense)
                 [f,d] = vl_dsift(I, 'Step', stepSift, 'Size', sizeSift, 'FloatDescriptors');
              else
                 [f,d] = vl_sift(I,'FloatDescriptors');
              end
              if(normalize)
                  for k=1:size(d,2)
                      factor=norm(d(:,k));
                      if(factor>0)
                        d(:,k)=d(:,k)/factor;
                      end
                      d(d(:,k)>0.2,k)=0.2;
                      factor=norm(d(:,k));
                      if(factor>0)
                        d(:,k)=d(:,k)/factor;      
                      end
                  end
              end
          else
              if(size(d,2)==3)
                  I=(rgb2gray(img));     
              else
                  I=(img);
              end 
              convG=fspecial('gaussian');
              I=imfilter(I,convG,'replicate');
              [I d f]=sift(I);
              d=d';
              f=f';
              tmp=f(1:2,:);
              f(1,:)=tmp(2,:);
              f(2,:)=tmp(1,:);           
          end
          locs{i}{j}=f;   
          descriptors{i}{j}=d;      
        j   
       end    
       i

    end

end