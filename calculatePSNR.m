% Function to calculate PSNR between two frames
function psnrValue = calculatePSNR(originalFrame, compressedFrame)
    % Convert frames to double precision
    originalFrame = double(originalFrame);
    compressedFrame = double(compressedFrame);
    
    % Calculate MSE (Mean Squared Error)
    mse = sum((originalFrame(:) - compressedFrame(:)).^2) / numel(originalFrame);
    
    % Calculate PSNR (Peak Signal-to-Noise Ratio)
    if mse > 0
        maxValue = 255; % Assuming 8-bit images
        psnrValue = 10 * log10(maxValue^2 / mse);
    else
        psnrValue = Inf; % Frames are identical
    end
end