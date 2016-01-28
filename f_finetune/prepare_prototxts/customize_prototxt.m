function customize_prototxt(template_path, params, dst_path)

    text_network = fileread(template_path);
    
    fid = fopen(dst_path,'w');
    
    
    fprintf(fid,text_network, params{:});
    
    fclose(fid);

end


