function linecount = get_linecount(f)

[status, cmdout] = system(sprintf ('wc -l %s', f));

if status==0
    scancell = textscan(cmdout,'%u %s');
    linecount = scancell{1}; 
else 
    fprintf(1,'Failed to find line count of %s\n',f);
    linecount = -1;
end