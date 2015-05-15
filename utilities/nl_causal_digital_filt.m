function out = nl_causal_digital_filt(in, w, fun, value)

nframes = length(in);

out = zeros(nframes,1);

for idx=1:nframes 
    if idx>(w-1)
        out(idx) = fun( in((idx-(w-1)):idx) );
    end
end

out(1:(w-1)) = value;

end