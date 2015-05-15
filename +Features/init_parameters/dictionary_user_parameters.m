
function p=dictionary_user_parameters(img_folder_path,dictionaries_folder_path,prefix)

    if(nargin<2)
        error('Error! Not enough parameters!');
    end
    
    if(nargin<3)
        prefix='';
    end
    
    p=dictionary_creator_parameters(dictionaries_folder_path);
    p=change_folder_parameter(p,img_folder_path,prefix);
end

