function root_path = init_machine(machine_tag)

if strcmp(machine_tag, 'server')
    
    FEATURES_DIR = '/home/icub/GiuliaP/objrecpipe_mat';
    root_path = '/DATA/DATASETS';
    
    run('/home/icub/Dev/GURLS/gurls/utils/gurls_install.m');
    
    curr_dir = pwd;
    cd([getenv('VLFEAT_ROOT') '/toolbox']);
    vl_setup;
    cd(curr_dir);
    clear curr_dir;
    
elseif strcmp (machine_tag, 'laptop_giulia_win')
    
    run('C:\Users\Giulia\REPOS\GURLS\gurls\utils\gurls_install.m');
    
    FEATURES_DIR = 'C:\Users\Giulia\REPOS\objrecpipe_mat';
    root_path = 'D:\DATASETS';
    
elseif strcmp (machine_tag, 'laptop_giulia_lin')
    
    FEATURES_DIR = '/home/giulia/REPOS/objrecpipe_mat';
    root_path = '/media/giulia/DATA/DATASETS';
    
    curr_dir = pwd;
    cd([getenv('VLFEAT_ROOT') '/toolbox']);
    vl_setup;
    cd(curr_dir);
    clear curr_dir;
    
    curr_dir=pwd;
    cd(getenv('CNS_ROOT'));
    cns_path;
    cd(curr_dir);
    clear curr_dir;
    addpath(genpath(fullfile(getenv('CNS_ROOT'), 'hmax')));

    run('/home/giulia/REPOS/GURLS/gurls/utils/gurls_install.m');
    
elseif strcmp (machine_tag, 'laptop_giulia_mac')
    
    FEATURES_DIR = '/Users/giulia/REPOS/objrecpipe_mat';
    root_path = '/Users/giulia/DATASETS';
    
    curr_dir = pwd;
    cd([getenv('VLFEAT_ROOT') '/toolbox']);
    vl_setup;
    cd(curr_dir);
    clear curr_dir;
   
    run('/Users/giulia/LIBRARIES/GURLS/gurls/utils/gurls_install.m');
    
end

addpath(genpath(FEATURES_DIR));

check_input_dir(root_path);
