% Parameters for motion estimation and compression
blockSize = 16; % Macroblock size (16x16 pixels)
searchWindow = 32; % Search window size (32x32 pixels)
Thresh = 0.12; % Threshold for quadtree decomposition
Qscale = 3; % Quantization scale for DCT

%taking file name 
fileName = 'Bowling\v_Bowling_g01_c01.avi';

% Read the video file
v = VideoReader(fileName);
numFrames = v.NumFrames;
frameStart = 1;
frameEnd = numFrames;

% Output video file
outputVideoFile = 'extracted_video_final.mp4';
outputVideo1 = VideoWriter(outputVideoFile, 'MPEG-4');
outputVideo1.FrameRate = v.FrameRate;
open(outputVideo1);

% Initialization
numFrames = frameEnd - frameStart + 1;
quadtreeFrames = cell(numFrames, 1);

% Initialization
numFrames = frameEnd - frameStart + 1;
quadtreeFrames = cell(numFrames, 1);

% Loop through frames
for k = frameStart:frameEnd
    % Read the frame
    curFrame = read(v, k);
    
    % Resize frame to a size compatible with blockSize
    % Determine new dimensions for resizing
    [rows, cols, ~] = size(curFrame);
    newRows = floor(rows / blockSize) * blockSize; % Round down to nearest multiple of blockSize
    newCols = floor(cols / blockSize) * blockSize; % Round down to nearest multiple of blockSize
    
    % Resize frame to new dimensions
    resizedFrame = imresize(curFrame(1:newRows, 1:newCols, :), [newRows, newCols]);
    
    % Perform quadtree decomposition and DCT coding
    processedFrame = varSizeDCTcoder(resizedFrame, Thresh, Qscale);
    quadtreeFrames{k - frameStart + 1} = processedFrame;
    
    % Write processed frame to output video
    writeVideo(outputVideo1, processedFrame);
    
    % Display progress
    fprintf('Processed frame %d / %d\n', k, frameEnd);
end

% Close output video file
close(outputVideo1);
fprintf('Compression complete. Output video saved as %s\n', outputVideoFile);

% Step 5: Compress video with quality enhancements
originalVideoFile = fileName; % Update with your video path
% Check if the original video file exists
if ~isfile(outputVideoFile)
    error('The outputVideoFile file specified was not found. Please check the path and file name.');
end

% Define the path to save the compressed video file
compressedVideoFile = 'compressed_video_final.mp4';

% Load the original video
OriginalVideoReader = VideoReader(originalVideoFile);
CompressedVideoReader = VideoReader(outputVideoFile);

% Initialize VideoWriter object for compressed video
outputVideo1 = VideoWriter(compressedVideoFile, 'MPEG-4');
outputVideo1.FrameRate = OriginalVideoReader.FrameRate;
outputVideo1.Quality = 60; % Adjust quality as needed for smaller size

open(outputVideo1);

% Initialize variables for PSNR calculation
totalPSNR = 0; % Initialize a variable to accumulate PSNR values
frameCount = 0; % Initialize frame counter

% Process and compress each frame of the original video
while hasFrame(CompressedVideoReader) && hasFrame(OriginalVideoReader)
    % Read frame from the original video and compressed video
    originalFrame = readFrame(OriginalVideoReader);
    compressedFrame = readFrame(CompressedVideoReader);
    
    % Ensure the frame sizes are the same
    if any(size(originalFrame) ~= size(compressedFrame))
        resizedCompressedFrame = imresize(compressedFrame, [size(originalFrame, 1) size(originalFrame, 2)]);
    else
        resizedCompressedFrame = compressedFrame;
    end
    
    % Calculate PSNR for the current frame
    psnrValue = calculatePSNR(originalFrame, resizedCompressedFrame);
    
    % Debug: Print MSE value
    mse = sum((double(originalFrame(:)) - double(resizedCompressedFrame(:))).^2) / numel(originalFrame);
    fprintf('Frame %d: MSE = %f, PSNR = %f dB\n', frameCount+1, mse, psnrValue);
    
    % Accumulate PSNR
    totalPSNR = totalPSNR + psnrValue;
    frameCount = frameCount + 1; % Increment frame counter
end

% Close the video writer
close(outputVideo1);

% Calculate and display average PSNR
averagePSNR = totalPSNR / frameCount;
disp(['Average PSNR value is: ', num2str(averagePSNR), ' dB']);

% Load the original video
OriginalVideoReader = VideoReader(outputVideoFile);

% Initialize VideoWriter object for compressed video
outputVideo1 = VideoWriter(compressedVideoFile, 'MPEG-4');
outputVideo1.FrameRate = OriginalVideoReader.FrameRate;
outputVideo1.Quality = 60; 

open(outputVideo1);

% Initialize variables for PSNR calculation
totalPSNR = 0; % Initialize a variable to accumulate PSNR values
frameCount = 0; % Initialize frame counter

% Process and compress each frame of the original video
while hasFrame(OriginalVideoReader)
    % Read frame from the original video
    originalFrame = readFrame(OriginalVideoReader);
    
    % Preprocessing: Apply non-local means denoising (if necessary)
    denoisedFrame = imnlmfilt(originalFrame);
    
    % Compression: Reduce size aggressively (example adjustment)
    compressedFrame = imresize(originalFrame, 0.6); % Example of reducing size
    
    % Ensure values are within range
    compressedFrame = uint8(min(max(compressedFrame, 0), 255));
    
    % Resize the original frame to match the size of the compressed frame
    resizedOriginalFrame = imresize(originalFrame, size(compressedFrame(:,:,1)));
    
    % Calculate PSNR for the current frame
    psnrValue = calculatePSNR(resizedOriginalFrame, compressedFrame);
    totalPSNR = totalPSNR + psnrValue;
    frameCount = frameCount + 1; % Increment frame counter
    
    % Write compressed frame to the video
    writeVideo(outputVideo1, compressedFrame);
end

% Close the video writer
close(outputVideo1);


% Calculate and display bitrates
originalBitrate = calculateBitrate(originalVideoFile);
ExtractedBitrate = calculateBitrate(outputVideoFile);
compressedBitrate = calculateBitrate(compressedVideoFile);
disp(['Original video bitrate: ', num2str(originalBitrate), ' bps']);
disp(['Extracted video bitrate: ', num2str(ExtractedBitrate),' bps']);


% Extract and compress audio from the original video
% Define the path to save the extracted and compressed audio file
compressedAudioFile = 'compressed_audio_final.mp3';

% Ensure the input file path is properly quoted for the system command
inputFileQuoted = sprintf('"%s"', originalVideoFile);

% Perform audio extraction and compression using ffmpeg
fprintf('Extracting and compressing audio.\n');
ffmpeg_command_audio = sprintf('ffmpeg -i %s -q:a 6 -map 0:a:0 -c:a libmp3lame -b:a 8k "%s"', inputFileQuoted, compressedAudioFile);
[status_ffmpeg_audio, cmdout_audio] = system(ffmpeg_command_audio);
if status_ffmpeg_audio ~= 0
    error('Error extracting/compressing audio: %s', cmdout_audio);
end

fprintf('Audio extracted and compressed successfully!\n');
fprintf('Output Audio: %s\n', compressedAudioFile);

% Define the path to the final video file
finalVideoFile = 'Final_video_Full.mp4';

% Ensure the input and audio file paths are properly quoted for the system command
inputVideoQuoted = sprintf('"%s"', compressedVideoFile);
audioFileQuoted = sprintf('"%s"', compressedAudioFile);

% Combine video and audio using ffmpeg
fprintf('Combining video and audio.\n');
ffmpeg_command_combine = sprintf('ffmpeg -i %s -i %s -c copy %s', inputVideoQuoted, audioFileQuoted, finalVideoFile);
[status_ffmpeg_combine, cmdout_combine] = system(ffmpeg_command_combine);
if status_ffmpeg_combine ~= 0
    error('Error combining video and audio: %s', cmdout_combine);
end

fprintf('Video and audio combined successfully!\n');
fprintf('Final Video: %s\n', finalVideoFile);

% End of script
fprintf('Video Compression is completed\n');



