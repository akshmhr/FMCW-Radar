

% write(s, '1', "char");
data = load("data1.mat");

rawData = data.overall_data(1:3:end,:,:);

[NumFrames, NumChirps, NumSamples] = size(rawData);

% =====================================================
% FIX 1: Global static clutter removal BEFORE any FFT
% Subtracts the mean across ALL frames (removes anything
% that doesn't change over time = walls, DC bias)
% =====================================================
rawData = rawData - mean(rawData, 1);   % mean over frames dim

dopplerSpectrogram = zeros(NumSamples/2, NumFrames * NumChirps);

col = 1;

for f = 1:NumFrames

    frame = squeeze(rawData(f,:,:));   % [128 chirps × 64 samples]

    % FIX 2: Remove mean across CHIRPS (slow-time DC)
    % This kills the within-frame static component
    % dim=2 removes per-chirp sample mean (range DC)
    % dim=1 removes per-sample chirp mean (Doppler DC)
    frame = frame - mean(frame, 1);    % remove static along slow-time
    frame = frame - mean(frame, 2);    % remove static along fast-time

    % ===== Range FFT =====
    r_fft = fft(frame, NumSamples, 2);
    r_fft = r_fft(:, 1:NumSamples/2);

    % FIX 3: Zero the DC range bin explicitly (bin 1)
    r_fft(:, 1) = 0;

    % ===== Doppler FFT =====
    d_fft = fftshift(fft(r_fft, NumChirps, 1), 1);
    RD = abs(d_fft);

    % FIX 4: Zero the zero-Doppler bin (centre row)
    zeroBin = ceil(NumChirps/2) + 1;
    RD(zeroBin, :) = 0;

    % ===== Store =====
    for r = 1:(NumSamples/2)
        dopplerSpectrogram(r, col:col+NumChirps-1) = RD(:, r)';
    end

    col = col + NumChirps;
end

%% Take max value for each chirp (each column)
[maxValPerChirp, maxRangeBin] = max(abs(dopplerSpectrogram), [], 1);

% startIdx = 1;
% endIdx = 12800;
% 
% segment = maxRangeBin(startIdx:endIdx);
% smoothSegment = movmean(segment, 20);
% 
% figure;
% plot(segment, 'Color', [0.7 0.7 0.7]);
% hold on;
% plot(smoothSegment, 'b', 'LineWidth', 2);
% 
% grid on;
% xlabel('Chirp Index (Segment)');
% ylabel('Range Bin of Maximum');
% title('Selected Chirp Segment');
% legend('Raw', 'Smoothed');
% 



% ===== Use only first 2560 chirps (2 seconds) =====
N = 12800;
segment = maxRangeBin(1:N);

% Smooth the curve
smoothSegment = movmean(segment, 20);

% ===== Set threshold =====
% Start with a value based on your plot
threshold = 10;   % adjust after checking the plot

% ===== Trigger condition =====
aboveThresh = smoothSegment > threshold;

% Require persistence: 5 consecutive chirps above threshold
persistCount = 5;
triggerIndex = -1;

for i = 1:(length(aboveThresh) - persistCount + 1)
    if all(aboveThresh(i:i+persistCount-1))
        triggerIndex = i;
        break;
    end
end

% ===== Plot =====
figure;
plot(segment, 'Color', [0.7 0.7 0.7]);
hold on;
plot(smoothSegment, 'b', 'LineWidth', 2);
yline(threshold, 'r--', 'Threshold');
grid on;
xlabel('Chirp Index');
ylabel('Range Bin of Maximum');
title('2 Second Window for Servo Trigger');
legend('Raw', 'Smoothed', 'Threshold');

% ===== Decision =====
persistCount = 3;

intruder_state = 0;  % initial state OFF

for i = 1:(length(smoothSegment) - persistCount + 1)

    window = smoothSegment(i:i+persistCount-1);

    % ===== TURN ON =====
    if intruder_state == 0 && all(window > threshold)
        intruder_state = 1;
        write(s, '1', "char");
        disp("INTRUDER DETECTED -> LED ON");

    % ===== TURN OFF =====
    elseif intruder_state == 1 && all(window < threshold)
        intruder_state = 0;
        write(s, '0', "char");
        disp("NO INTRUDER -> LED OFF");
    end

end
