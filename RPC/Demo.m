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

clc; clear; close all;

% Parameter settings
params.qnums = 256;		% [Subsection 'Color Quantization', pp.8]
params.alpha = 0.95;	% [Subsection 'Parameter Selection', pp.8]
params.delta = 0.25;
params.sigma = 0.2;

%% make folders
if exist('GloSalMaps','dir') ~= 7
	system('md GloSalMaps');
end

if exist('RegSalMaps','dir') ~= 7
	system('md RegSalMaps');
end

%% RPC
rgbfiles = dir('images\*.jpg');
for nums = 1:length(rgbfiles)
	tic;
	% read image
	filename = rgbfiles(nums).name;
	fprintf('%4d/%-4d:\t%s\t', nums, length(rgbfiles), filename);
	rgb = imread(['images\', filename]);
	if ndims(rgb) == 2
		rgb = repmat(rgb, [1 1 3]);
	end
	[GloSalMap, RegSalMap] = RpcSaliency(rgb, params);
	% save result
	imwrite(GloSalMap, ['GloSalMaps\', filename(1:end-4), '_RPC.png']);
	imwrite(RegSalMap, ['RegSalMaps\', filename(1:end-4), '_RPC.png']);
	toc;
end