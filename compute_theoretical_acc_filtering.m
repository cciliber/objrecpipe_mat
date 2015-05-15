
windows = [1:20 25:5:55];
fps = 11;

dt_frame = 1/fps; % sec
temporal_windows = (windows-1)*(dt_frame);
nwindows = length(windows);


w = 3; %12
 
p = zeros(size(a));
for k = (floor(w/2)+1):w
    p = p + nchoosek(w,k) * a.^k.*(1-a).^(w-k);
end