
function p=set_dictionary_folder_parameters(p,dictionaries_folder_path)
    if nargin<1
        error('Error! not enough parameters!');
    end
    
    if(dictionaries_folder_path(1,end)~='/' && dictionaries_folder_path(1,end)~='\')
        dictionaries_folder_path(1,end+1)='/';
    end    

    p.bow.dictionary_path=[dictionaries_folder_path 'bow_dictionary.txt'];
    p.sc.dictionary_path=[dictionaries_folder_path 'sc_dictionary.txt'];
    p.hmax.dictionary_path=[dictionaries_folder_path 'hmax_dictionary.txt'];
end