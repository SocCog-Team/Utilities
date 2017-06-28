function [ BlockScramledImageFQN ] = fnBlockScrambleImage( ImageFQN, NumBlocksHorizontal, NumBlocksVertical )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
% ImageFQN: the fully qualified name of the image file, e,g. '/space/UncannyValleyNHPStimuli/Lily_crop_crop.jpg'
% NumBlocksHorizontal: how many horizontal blocks to create
% NumBlocksVertical:how many vertical blocks to create
BlockScramledImageFQN = [];
debug = 1;


if ~exist('NumBlocksHorizontal', 'var')	
	NumBlocksHorizontal = inputdlg('Enter number of horizontal blocks to create', 'NumBlocksHorizontal', 1, {'17'});
	NumBlocksHorizontal = str2double(NumBlocksHorizontal);
end
if ~exist('NumBlocksVertical', 'var')
	NumBlocksVertical = inputdlg('Enter number of vertical blocks to create', 'NumBlocksVertical', 1, {'20'});
	NumBlocksVertical = str2double(NumBlocksVertical);
end

if (~exist('ImageFQN', 'var'))
	[ImageName, ImageDir] = uigetfile({'*.jpg'; '*.png'; '*.gif'; '*.bmp'}, 'Select the image to block-scramble.');
	ImageFQN = fullfile(ImageDir, ImageName);
	%save_matfile = 1;
elseif isempty(ImageFQN)
	% just return the current version number as second return value
	return
end

[ImageDir, ImageName, ext] = fileparts(ImageFQN);

InputImageArray = imread(ImageFQN);
[ImageHeight, ImageWidth, ImageColorPlanes] = size(InputImageArray);
if (debug)
	figure('Name', 'Input Image');
	image(InputImageArray)
	axis image;
end

% make sure the requested number of blocks do fully fit into the image, or
% rather make the image fit.

VerticalBlockSize = round(ImageHeight / NumBlocksVertical);
HorizontalBlockSize = round(ImageWidth / NumBlocksHorizontal);
BlockedImage = uint8(zeros([(VerticalBlockSize * NumBlocksVertical), (HorizontalBlockSize * NumBlocksHorizontal), ImageColorPlanes]));
[BlockedImageHeight, BlockedImageWidth, ImageColorPlanes] = size(BlockedImage);
if (BlockedImageHeight < ImageHeight) || (BlockedImageWidth < ImageWidth)
	BlockedImage = ms_crop_image(InputImageArray, (VerticalBlockSize * NumBlocksVertical), (HorizontalBlockSize * NumBlocksHorizontal), [254 254 254], []);
else
	BlockedImage(1:ImageHeight, 1:ImageWidth, :) = InputImageArray(1:ImageHeight, 1:ImageWidth, :);
	% now copy the last image row or column into the new pixels?
end
	 
if (debug)
	figure('Name', 'Block-Extended Image');
	imagesc(BlockedImage)
	axis image;
end

% now randomize the block ids
BlockedScrambledImage = uint8(zeros([(VerticalBlockSize * NumBlocksVertical), (HorizontalBlockSize * NumBlocksHorizontal), ImageColorPlanes]));
BlockIdx = zeros([NumBlocksVertical, NumBlocksHorizontal]);
NumBlocks = length(BlockIdx(:));
BlockIdx(:) = (1:1:NumBlocks);
ShuffledBlocksIdx = randperm(NumBlocks);
% now process the shuffled Block list
for iBlock = 1 : NumBlocks;
	CurrenLinBlockIdx = ShuffledBlocksIdx(iBlock);
	[SourceBlockHeightIdx, SourceBlockWidthIdx] = ind2sub(size(BlockIdx), iBlock);
	[TargetBlockHeightIdx, TargetBlockWidthIdx] = ind2sub(size(BlockIdx), CurrenLinBlockIdx);
	
	% now copy the image data around
	DstYIdx = TargetBlockHeightIdx;
	DstXIdx = TargetBlockWidthIdx;
	SrcYIdx = SourceBlockHeightIdx;
	SrcXIdx = SourceBlockWidthIdx;
	VBS = VerticalBlockSize;
	HBS = HorizontalBlockSize;
	BlockedScrambledImage((((DstYIdx-1) * VBS) + 1):(DstYIdx * VBS), (((DstXIdx-1) * HBS) + 1):(DstXIdx * HBS), :) = BlockedImage((((SrcYIdx-1) * VBS) + 1):(SrcYIdx * VBS), (((SrcXIdx-1) * HBS) + 1):(SrcXIdx * HBS), :);
	
end

if (debug)
	figure('Name', 'Block-Extended-Scrambled Image');
	imagesc(BlockedScrambledImage)
	axis image;
end

% now just write out the created files
if ~isequal(size(InputImageArray), size(BlockedImage))
	disp('Original image was size adjusted to allow the requested number of blocks, saving as:'); 
	disp([fullfile(ImageDir, [ImageName, '_BlockSized_Horz', num2str(NumBlocksHorizontal), '_Vert', num2str(NumBlocksVertical), ext])]);
	imwrite(BlockedImage, fullfile(ImageDir, [ImageName, '_BlockSized_Horz', num2str(NumBlocksHorizontal), '_Vert', num2str(NumBlocksVertical), ext]));
end

BlockScramledImageFQN = fullfile(ImageDir, [ImageName, '_BlockScrambled_Horz', num2str(NumBlocksHorizontal), '_Vert', num2str(NumBlocksVertical), ext]);
imwrite(BlockedScrambledImage, BlockScramledImageFQN);


return

end


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function img = ms_crop_image(img, crop_height, crop_width, bg_color, center_pos)
% ms_crop_image: crop or extend the image canvas, centered; new pixel will 
% be of bg_color (color spec) 
% crop image or extend the canvas, relative to the specified center, this will
% if the finalsize is not an even number of pixels smaller or
% larger than the input, the cropping will be shifted one pixel
% from the center, therefore the center error gets larger as
% the final image size gets smaller
% if no center is specified this routine picks the real image center
%
% TODO: 
%
% DONE:
%	test with grayscale images...
%	allow to specify a center position

debug = 0;
in_img_type = class(img);

if (nargin < 5)
	center_pos = [];
end
if (nargin < 4)
	switch size(img, 3)
		case 1
			bg_color = [0];	% if no back ground color is specified just maker one up
		case 3
			bg_color = [0 0 0];
		otherwise
			error(['Current image has unexpected color depth of', num2str(size(img, 3))]);
	end
end
% make sure bg_color is of same ttype as the image, otherwise repmat will
% be doing interesting things
bg_color = cast(bg_color, in_img_type);
% fix bg_color img color plane mismatches
if ((size(img, 3) == 1) && (size(bg_color, 2) == 3))
	bg_color = rgb2gray(reshape(bg_color, [1 1 3]));
end


if ~isempty(center_pos)
	% just extend the image so center_pos is actually in the center
	% this is rather costly but also simple
	img_size = size(img);	% [height widths depth]
	n_pix_above_center = center_pos(1);
	n_pix_below_center = img_size(1) - center_pos(1);
	if ~(n_pix_above_center == n_pix_below_center)
		tmp_img = repmat(reshape(bg_color, [1 1 size(img, 3)]), [(max([n_pix_below_center  n_pix_above_center]) * 2 ) img_size(2) 1]);
		if (n_pix_above_center > n_pix_below_center)
			% add pixels below the bottom	
			tmp_img(1:img_size(1), 1:img_size(2), 1:size(img, 3)) = img(1:img_size(1), 1:img_size(2), 1:size(img, 3));
		else
			% add pixels above the top
			tmp_img(size(tmp_img, 1) + 1 - img_size(1):end, 1:img_size(2), 1:size(img, 3)) = img(1:img_size(1), 1:img_size(2), 1:size(img, 3));
		end
		img = tmp_img;
	end
	img_size = size(img);
	n_pix_left_of_center = center_pos(2);
	n_pix_right_of_center = img_size(2) - center_pos(2);
	if ~(n_pix_left_of_center == n_pix_right_of_center)
		tmp_img = repmat(reshape(bg_color, [1 1 size(img, 3)]), [img_size(1) (max([n_pix_right_of_center  n_pix_left_of_center]) * 2) 1]);
		if (n_pix_left_of_center > n_pix_right_of_center)
			% add pixels on the right
			tmp_img(1:img_size(1), 1:img_size(2), 1:size(img, 3)) = img(1:img_size(1), 1:img_size(2), 1:size(img, 3));
		else
			% add pixels to the left
			tmp_img(1:img_size(1), end - img_size(2) + 1: end, 1:size(img, 3)) = img(1:img_size(1), 1:img_size(2), 1:size(img, 3));
		end
		img = tmp_img;
	end
end


img_size = size(img);	% [height widths depth]
cur_height = img_size(1);
cur_width = img_size(2);
if ~((crop_height == img_size(1)) && (crop_width == img_size(2))),	% only crop if necessary
	if (debug),
		if (crop_height > img_size(1)),
			disp('Requested crop height larger than image, padding image...');
		else
			if (crop_height < img_size(1)),
				disp('Cropping height of image');
			end
		end
		if (crop_width > img_size(2)),
			disp('Requested crop width larger than image, padding image...');
		else
			if (crop_width < img_size(1)),
				disp('Cropping width of image');
			end
		end
	end
	height_delta = crop_height - cur_height;
	d_h_U = floor(height_delta / 2);	% due to floor we might miss one row
	d_h_D = ceil(height_delta / 2);		% due to floor we might miss one row
	
	width_delta = crop_width - cur_width;
	d_h_R = floor(width_delta / 2);		% due to floor we might miss one row
	d_h_L = ceil(width_delta / 2);		% due to floor we might miss one row
	
	
	tmp_img = repmat(reshape(bg_color, [1 1 size(img, 3)]), [crop_height crop_width 1]);
	% now copy in the original image
	tmp_img(max([d_h_U 0]) + 1: d_h_U + cur_height + min([d_h_D 0]), max([d_h_L 0]) + 1: d_h_L + cur_width + min([d_h_R 0]), :) = ...
		img(abs(min([d_h_U 0])) + 1 : cur_height + min([d_h_D 0]),...
		abs(min([d_h_L 0])) + 1 : cur_width + min([d_h_R 0]),...
		:);
	img = tmp_img;
	if (debug),
		imagesc(img);
	end
end

return
end