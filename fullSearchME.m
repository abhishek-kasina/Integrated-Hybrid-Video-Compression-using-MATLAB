% Full Search Motion Estimation Function (unchanged)
function [motionVec, diffFrame, reconFrame] = fullSearchME(refY, curY, blockSize, searchWindow)
    [rows, cols] = size(refY);
    motionVec = zeros(rows/blockSize, cols/blockSize, 2);
    diffFrame = zeros(size(curY));
    reconFrame = zeros(size(curY));
    
    % Define search range
    range = (searchWindow - blockSize) / 2;
    
    for m = 1:blockSize:rows
        for n = 1:blockSize:cols
            bestSAD = inf;
            for x = -range:range
                for y = -range:range
                    if (m+y > 0 && m+y+blockSize-1 <= rows) && (n+x > 0 && n+x+blockSize-1 <= cols)
                        % Current and reference blocks
                        curBlock = curY(m:m+blockSize-1, n:n+blockSize-1);
                        refBlock = refY(m+y:m+y+blockSize-1, n+x:n+x+blockSize-1);
                        
                        % Calculate SAD
                        SAD = sum(sum(abs(double(curBlock) - double(refBlock))));
                        %Determine if calculated SAD is best SAD
                        if SAD < bestSAD
                            bestSAD = SAD;
                            motionVec((m-1)/blockSize+1, (n-1)/blockSize+1, :) = [y, x];
                        end
                    end
                end
            end

            %Set the motion vectors to be applied to the reference frame
            dy = motionVec((m-1)/blockSize+1, (n-1)/blockSize+1, 1);
            dx = motionVec((m-1)/blockSize+1, (n-1)/blockSize+1, 2);
            
            %Construct the reconstructed block
            reconBlock = refY(m+dy:m+dy+blockSize-1, n+dx:n+dx+blockSize-1);

            %Construct the difference block
            curBlock = curY(m:m+blockSize-1, n:n+blockSize-1);
            diffBlock = curBlock - reconBlock;
            
            % Store the difference block and reconstructed block
            diffFrame(m:m+blockSize-1, n:n+blockSize-1) = diffBlock;
            reconFrame(m:m+blockSize-1, n:n+blockSize-1) = reconBlock + diffBlock;
        end
    end
end