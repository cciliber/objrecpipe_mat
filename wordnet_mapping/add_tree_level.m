function r = add_tree_level(x)

if isempty(x)
    r = 0;
else
    r = max(x) + 1;
end