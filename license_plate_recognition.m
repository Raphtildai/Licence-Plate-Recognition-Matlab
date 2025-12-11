function [recognized_chars, time_taken] = license_plate_recognition()
% ======================================================================
% OPTIMIZED LICENSE PLATE RECOGNITION (LPR) using MATLAB Functions
% ======================================================================
    tic; % Start timer for comparison
    clc; clear; close all;
    
    %% -------------------- 0. Load Character Database --------------------
    try
        % Assumes imgfile is a 2xN cell array: {Template_Image, Character_String}
        load('templates/imgfildata.mat');
        if ~exist('imgfile', 'var')
            error('imgfildata.mat must contain imgfile variable');
        end
        fprintf('Loaded character database with %d templates\n', size(imgfile, 2));
    catch
        error('Could not load imgfildata.mat character database. Ensure it exists.');
    end

    % --- Pre-process templates for consistent size (Optimization) ---
    TEMPLATE_SIZE = [42, 24];
    for t = 1:size(imgfile, 2)
        
        % ********************************************************************
        % ** THE FIX IS HERE: Explicitly convert to double first. **
        % ********************************************************************
        template_img = imgfile{1, t};
        
        % 1. Convert to double to handle logical/other non-numeric types
        template_img_d = double(template_img); 
        
        % 2. If the template is RGB (3D), convert to grayscale. Otherwise, it's 2D.
        if size(template_img_d, 3) == 3
            template_img_d = im2gray(template_img_d);
        end
        
        % 3. Binarize (only necessary if templates weren't already perfectly binary)
        %    imbinarize handles numeric arrays well.
        template_binary = imbinarize(template_img_d);
        
        % 4. Resize and store
        imgfile{1, t} = imresize(template_binary, TEMPLATE_SIZE);
        
    end

    %% -------------------- 1. LOAD IMAGE + RGB → GRAY --------------------
    [file, path] = uigetfile({'*.jpg;*.bmp;*.png;*.tif;*.jpeg'}, 'Choose an image');
    if isequal(file, 0)
        disp('No file selected. Exiting.');
        recognized_chars = '';
        time_taken = toc;
        return;
    end
    imgPath = fullfile(path, file);
    
    I_color = imread(imgPath);
    
    % Use built-in function for efficiency and accuracy
    I = im2gray(I_color);
    I = uint8(I);
    figure; imshow(I); title('1. Original Grayscale');

    %% -------------------- 2. CONTRAST ENHANCEMENT --------------------
    % Use Adaptive Histogram Equalization (CLAHE) for better local contrast
    I_enh = adapthisteq(I);
    figure; imshow(I_enh); title('2. Contrast Enhanced (CLAHE)');
    
    %% -------------------- 3. SOBEL EDGE DETECTION (Optimized) --------------------
    % Use built-in edge detector (Canny is often better, but Sobel for comparison)
    % Using a threshold to create a binary edge map
    E = edge(I_enh, 'sobel');
    figure; imshow(E); title('3. Edges (Sobel)');
    
    %% -------------------- 4. MORPHOLOGICAL CLOSING (Optimized) --------------------
    % Replace manual loops with strel and imclose
    SE = strel('square', 3);
    Ec = imclose(E, SE); 
    figure; imshow(Ec); title('4. After Closing');
    
    %% -------------------- 5. CONNECTED COMPONENTS (Optimized) --------------------
    CC = bwconncomp(Ec);
    % Use regionprops for fast calculation of properties
    props = regionprops(CC, 'Area', 'BoundingBox');
    
    %% -------------------- 6. LICENSE PLATE CANDIDATE SELECTION --------------------
    bestScore = -inf;
    bestBox   = [];
    
    for k = 1:length(props)
        bb = props(k).BoundingBox;
        area = props(k).Area;
        w = bb(3); h = bb(4);
        aspect = w / h;
        
        % Fixed Filtering Criteria (same as original for fair comparison)
        if aspect < 2 || aspect > 6, continue; end
        if area < 1500 || area > 40000, continue; end

        % Score based on edge density (same technique)
        sub_image_E = E(round(bb(2)):round(bb(2)+h-1), round(bb(1)):round(bb(1)+w-1));
        score = sum(sub_image_E(:)) / (w * h);
        
        if score > bestScore
            bestScore = score;
            bestBox = bb;
        end
    end
    
    if isempty(bestBox)
        error('No license-plate region detected.');
    end
    
    % Display detected plate
    figure; imshow(I_color); title('6. Detected License Plate'); hold on;
    rectangle('Position', bestBox, 'EdgeColor','red', 'LineWidth', 3);
    hold off;
    
    x1 = round(bestBox(1));
    y1 = round(bestBox(2));
    x2 = x1 + round(bestBox(3)) - 1;
    y2 = y1 + round(bestBox(4)) - 1;
    
    %% -------------------- 7. EXTRACT PLATE (Generous Padding) --------------------
    width  = bestBox(3);
    height = bestBox(4);
    
    % Same generous padding logic as original
    padX = max(round(width * 0.20), 20);
    padY = max(round(height * 0.25), 15);
    
    x1p = max(1, x1 - padX);
    y1p = max(1, y1 - padY);
    x2p = min(size(I_enh,2), x2 + padX);
    y2p = min(size(I_enh,1), y2 + padY);
    
    plate = I_enh(y1p:y2p, x1p:x2p);
    
    % SAFE EXTRA CROP TO REMOVE THICK BORDER
    if size(plate,1) > 12 && size(plate,2) > 12
        plate = plate(6:end-6, 6:end-6);
    end

    figure; imshow(plate); title('7. Extracted Plate');
    
    %% -------------------- 8. OTSU BINARIZATION + POST-PROCESSING (ULTIMATE FIX) --------------------
    %% === 8. OTSU + BORDER REMOVAL + CLEANING ===
    th = graythresh(plate);
    BW = imbinarize(plate, th);
    BW = ~BW;                 % characters white
    
    BW = bwareaopen(BW, 40);  % remove small noise
    
    % HUGE FIX: Remove anything touching the border (frame, underline, emblem)
    BW = imclearborder(BW);
    
    % Close small gaps inside characters
    BW = imclose(BW, strel('rectangle',[3 2]));
    
    % Light erosion to break horizontal bridges
    BW = imerode(BW, strel('line',3,0));
    
    % Restore thickness
    BW_clean = imdilate(BW, strel('square',2));
    
    figure; imshow(BW_clean); title('8. Clean Binarized Plate (Targeted Separation)');
    
    %% -------------------- 9. CHARACTER SEGMENTATION + MERGING (FINAL FILTER SET) --------------------
    CC_chars = bwconncomp(BW_clean);
    charStats = regionprops(CC_chars, 'BoundingBox', 'Area');
    
    charBoxes = [];
    plate_height = size(BW_clean,1);
    
    for k = 1:length(charStats)
        bb = charStats(k).BoundingBox;
        w = bb(3); h = bb(4);
        aspect = w/h;
        area = charStats(k).Area;
    
        % Filter 1: Area (Noise) - KEEP
        if area < 40, continue; end
    
        % Filter 2: Character Height (SAFE range: 40% to 100%)
        % 40% is safe for numbers/letters, and avoids small noise.
        if h < 0.40 * plate_height || h > plate_height, continue; end 
    
        % Filter 3: Aspect Ratio (SAFE range: Max width 1.5x height)
        if aspect < 0.05 || aspect > 1.5, continue; end 
        
        % Filter 4: Emblem Filter (CRITICAL for Croatian plate)
        % Note: C is the width of the segmented plate image, not the bounding box width.
        if aspect > 0.8 && aspect < 1.5 && (bb(1) > C*0.3) && (bb(1) < C*0.7)
            continue; 
        end
    
        charBoxes = [charBoxes; bb];
    end
    
    % Sort left-to-right
    if ~isempty(charBoxes)
        [~, ord] = sort(charBoxes(:,1));
        charBoxes = charBoxes(ord, :);
    end
    
    figure; imshow(BW_clean); hold on;
    for k = 1:size(charBoxes,1)
        rectangle('Position', charBoxes(k,:), 'EdgeColor','r', 'LineWidth', 2);
    end
    hold off;
    title(sprintf('9. Final Character Segmentation (Detected: %d)', size(charBoxes,1)));

    %% -------------------- 10. CHARACTER RECOGNITION --------------------
    recognized_chars = '';
    
    if isempty(charBoxes)
        fprintf('No characters to recognize.\n');
        time_taken = toc;
        return;
    end
    fprintf('\n=== 10. CHARACTER RECOGNITION ===\n');
    
    for k = 1:size(charBoxes,1)
        bb = charBoxes(k,:);
        
        % Extract character with padding (same logic)
        pad_x = max(1, round(bb(3) * 0.1));
        pad_y = max(1, round(bb(4) * 0.1));
        
        x1_c = max(1, round(bb(1)) - pad_x);
        y1_c = max(1, round(bb(2)) - pad_y);
        x2_c = min(size(BW_clean,2), round(bb(1) + bb(3)) + pad_x);
        y2_c = min(size(BW_clean,1), round(bb(2) + bb(4)) + pad_y);
        
        char_img = BW_clean(y1_c:y2_c, x1_c:x2_c);
        
        if numel(char_img) < 25
            fprintf('Char %d: Too small, skipping\n', k);
            continue;
        end
        
        % Resize to match template size
        char_resized = imresize(char_img, TEMPLATE_SIZE);
        
        % Recognize character using the same correlation technique
        [best_char, confidence] = recognize_character_simple_optimized(char_resized, imgfile);
        
        % Adaptive threshold (same logic)
        threshold = 0.3;
        if k <= 2 % First two characters (typically letters)
            threshold = 0.35;
        end
        
        if confidence > threshold
            recognized_chars = [recognized_chars, best_char];
            status = 'MATCH';
        else
            recognized_chars = [recognized_chars, '?'];
            status = 'LOW_CONF';
        end
        
        fprintf('Char %d: %s (confidence: %.3f) - %s\n', k, best_char, confidence, status);
    end

    %% -------------------- 11. FINAL RESULTS & BENCHMARK --------------------
    time_taken = toc;
    fprintf('\n=== 11. FINAL RESULT ===\n');
    fprintf('Recognized License Plate: %s\n', recognized_chars);
    fprintf('Total execution time: %.3f seconds\n', time_taken);
    
    % Save to file (same logic)
    try
        fileID = fopen('number_Plate_Optimized.txt', 'w');
        fprintf(fileID, '%s\n', recognized_chars);
        fclose(fileID);
        fprintf('Results saved to number_Plate_Optimized.txt\n');
    catch
        warning('Could not save results to file.');
    end
    
    % Final display (same logic)
    figure('Position', [100, 100, 1000, 400]);
    subplot(1,3,1); imshow(I_color); title('Original Image');
    subplot(1,3,2); imshow(plate); title('Extracted Plate');
    subplot(1,3,3); imshow(BW_clean); hold on;
    for k = 1:size(charBoxes,1)
        rectangle('Position', charBoxes(k,:), 'EdgeColor','r', 'LineWidth', 2);
        if k <= length(recognized_chars)
            text(charBoxes(k,1), charBoxes(k,2)-8, recognized_chars(k), ...
                 'Color', 'g', 'FontSize', 12, 'FontWeight', 'bold');
        end
    end
    title(sprintf('Recognized: %s\nTime: %.3fs', recognized_chars, time_taken));
    hold off;
end

%% ===================== HELPER FUNCTION ==============================

function [best_char, best_score] = recognize_character_simple_optimized(char_img, imgfile)
% Simple character recognition using correlation (Optimized for fixed size)
% char_img is already resized to TEMPLATE_SIZE
    best_score = -inf;
    best_char = '?';
    
    % Convert to double once outside the loop
    char_img_d = double(char_img); 
    
    for t = 1:size(imgfile, 2)
        % Template is already pre-resized and converted
        template = imgfile{1, t}; 
        
        % Calculate correlation
        correlation = corr2(double(template), char_img_d);
        
        if correlation > best_score
            best_score = correlation;
            best_char = imgfile{2, t};
        end
    end
end