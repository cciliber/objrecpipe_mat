

%%
% registry_train=cell(0);
% registry_test=cell(0);
% registry_dict=cell(0);
% 
% sift_registry_train=cell(0);
% sift_registry_test=cell(0);
% sift_registry_dict=cell(0);
% 
% 
% registry=load_registry('/home/icub/Experiments/registries/registry.txt');
% sift_registry=load_registry('/home/icub/Experiments/registries/sift_registry.txt');
% 
% cnt=0;
% test_init=200;
% test_end=400;
% demo_tag='demo1';
% for i=1:length(registry)
%    
%     %check if the demo has changed
%     if ~strcmp(demo_tag,registry{i}{3})
%         cnt=0;
%         demo_tag=registry{i}{3};
%     end
%     
%     if cnt<test_init
%         registry_train{end+1}=registry{i};
%         sift_registry_train{end+1}=sift_registry{i};
%     else
%        if cnt<test_end
%             registry_test{end+1}=registry{i}; 
%             sift_registry_test{end+1}=sift_registry{i}; 
%        else
%             registry_dict{end+1}=registry{i};
%             sift_registry_dict{end+1}=sift_registry{i};
%        end
%     end
%     cnt=cnt+1;
% end
% 
% 
% save_registry(registry_train,fullfile('/home/icub/Experiments/registries','registry_train.txt'));
% save_registry(registry_test,fullfile('/home/icub/Experiments/registries','registry_test.txt'));
% save_registry(registry_dict,fullfile('/home/icub/Experiments/registries','registry_dict.txt'));
% 
% save_registry(sift_registry_train,fullfile('/home/icub/Experiments/registries','sift_registry_train.txt'));
% save_registry(sift_registry_test,fullfile('/home/icub/Experiments/registries','sift_registry_test.txt'));
% save_registry(sift_registry_dict,fullfile('/home/icub/Experiments/registries','sift_registry_dict.txt'));


%%

registry_path='D:\IIT\CODICI\Groceries_experiments\registries\';

sift_registry_train=cell(0);
sift_registry_test=cell(0);
sift_registry_dict=cell(0);


registry=load_registry(fullfile(registry_path,'registry.txt'));
sift_registry=load_registry(fullfile(registry_path,'sift_registry.txt'));

cnt=0;
test_init=200;
test_end=400;
class_tag=registry{1}{1};
for i=1:length(registry)
   
    %check if the demo has changed
    if ~strcmp(class_tag,registry{i}{1})
        cnt=0;
        class_tag=registry{i}{1};
    end
    
    if cnt<test_init
        sift_registry_train{end+1}=sift_registry{i};
    else
       if cnt<test_end
            sift_registry_test{end+1}=sift_registry{i}; 
       else
            sift_registry_dict{end+1}=sift_registry{i};
       end
    end
    cnt=cnt+1;
end

save_registry(sift_registry_train,fullfile(registry_path,'sift_registry_train.txt'));
save_registry(sift_registry_test,fullfile(registry_path,'sift_registry_test.txt'));
save_registry(sift_registry_dict,fullfile(registry_path,'sift_registry_dict.txt'));

