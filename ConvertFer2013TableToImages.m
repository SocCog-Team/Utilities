function [ output_args ] = ConvertFer2013TableToImages( input_args )
%CONVERTFER2013TABLETOIMAGES Summary of this function goes here
%   Detailed explanation goes here
% see https://www.kaggle.com/c/challenges-in-representation-learning-facial-expression-recognition-challenge/data
%
% The data consists of 48x48 pixel grayscale images of faces. The faces have
% been automatically registered so that the face is more or less centered and
% occupies about the same amount of space in each image. The task is to categorize
% each face based on the emotion shown in the facial expression in to one of
% seven categories (0=Angry, 1=Disgust, 2=Fear, 3=Happy, 4=Sad, 5=Surprise, 6=Neutral).
%
% train.csv contains two columns, "emotion" and "pixels". The "emotion" column
% contains a numeric code ranging from 0 to 6, inclusive, for the emotion that
% is present in the image. The "pixels" column contains a string surrounded
% in quotes for each image. The contents of this string a space-separated pixel
% values in row major order. test.csv contains only the "pixels" column and
% your task is to predict the emotion column.
%
% The training set consists of 28,709 examples. The public test set used for
% the leaderboard consists of 3,589 examples. The final test set, which was
% used to determine the winner of the competition, consists of another 3,589 examples.
%
% This dataset was prepared by Pierre-Luc Carrier and Aaron Courville, as part
% of an ongoing research project. They have graciously provided the workshop
% organizers with a preliminary version of their dataset to use for this contest.
% toal: 35887 images

timestamps.(mfilename).start = tic;
disp(['Starting: ', mfilename]);
dbstop if error
fq_mfilename = mfilename('fullpath');
mfilepath = fileparts(fq_mfilename);



SaveImgs = 0;
SaveVideo = 1;
SaveLabels = 1;
%SaveRGB = 1;
debug = 0;
verbose = 0;

BigCSVDir = fullfile(pwd, 'fer2013');
BigCSVFileName = 'fer2013.csv';
ColumnSeparator = ',';
Pixelseparator = ' ';
ImgWidthPixel = 48;
ImgHeightPixel = 48;
NumImgs = 35887;
NumFramesPerImg = 30;
NumPixels = ImgWidthPixel * ImgHeightPixel;
OutputDir = fullfile(pwd, 'Images', [num2str(ImgWidthPixel), 'by', num2str(ImgHeightPixel)]);
OutputFormat = 'png';
OutputMovieFormat = 'Grayscale AVI';
%OutputMovieFormat = 'Uncompressed AVI'
OutputMovieExtension = 'avi';

OutputMovieFormat = 'MPEG-4';
OutputMovieExtension = 'mp4';


LabelSeparatorString = char(10); % char(10) : newline

if isempty(strfind(OutputMovieFormat, 'Grayscale AVI'))
	SaveRGB = 1;
else
	SaveRGB = 0;
end

EmotionsList = {'Angry', 'Disgust', 'Fear', 'Happy', 'Sad', 'Surprise', 'Neutral'};


if (exist(OutputDir) == 0)
	mkdir(OutputDir);
end



CSV_fd = fopen(fullfile(BigCSVDir, BigCSVFileName));
if (CSV_fd == -1)
	error(['Could not open ', fullfile(BigCSVDir, BigCSVFileName)]);
end

CurrentLine = fgetl(CSV_fd);
HeaderLine = CurrentLine;
[Col1Name, remain] = strtok(HeaderLine, ColumnSeparator);
[Col2Name, remain] = strtok(remain, ColumnSeparator);
[Col3Name, remain] = strtok(remain, ColumnSeparator);


%ImgMovieArr = zeros([ImgWidthPixel, ImgHeightPixel, (NumImgs * NumFramesPerImg)]);
ImgMovieArr = zeros([ImgWidthPixel, ImgHeightPixel, NumImgs]);

LabelsList = cell([1, NumImgs]);
MovieLabelsList = cell([1, (NumImgs * NumFramesPerImg)]);

NumImg = 0;

while ~feof(CSV_fd)
	CurrentLine = fgetl(CSV_fd);
	NumImg = NumImg + 1;
	% extract the components of the current line
	[Col1Code, remain] = strtok(CurrentLine, ColumnSeparator);
	Col1Code = str2double(Col1Code);
	[PixelData, remain] = strtok(remain, ColumnSeparator);
	PixelData = str2num(PixelData);
	[UsageName, remain] = strtok(remain, ColumnSeparator);
	
	% now turn PixelData into a proper 2D array
	ImgData = reshape(PixelData, [ImgWidthPixel, ImgHeightPixel]);
	% now rotate, this might still be flipped?
	ImgData = ImgData';
	
	% allow multiple repetitions per frame
	for iFrame = 1 : NumFramesPerImg
		CurrentImgOffset = ((NumImg - 1) * NumFramesPerImg);
		%ImgMovieArr(:,:,CurrentImgOffset + iFrame) = ImgData;
		MovieLabelsList{CurrentImgOffset + iFrame} = EmotionsList{Col1Code+1};
	end
	ImgMovieArr(:,:,NumImg) = ImgData;
	
	
	if (debug);
		imagesc(ImgData);
		colormap(gray);
		axis equal
		axis image
	end
	
	CurrentImgName = [num2str(NumImg, '%08d'), '.', Col1Name, '_', num2str(Col1Code), '.', EmotionsList{Col1Code+1}, '.', Col3Name, '_', UsageName, '.', OutputFormat];
	LabelsList{NumImg} = EmotionsList{Col1Code+1};
	if (SaveImgs)
		disp(['Saving ', fullfile(OutputDir, CurrentImgName)]);
		imwrite(ImgData, fullfile(OutputDir, CurrentImgName));
	else
		if (verbose) 
			disp(['Found data for', fullfile(OutputDir, CurrentImgName)]);
		end
	end
end
disp(['Extracted ', num2str(NumImg),' images from ', fullfile(BigCSVDir, BigCSVFileName)]);
fclose(CSV_fd);


if (SaveLabels) && ~isempty(LabelsList{1})
	% save LabelsList to file
	disp(['Saving labels by image as: ', fullfile(OutputDir, 'EmotionLabelByImage.txt')]);
	ImgsLabels_fd = fopen(fullfile(OutputDir, 'EmotionLabelByImage.txt'), 'w');
	for NumImg = 1 : NumImgs
		fwrite(ImgsLabels_fd, [MovieLabelsList{NumImg}, LabelSeparatorString]);
	end
	fclose(ImgsLabels_fd);
end
if (SaveLabels) && ~isempty(LabelsList{1})
	% save MovieLabelsList
	disp(['Saving labels by frame as: ', fullfile(OutputDir, '..', ['EmotionLabelByMovieFrame_', num2str(NumFramesPerImg), 'FramesPerImage.txt'])]);
	MovieFrameLabels_fd = fopen(fullfile(OutputDir, '..', ['EmotionLabelByMovieFrame_', num2str(NumFramesPerImg), 'FramesPerImage.txt']), 'w');
	for iNumFrame = 1 : length(MovieLabelsList)
		fwrite(ImgsLabels_fd, [MovieLabelsList{iNumFrame}, LabelSeparatorString]);
	end
	fclose(MovieFrameLabels_fd);
end



if (SaveVideo)
	RGBFrame = zeros([ImgWidthPixel, ImgHeightPixel, 3]);
	% write a video:
	
	if (SaveRGB)
		VideoPrefix = 'RGB';
	else
		VideoPrefix = 'Gray';
	end
	
	VideoOut = VideoWriter(fullfile(OutputDir, '..', [VideoPrefix, '_Video.', num2str(NumFramesPerImg, '%02d'),'FramesPerImg', '.', num2str(ImgWidthPixel), 'by', num2str(ImgHeightPixel), '.', OutputMovieExtension]), OutputMovieFormat);
	
	if ~isempty(ismember(OutputMovieFormat, {'Grayscale AVI', 'Indexed AVI', 'Uncompressed AVI'}))
	else
		VideoOut.Quality = 100;
	end
	
	%VideoOut.FileFormat = 'mp4';
	open(VideoOut);
	for NumImg = 1 : NumImgs
		CurrentFrame = ImgMovieArr(:,:,NumImg) / 255;
		if (SaveRGB)
			RGBFrame(:,:,1) = CurrentFrame;
			RGBFrame(:,:,2) = CurrentFrame;
			RGBFrame(:,:,3) = CurrentFrame;
			CurrentFrame = RGBFrame;
		end
		% repeat for the requested number of frames
		for iFrame = 1 : NumFramesPerImg	
			writeVideo(VideoOut, CurrentFrame);
		end
	end
	close(VideoOut);
end

timestamps.(mfilename).end = toc(timestamps.(mfilename).start);
disp([mfilename, ' took: ', num2str(timestamps.(mfilename).end), ' seconds.']);
disp([mfilename, ' took: ', num2str(timestamps.(mfilename).end / 60), ' minutes. Done...']);

end

