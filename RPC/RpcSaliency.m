%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% Jing Lou, Mingwu Ren, Huan Wang, "Regional Principal Color Based Saliency Detection," PLoS ONE, 
% vol. 9, no. 11, pp. e112475: 1-13, 2014. doi:10.1371/journal.pone.0112475
% 
% Project page: http://www.loujing.com/rpc-saliency/
% 
% Copyright (C) 2016 Jing Lou
% 
% Date: Jul 31, 2016
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [GloSalMap, RegSalMap] = RpcSaliency(rgb, params)
% Output:
% 	GloSalMap: Global saliency map
% 	RegSalMap: Regional saliency map

[Height, Width, ~] = size(rgb);

%% Minimum variance quantization [Subsection 'Global Color Saliency', pp.2]
[X, map] = rgb2ind(rgb, params.qnums, 'nodither');
RGB_Quan = ind2rgb(X, map);

%% Color histogram [Subsection 'Global Color Saliency', pp.3]
rgb_quan_colormap = reshape(RGB_Quan, Height*Width, 3);
[Colormap,~,RGB_Quan_Idx] = unique(rgb_quan_colormap, 'rows');
ColormapIdx = (1:size(Colormap,1))';
ColormapCount = accumarray(RGB_Quan_Idx,1);
[ColormapCountSort, ColormapIdxSort] = sort(ColormapCount,1,'descend');

%% Abandon infrequently occurring colors [Subsection 'Global Color Saliency', pp.3]
tmpsum = 0;
for m = 1:size(ColormapCountSort)
	tmpsum = tmpsum + ColormapCountSort(m);
	if tmpsum > Height*Width * params.alpha
		break;
	end
end
reserved = m; % the number of high frequently occurring colors
if reserved == 1
	GloSalMap = zeros(Height,Width);
	RegSalMap = zeros(Height,Width);
	return;
end

ColormapIdxReserved = ColormapIdxSort(1:reserved);
ColormapReserved = Colormap(ColormapIdxReserved,:);
% replace infrequently occurring colors by the most similar colors in the color histogram[Subsection 'Global Color Saliency', pp.3]
ColormapIdxCombine = [ColormapIdx, ColormapIdx];
for m = 1:length(ColormapIdx)
	if isempty(find(ColormapIdxCombine(m,1)==ColormapIdxReserved, 1))
		ColormapIdxCombine(m,2) = 0;
	end
end
tmpNonZeroIdx = find(ColormapIdxCombine(:,2)~=0);
tmpZeroIdx = find(ColormapIdxCombine(:,2)==0);
% measure in Lab color space [Subsection 'Global Color Saliency', pp.3, Eq.(1)]
tmpcolormap = im2double(Colormap);
for m = 1:length(tmpZeroIdx)
	midx = tmpZeroIdx(m);
	[ml,ma,mb] = RGB2Lab(tmpcolormap(midx,1),tmpcolormap(midx,2),tmpcolormap(midx,3));
	tmpdist = inf;
	maxidx = 0;
	for n = 1:length(tmpNonZeroIdx)
		nidx = tmpNonZeroIdx(n);
		[nl,na,nb] = RGB2Lab(tmpcolormap(nidx,1),tmpcolormap(nidx,2),tmpcolormap(nidx,3));
		tmpnorm = norm([ml,ma,mb]-[nl,na,nb], 2);
		if tmpnorm < tmpdist
			tmpdist = tmpnorm;
			maxidx = tmpNonZeroIdx(n);
		end
	end
	if maxidx~=0
		ColormapIdxCombine(tmpZeroIdx(m),2) = maxidx;
	end
end
% recompute ColormapCount and ColormapSort
RGB_Quan_Idx_Combine = RGB_Quan_Idx;
for m = 1:Height*Width
	RGB_Quan_Idx_Combine(m) = ColormapIdxCombine(RGB_Quan_Idx(m),2);
end
ColormapCountCombine = accumarray(RGB_Quan_Idx_Combine,1);
[ColormapCountSortCombine, ~] = sort(ColormapCountCombine,1,'descend');
ColormapCountSortCombine = ColormapCountSortCombine(1:length(ColormapIdxReserved));

%% Recompute the distance between two high frequent colors in Lab color space
tmplen = length(ColormapIdxReserved);
tmpcolormap = im2double(ColormapReserved);
ColormapReservedDist = zeros(tmplen);
for m = 1:tmplen
	[ml,ma,mb] = RGB2Lab(tmpcolormap(m,1),tmpcolormap(m,2),tmpcolormap(m,3));
	for n = 1:tmplen
		[nl,na,nb] = RGB2Lab(tmpcolormap(n,1),tmpcolormap(n,2),tmpcolormap(n,3));
		ColormapReservedDist(m,n) = norm([ml,ma,mb]-[nl,na,nb], 2);
	end
end

%% Global color saliency [Subsection 'Global Color Saliency', pp.3, Eq.(2)]
tmplen = length(ColormapIdxReserved);
ColormapReservedSaliency = zeros(tmplen,1);
for m = 1:tmplen
	for n = 1:tmplen
		ColormapReservedSaliency(m,1) = ColormapReservedSaliency(m,1) + ColormapReservedDist(m,n)*ColormapCountSortCombine(n);
	end
end

%% Color space smoothing [Subsection 'Global Color Saliency', pp.4, Eq.(3)]
tmplen = length(ColormapIdxReserved);
[ColormapReservedDistSort, ColormapReservedDistSortIdx] = sort(ColormapReservedDist, 2, 'ascend');
tmpcnt = uint32(ceil(length(ColormapIdxReserved) * params.delta));
if tmpcnt == 1
	tmpcnt = 2;
end
T = zeros(tmplen,1);
for m = 1:tmplen
	T(m) = sum(ColormapReservedDistSort(m,1:tmpcnt));
end
ColormapReservedSaliencySmooth = zeros(tmplen,1);
for m = 1:tmplen
	tmpsum = 0;
	for n = 1:tmpcnt
		tmpsum = tmpsum + (T(m)-ColormapReservedDistSort(m,n))*ColormapReservedSaliency(ColormapReservedDistSortIdx(m,n));
	end
	ColormapReservedSaliencySmooth(m) = tmpsum/double(tmpcnt-1)/T(m);
end
% normalization
ColormapReservedSaliencySmooth = mapminmax(ColormapReservedSaliencySmooth',0,1);
%* Global saliency map
GloSalMap = zeros(Height,Width);
for m = 1:Height*Width
	tmpidx = RGB_Quan_Idx_Combine(m);
	GloSalMap(m) = ColormapReservedSaliencySmooth(ColormapIdxReserved==tmpidx);
end

%% Graph-based segmentation [Subsection 'Regional Principal Color Saliency', pp.4]
graphsig = 0.5;	% Used to smooth the input image before segmenting it
k = 50;				% Value for the threshold function
minsize = 50;		% Minimum component size enforced by post-processing
imwrite(RGB_Quan, 's.ppm');
system(['segment.exe ', int2str(graphsig), ' ', int2str(k), ' ', int2str(minsize), ' s.ppm r.ppm']);
tmprgbseg = imread('r.ppm');
tmpcolormap = reshape(tmprgbseg, Height*Width, 3);
[~,~,SegImg_Label] = unique(tmpcolormap, 'rows');
clear segsigma k minsize tmprgbseg tmpcolormap;
SegImg_Label = reshape(SegImg_Label, Height,Width);
[SegLabel,~,~]= unique(SegImg_Label);

%% Regional principal color saliency [Subsection 'Regional Principal Color Saliency', pp.4]
regionlen = length(SegLabel);
Region = struct([]);
for m = 1:regionlen
	Region(m).Label = SegLabel(m);
	tmpidx = find(SegImg_Label==Region(m).Label);
	Region(m).Count = length(tmpidx);
	[subx,suby] = ind2sub([Height,Width], tmpidx);
	Region(m).Sub = [subx,suby];
	% regional center
	Region(m).Center(2) = mean(subx);
	Region(m).Center(1) = mean(suby);
	% spatial distance between regional center and image center
	Region(m).ToCenterDist = norm([Width/2,Height/2]-Region(m).Center,2);
	Region(m).ColormapIdx = RGB_Quan_Idx_Combine(tmpidx);
	% regional principal color
	tmpColormapIdx = Region(m).ColormapIdx;
	[uniColormap,~,uniColormapIdx] = unique(tmpColormapIdx);
	uniColormapIdxCount = accumarray(uniColormapIdx,1);
	[sortColormapIdxCount,sortColormapIdxCountIdx] = sort(uniColormapIdxCount,1,'descend');
	Region(m).MainColorIdx = uniColormap(sortColormapIdxCountIdx(1));
	Region(m).MainColorCount = sortColormapIdxCount(1);
	Region(m).Saliency = ColormapReservedSaliencySmooth(ColormapIdxReserved==Region(m).MainColorIdx);
end
% normalization
tmpSaliency = [Region(:).Saliency];
tmpSaliency = mapminmax(tmpSaliency(:)',0,1);
for m = 1:regionlen
	Region(m).Saliency = tmpSaliency(m);
end

%% Spatial Relationships [Subsection 'Spatial Relationships', pp.5]
% spatial distance between two regions
RegionDist = zeros(regionlen);
for m = 1:regionlen
	for n = 1:regionlen
		RegionDist(m,n) = norm(Region(m).Center-Region(n).Center,2);
	end
end
RegionDist = reshape(mapminmax(RegionDist(:)',0,1),regionlen,regionlen);
% spatial distance between regional center and image center
tmpDist = [Region(:).ToCenterDist];
tmpDist = mapminmax(tmpDist(:)',0,1);
for m = 1:regionlen
	Region(m).ToCenterDist = tmpDist(m);
end
% [Subsection 'Spatial Relationships', pp.5, Eq.(5)]
RegionSaliencyContr = zeros(regionlen);
for m = 1:regionlen
	for n = 1:regionlen
		RegionSaliencyContr(m,n) = Region(m).Saliency-Region(n).Saliency;
		if RegionSaliencyContr(m,n)<=0
			RegionSaliencyContr(m,n) = 0;
		end
	end
end
RegionSaliencyContr = reshape(mapminmax(RegionSaliencyContr(:)',0,1),regionlen,regionlen);
% [Subsection 'Spatial Relationships', pp.5, Eq.(4)]
for m = 1:regionlen
	Region(m).SaliencyW = Region(m).Count*Region(m).Saliency;
	for n = 1:regionlen
		Region(m).SaliencyW = Region(m).SaliencyW + Region(n).Count*exp(-RegionDist(m,n)^2)*RegionSaliencyContr(m,n);
	end
end
% [Subsection 'Spatial Relationships', pp.5, Eq.(6)]
for m = 1:regionlen
	Region(m).SaliencyW = Region(m).SaliencyW/exp(Region(m).ToCenterDist^2 / params.sigma);
end
% normalization
tmpSaliencyW = [Region(:).SaliencyW];
tmpSaliencyW = mapminmax(tmpSaliencyW(:)',0,1);
for m = 1:regionlen
	Region(m).SaliencyW = tmpSaliencyW(m);
end
%** Regional saliency map
RegSalMap = zeros(Height,Width);
for m = 1:regionlen
	for n = 1:Region(m).Count
		RegSalMap(Region(m).Sub(n,1), Region(m).Sub(n,2), 1) = Region(m).SaliencyW;
	end
end
RegSalMap = reshape(mapminmax(RegSalMap(:)',0,1),Height,Width);
