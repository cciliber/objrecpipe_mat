function cns_setup()

 curr_dir=pwd;
    cd(getenv('CNS_ROOT'));
    cns_path;
    cd(curr_dir);
    clear curr_dir;
    addpath(genpath(fullfile(getenv('CNS_ROOT'), 'hmax')));