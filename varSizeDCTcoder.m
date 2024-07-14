% Variable-size DCT Coding Function (unchanged from original)
function Aq = varSizeDCTcoder(A, Thresh, Qscale)
    [Height, Width, Depth] = size(A);
    
    % Perform quadtree decomposition on grayscale image
    S = qtdecomp(rgb2gray(A), Thresh, [2, 16]);
    QuadBlks = repmat(uint8(0), size(S));
    
    % Create the quadtree blocks
    for dim = [2 4 8 16]
        numBlks = length(find(S == dim));
        if (numBlks > 0)
            Val = repmat(uint8(1), [dim dim numBlks]);
            Val(2:dim, 2:dim, :) = 0;
            QuadBlks = qtsetblk(QuadBlks, S, dim, Val);
        end
    end
    QuadBlks(end, 1:end) = 1;
    QuadBlks(1:end, end) = 1;
    
    % Display quadtree blocks (optional)
    % figure, imshow(QuadBlks, [])
    
    % Define quantization matrices for different block sizes
    Qsteps8 = [16 11 10 16 24 40 51 61;
               12 12 14 19 26 58 60 55;
               14 13 16 24 40 57 69 56;
               14 17 22 29 51 87 80 62;
               18 22 37 56 68 109 103 77;
               24 35 55 64 81 104 113 92;
               49 64 78 87 103 121 120 101;
               72 92 95 98 112 100 103 99];
    
    Qsteps2 = [8 34; 34 34];
    Qsteps4 = [8 24 24 24; 24 24 24 24; 24 24 24 24; 24 24 24 24];
    Qsteps16 = [4 16 16 16 16 16 16 16 16 16 16 16 16 16 16 16;
                16 16 16 16 16 16 16 16 16 16 16 16 16 16 16 16;
                16 16 16 16 16 16 16 16 16 16 16 16 16 16 16 16;
                16 16 16 16 16 16 16 16 16 16 16 16 16 16 16 16;
                16 16 16 16 16 16 16 16 16 16 16 16 16 16 16 16;
                16 16 16 16 16 16 16 16 16 16 16 16 16 16 16 16;
                16 16 16 16 16 16 16 16 16 16 16 16 16 16 16 16;
                16 16 16 16 16 16 16 16 16 16 16 16 16 16 16 16;
                16 16 16 16 16 16 16 16 16 16 16 16 16 16 16 16;
                16 16 16 16 16 16 16 16 16 16 16 16 16 16 16 16;
                16 16 16 16 16 16 16 16 16 16 16 16 16 16 16 16;
                16 16 16 16 16 16 16 16 16 16 16 16 16 16 16 16;
                16 16 16 16 16 16 16 16 16 16 16 16 16 16 16 16;
                16 16 16 16 16 16 16 16 16 16 16 16 16 16 16 16;
                16 16 16 16 16 16 16 16 16 16 16 16 16 16 16 16;
                16 16 16 16 16 16 16 16 16 16 16 16 16 16 16 16];
    
    Aq = uint8(zeros(Height, Width, Depth));
    BlkPercent = zeros(4, 1);
    m = 1;
    
    % Perform DCT and quantization for each block size
    for dim = [2 4 8 16]
        [x, y] = find(S == dim);
        BlkPercent(m) = length(x) * dim * dim * 100 / (Height * Width);
        
        % Process each block
        for k = 1:length(x)
            % DCT transformation for each color channel
            t = zeros(dim, dim, Depth);
            for d = 1:Depth
                t(:,:,d) = dct2(double(A(x(k):x(k)+dim-1, y(k):y(k)+dim-1, d)));
                
                % Quantization
                switch dim
                    case 2
                        t(:,:,d) = round(t(:,:,d) ./ Qsteps2) .* Qsteps2;
                    case 4
                        t(:,:,d) = round(t(:,:,d) ./ Qsteps4) .* Qsteps4;
                    case 8
                        t(:,:,d) = round(t(:,:,d) ./ (Qscale * Qsteps8)) .* (Qscale * Qsteps8);
                    case 16
                        t(:,:,d) = round(t(:,:,d) ./ Qsteps16) .* Qsteps16;
                end
                
                % Perform inverse DCT
                Aq(x(k):x(k)+dim-1, y(k):y(k)+dim-1, d) = uint8(idct2(t(:,:,d)));
            end
        end
        m = m + 1;
    end
end