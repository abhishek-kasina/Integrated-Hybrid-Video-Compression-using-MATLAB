
% Function to calculate bitrate of a video file
function bitrate = calculateBitrate(videoFile)
    videoInfo = VideoReader(videoFile);
    fileSize = dir(videoFile).bytes;
    duration = videoInfo.Duration;
    bitrate = fileSize * 8 / duration; % Bits per second
end