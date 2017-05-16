function [ output_args ] = fnGeneratePulseTrains( input_args )
%FNGENERATEBANDNOISE create band"filtered white noise by generative method
%   create white noise as the sum of selected frequencies inside a band
%   with randsomized phases

FsamplingHz = 44100;
OutDir = pwd;
TypeString = 'LowNoise';
OutDotExtString = '.wav';

PulseDurationMS = 150;
RampDurationMS = 10;
PulsesPerTrain = 6;
InterPulseDelayMS = 200;
StereoChannelOffsetMS = 75;
AlignmentString = 'Concatenated'; % End, Start, Concatenated
TrainDescriptionString = ['PulseDur_', num2str(PulseDurationMS), '.RampDur_', num2str(RampDurationMS), '.PulsesPerTrain_', num2str(PulsesPerTrain), '.InterPulseDur_', num2str(InterPulseDelayMS), '.Alignment_', AlignmentString];
TrainDescriptionString = ['PulseDur_', num2str(PulseDurationMS), '.RampDur_', num2str(RampDurationMS), '.InterPulseDur_', num2str(InterPulseDelayMS), '.Alignment_', AlignmentString];

OutFQN = fullfile(OutDir, [TypeString, '.', TrainDescriptionString, OutDotExtString]);

PulseDurationSamples = ConvertMSToSamples(PulseDurationMS, FsamplingHz);
InterPulseDelaySamples = ConvertMSToSamples(InterPulseDelayMS, FsamplingHz);

OutputWaveformDurationMS = (PulsesPerTrain * PulseDurationMS) + ((PulsesPerTrain - 1) * InterPulseDelayMS);
OutputWaveformDurationSamples = ConvertMSToSamples(OutputWaveformDurationMS, FsamplingHz);
OutputWaveform = zeros([1, OutputWaveformDurationSamples]);

OutStartIdx = 0;
OutEndIdx = 0;

% harmonic series
JitterFactor = 0.01;
SpecificationCell_443Hz_12harmonics = fnCreateHarmonicSeriesSpecification(443, 12, 'LinearDecrease', JitterFactor);
SpecificationCell_733Hz_12harmonics = fnCreateHarmonicSeriesSpecification(733, 12, 'LinearDecrease', JitterFactor);
SpecificationCell_997Hz_12harmonics = fnCreateHarmonicSeriesSpecification(997, 12, 'LinearDecrease', JitterFactor);


HarmonicPulse443_12 = fnGenerateNoisePulse( FsamplingHz, 0, 0, SpecificationCell_443Hz_12harmonics, PulseDurationMS, RampDurationMS, RampDurationMS );
HarmonicPulse733_12 = fnGenerateNoisePulse( FsamplingHz, 0, 0, SpecificationCell_733Hz_12harmonics, PulseDurationMS, RampDurationMS, RampDurationMS );
HarmonicPulse997_12 = fnGenerateNoisePulse( FsamplingHz, 0, 0, SpecificationCell_997Hz_12harmonics, PulseDurationMS, RampDurationMS, RampDurationMS );

tmp_player = audioplayer(HarmonicPulse443_12, FsamplingHz);
playblocking(tmp_player);
tmp_player = audioplayer(HarmonicPulse733_12, FsamplingHz);
playblocking(tmp_player);
tmp_player = audioplayer(HarmonicPulse997_12, FsamplingHz);
playblocking(tmp_player);


Harm443_12Train = fnCreatePulseTrain(FsamplingHz, HarmonicPulse443_12, PulsesPerTrain, InterPulseDelayMS);
Harm733_12Train = fnCreatePulseTrain(FsamplingHz, HarmonicPulse733_12, PulsesPerTrain, InterPulseDelayMS);
Harm997_12Train = fnCreatePulseTrain(FsamplingHz, HarmonicPulse997_12, PulsesPerTrain, InterPulseDelayMS);



% Noise
NoisePulseLow = fnGenerateNoisePulse( FsamplingHz, 1000, 2000, [], PulseDurationMS, RampDurationMS, RampDurationMS );
NoisePulseHigh = fnGenerateNoisePulse( FsamplingHz, 4000, 8000, [], PulseDurationMS, RampDurationMS, RampDurationMS );

NoisePulseLowTrain = fnCreatePulseTrain(FsamplingHz, NoisePulseLow, PulsesPerTrain, InterPulseDelayMS);
NoisePulseHighTrain = fnCreatePulseTrain(FsamplingHz, NoisePulseHigh, PulsesPerTrain, InterPulseDelayMS);


% get trains for all number of Pulses up to PulsesPerTrain
NoisePulseLowTrainCell = {};
NoisePulseHighTrainCell = {};
Harm443_12TrainCell = {};
Harm733_12TrainCell = {};
Harm997_12TrainCell = {};
for i_PulsesPerTrain = 1 : PulsesPerTrain
	CurrentPulsesPerTrain = i_PulsesPerTrain;
	NoisePulseLowTrainCell{end+1} = fnCreatePulseTrain(FsamplingHz, NoisePulseLow, CurrentPulsesPerTrain, InterPulseDelayMS);
	NoisePulseHighTrainCell{end+1} = fnCreatePulseTrain(FsamplingHz, NoisePulseHigh, CurrentPulsesPerTrain, InterPulseDelayMS);
	Harm443_12TrainCell{end+1} = fnCreatePulseTrain(FsamplingHz, HarmonicPulse443_12, CurrentPulsesPerTrain, InterPulseDelayMS);
	Harm733_12TrainCell{end+1} = fnCreatePulseTrain(FsamplingHz, HarmonicPulse733_12, CurrentPulsesPerTrain, InterPulseDelayMS);
	Harm997_12TrainCell{end+1} = fnCreatePulseTrain(FsamplingHz, HarmonicPulse997_12, CurrentPulsesPerTrain, InterPulseDelayMS);
end

% now create and save stereotrains for all combinations of a given dyad

fnCreateAllStrereotrainCombinations(FsamplingHz, StereoChannelOffsetMS, NoisePulseHighTrainCell, NoisePulseLowTrainCell, AlignmentString, OutDir, 'HighNoise_LowNoise', TrainDescriptionString, OutDotExtString);

fnCreateAllStrereotrainCombinations(FsamplingHz, StereoChannelOffsetMS, Harm733_12TrainCell, Harm443_12TrainCell, AlignmentString, OutDir, '733Hz12Harm_443Hz12Harm', TrainDescriptionString, OutDotExtString);



% % potentially silence some pulses here?
% NoiseStereoTrain = fnMergeMonoTimeseriesWithOffset(FsamplingHz, StereoChannelOffsetMS, NoisePulseHighTrain, NoisePulseLowTrain);
% tmp_player = audioplayer(NoiseStereoTrain, FsamplingHz);
% playblocking(tmp_player);
% TypeString = 'BandFilteredNoise';
% OutFQN = fullfile(OutDir, [TypeString, '.', TrainDescriptionString, OutDotExtString]);
% audiowrite(OutFQN, NoiseStereoTrain', FsamplingHz);
%
%
% HarmonicStereoTrain = fnMergeMonoTimeseriesWithOffset(FsamplingHz, StereoChannelOffsetMS, Harm443_12Train, Harm733_12Train);
% tmp_player = audioplayer(HarmonicStereoTrain, FsamplingHz);
% playblocking(tmp_player);
% TypeString = 'HarmonicSeries';
% OutFQN = fullfile(OutDir, [TypeString, '.', TrainDescriptionString, OutDotExtString]);
% audiowrite(OutFQN, HarmonicStereoTrain', FsamplingHz);



return
end


function [ OutputWaveform ] = fnCreatePulseTrain( FsamplingHz, CurrentPulseData, PulsesPerTrain, InterPulseDelayMS )

InterPulseDelaySamples = ConvertMSToSamples(InterPulseDelayMS, FsamplingHz);
PulseDurationSamples = size(CurrentPulseData, 2);
PulseDurationMS = PulseDurationSamples / FsamplingHz;


OutputWaveformDurationMS = (PulsesPerTrain * PulseDurationMS) + ((PulsesPerTrain - 1) * InterPulseDelayMS);
OutputWaveformDurationSamples = ConvertMSToSamples(OutputWaveformDurationMS, FsamplingHz);
OutputWaveform = zeros([1, OutputWaveformDurationSamples]);

for i_pulse = 1 : PulsesPerTrain
	OutStartIdx = (i_pulse-1) * (PulseDurationSamples + InterPulseDelaySamples) + 1;
	OutEndIdx = OutStartIdx + PulseDurationSamples -1;
	OutputWaveform(OutStartIdx: OutEndIdx) = CurrentPulseData;
end

return
end


function [ NoisePulse ] = fnGenerateNoisePulse( FsamplingHZ, FstartHZ, FstopHZ, N_steps, DurationMS, OnRampDurationMS, OffRampDurationMS )
%fnGenerateNoisePulse generatively creates band restricted noise...

debug = 1;
%SamplesPerPulse = (FsamplingHZ * DurationMS / 1000);
SamplesPerPulse = ConvertMSToSamples(DurationMS, FsamplingHZ);

NoisePulse = zeros([1, SamplesPerPulse]);

%NoisePulse = 2 * (rand([1, SamplesPerPulse])) - 1;
if (debug)
	subplot(4, 1, 1)
	plot(NoisePulse)
end
if isempty(N_steps)
	% a band limited approximation to white noise
	if (FstopHZ > (0.5 * FsamplingHZ))
		disp(['Requested stop frequency (', FstopHZ, ') is higher than the current Nyquist-frequency (', num2str(CurrentFrequencyHz * 0.5), ') setting Fstop to the Nyquist-frequency.']);
		FstopHZ = (0.5 * FsamplingHZ);
	end
	
	% default to 1/2 Hz steps
	N_steps = (FstopHZ - FstartHZ) * 2 ;
end

if iscell(N_steps)
	%only add the specified frequencies, ignore FstartHZ and FstopHZ
	FrequencyList = N_steps{1};
	WeightList = N_steps{2};
	N_steps = length(FrequencyList) - 1;
end



for i_step = 0: N_steps
	if exist('FrequencyList', 'var')
		%only add the specified frequencies, ignore FstopHZ
		CurrentPhase = 0;
		CurrentFrequencyHz = FrequencyList(i_step + 1);
		CurrentWeight = WeightList(i_step + 1);
		if (CurrentFrequencyHz > (0.5 * FsamplingHZ))
			disp(['Requested frequency (', CurrentFrequencyHz, ') is higher than the current Nyquist-frequency (', num2str(CurrentFrequencyHz * 0.5), ') forcing the weight to 0.']);
			CurrentWeight = 0;
		end
		
	else
		CurrentFrequencyHz = FstartHZ + i_step * (FstopHZ - FstartHZ)/N_steps;
		CurrentPhase = (rand(1) * pi) - (0.5 * pi);
		CurrentWeight = 1;
	end
	
	
	CyclesInPulse = CurrentFrequencyHz / 1000 * DurationMS;
	
	
	% a full sine takes 2*pi
	PulseStepSize = (CyclesInPulse / SamplesPerPulse) * 2 * pi;
	
	
	CurrentFrequencyPulse = CurrentWeight * sin(CurrentPhase:PulseStepSize:(((SamplesPerPulse) * PulseStepSize) + CurrentPhase));
	CurrentFrequencyDoublePulse = CurrentWeight * sin(CurrentPhase:PulseStepSize:(((SamplesPerPulse) * PulseStepSize) * 2 + CurrentPhase));
	
	% Trim things if too many samples
	if length(CurrentFrequencyPulse) > SamplesPerPulse
		CurrentFrequencyPulse = CurrentFrequencyPulse(1: SamplesPerPulse);
	elseif length(CurrentFrequencyPulse) < SamplesPerPulse
		error('Doh');
	end
	%plot(CurrentFrequencyPulse)
	% the folowing has often large initial transients that make the
	% normalisation not work well
	%NoisePulse = NoisePulse + CurrentFrequencyPulse(1: SamplesPerPulse);
	StartIdx = round(length(CurrentFrequencyDoublePulse) * 0.25);
	NoisePulse = NoisePulse + CurrentFrequencyDoublePulse(StartIdx: StartIdx+SamplesPerPulse-1);
	
	
	if (debug)
		subplot(4, 1, 1)
		plot(CurrentFrequencyPulse);
	end
end

% normalise the amplitude
NoisePulse = NoisePulse / max(abs(NoisePulse(:)));

if (debug)
	subplot(4, 1, 2)
	plot(NoisePulse);
end

% create OnRamp
if (OnRampDurationMS > 0)
	SamplesInRamp = round(FsamplingHZ/1000 * OnRampDurationMS);
	RampStepSize = pi / SamplesInRamp;
	CurrentOnRamp = 0.5 * (sin(-pi/2:RampStepSize:pi/2) + 1);
	NoisePulse(1:SamplesInRamp+1) = NoisePulse(1:SamplesInRamp+1) .* CurrentOnRamp;
end

if (OffRampDurationMS > 0)
	SamplesInRamp = round(FsamplingHZ/1000 * OffRampDurationMS);
	RampStepSize = pi / SamplesInRamp;
	CurrentOffRamp = 0.5 * (sin(pi/2:-RampStepSize:-pi/2) + 1);
	NoisePulse(end-SamplesInRamp:end) = NoisePulse(end-SamplesInRamp:end) .* CurrentOffRamp;
end

if (debug)
	subplot(4, 1, 3)
	plot(NoisePulse)
end


if (debug)
	subplot(4, 1, 4)
	CurrentN = 2^nextpow2(SamplesPerPulse);
	CurrentFFT = fft(NoisePulse, CurrentN);
	XVec = FsamplingHZ*(0:(CurrentN/2))/CurrentN;
	YVec = abs(CurrentFFT / CurrentN);
	plot(XVec, YVec(1:CurrentN/2+1));
end

return
end


function [ DurationSamples ] = ConvertMSToSamples(DurationMS, SamplingFrequency)

DurationSamples = round(DurationMS * 10^(-3) * SamplingFrequency);

return
end


function [ HarmonicSeriesSpecification ] = fnCreateHarmonicSeriesSpecification( BaseFrequencyHz, NumberOfHarmonics, WeightingFunction, JitterFactor )
% how much to jitter each harmonic, based on the true harmonic frequency
if ~exist('JitterFactor', 'var')
	JitterFactor = 0;
end


HarmonicSeriesSpecification = cell([2,1]);

FrequencyList = zeros([1, NumberOfHarmonics]);
WeightList = ones([1, NumberOfHarmonics]);

for iHarmonic = 1 : NumberOfHarmonics
	JitterHz = (rand() * JitterFactor) * (rand() * -1) * iHarmonic * BaseFrequencyHz;
	FrequencyList(iHarmonic) = iHarmonic * BaseFrequencyHz + JitterHz;
	switch WeightingFunction
		case 'Equal'
			WeightList(iHarmonic) = 1;
		case 'LinearDecrease'
			WeightList(iHarmonic) = 1 - ((iHarmonic - 1) / NumberOfHarmonics);
	end
end

HarmonicSeriesSpecification{1} = FrequencyList;
HarmonicSeriesSpecification{2} = WeightList;

return
end

function [ CurrentStereoTrain ] = fnMergeMonoTimeseriesWithOffset( FsamplingHz, StereoChannelOffsetMS, ChannelDataLeft, ChannelDataRight, AlignmentString )

if ~exist('AlignmentString', 'var')
	AlignmentString = 'End';
end


StereoChannelOffsetSamples = ConvertMSToSamples(StereoChannelOffsetMS, FsamplingHz);

MaxTrainSamples = max([size(ChannelDataRight, 2), size(ChannelDataLeft, 2)]);

CurrentStereoTrain = zeros([2, MaxTrainSamples + StereoChannelOffsetSamples]);


switch AlignmentString
	case 'End'
		% align the shorter train at the end while still applying the
		% offset, here the shorter train is always lagging...
		if (size(ChannelDataRight, 2) > size(ChannelDataLeft, 2))
			CurrentStereoTrain(2, 1:size(ChannelDataRight, 2)) = ChannelDataRight;
			CurrentStereoTrain(1, end-size(ChannelDataLeft, 2)+1:end) = ChannelDataLeft;
		else
			CurrentStereoTrain(2, end-size(ChannelDataRight, 2)+1:end) = ChannelDataRight;
			CurrentStereoTrain(1, 1:size(ChannelDataLeft, 2)) = ChannelDataLeft;
		end
		
	case 'Start'
		% align the shorter train at the start while still applying the
		% offset to the shorter train
		if (size(ChannelDataRight, 2) > size(ChannelDataLeft, 2))
			CurrentStereoTrain(2, 1:size(ChannelDataRight, 2)) = ChannelDataRight;
			CurrentStereoTrain(1, StereoChannelOffsetSamples+1:StereoChannelOffsetSamples+size(ChannelDataLeft, 2)) = ChannelDataLeft;
		else
			CurrentStereoTrain(2, StereoChannelOffsetSamples+1:StereoChannelOffsetSamples+size(ChannelDataRight, 2)) = ChannelDataRight;
			CurrentStereoTrain(1, 1:size(ChannelDataLeft, 2)) = ChannelDataLeft;
		end
		
	case 'Concatenated'
		CurrentStereoTrain = zeros([2, size(ChannelDataRight, 2) + size(ChannelDataLeft, 2) + StereoChannelOffsetSamples]);
		% left leads...
		
		FirstTrainEndIdx = size(ChannelDataLeft, 2);
		SecondTrainStartIdx = FirstTrainEndIdx + StereoChannelOffsetSamples + 1;
		SecondTrainEndIdx = SecondTrainStartIdx + size(ChannelDataRight, 2) - 1;
		
		CurrentStereoTrain(1, 1 : FirstTrainEndIdx) = ChannelDataLeft;
		CurrentStereoTrain(2, SecondTrainStartIdx : SecondTrainEndIdx) = ChannelDataRight;
end

return
end


function [ ] = fnCreateAllStrereotrainCombinations( FsamplingHz, StereoChannelOffsetMS, LeftChannelTrainCell, RightChannelTrainCell, AlignmentString, OutDir, TypeString, TrainDescriptionString, OutDotExtString )
% for audiowrite the first channel is left, the second is right
NumberRightTrains = length(RightChannelTrainCell);
NumberLeftTrains = length(LeftChannelTrainCell);

for iRightTrain = 0 : NumberRightTrains
	
	if (iRightTrain == 0)
		CurrentRightTrain = zeros(size(RightChannelTrainCell{1}));
	else
		CurrentRightTrain = RightChannelTrainCell{iRightTrain};
	end
	for iLeftTrain = 0 : NumberLeftTrains
		if (iLeftTrain == 0)
			CurrentLeftTrain = zeros(size(LeftChannelTrainCell{1}));
		else
			CurrentLeftTrain = LeftChannelTrainCell{iLeftTrain};
		end
		%CurrentLeftTrain = LeftChannelTrainCell{iLeftTrain};
		CurrentStereoTrain = fnMergeMonoTimeseriesWithOffset(FsamplingHz, StereoChannelOffsetMS, CurrentLeftTrain, CurrentRightTrain, AlignmentString);
		CurrentPulseNumberCombinationString = ['RightPulses_', num2str(iRightTrain), '.LeftPulses_', num2str(iLeftTrain)];
		OutFQN = fullfile(OutDir, [TypeString, '.', CurrentPulseNumberCombinationString, '.', TrainDescriptionString, '.', ['StereoOffset_', num2str(StereoChannelOffsetMS)], OutDotExtString]);
		audiowrite(OutFQN, CurrentStereoTrain', FsamplingHz);
		disp(['Saved stereo trains with offset as ', OutFQN]);
	end
end

return
end