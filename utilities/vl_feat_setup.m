function vl_feat_setup()

    curr_dir = pwd;
    cd([getenv('VLFEAT_ROOT') '/toolbox']);
    vl_setup;
    cd(curr_dir);
    clear curr_dir;