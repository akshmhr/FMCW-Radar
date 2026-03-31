data = load("data1.mat");
rawData = data.overall_data(1:3:end,:,:);
[NumFrames, NumChirps, NumSamples] = size(rawData);

% ===== Parameters =====
fc = 60e9; c = 3e8; BW = 2e9; Tc = 0.0005;
rangeRes  = c / (2 * BW);
maxRange  = rangeRes * (NumSamples/2);
lambda    = c / fc;
maxVel    = lambda / (4 * Tc);

rangeAxis   = linspace(0, maxRange, NumSamples/2);
dopplerAxis = linspace(-maxVel, maxVel, NumChirps);

% ===== Static Clutter Removal =====
% Subtract mean across ALL frames → removes anything that doesn't move
staticMean = mean(rawData, 1);          % [1 × NumChirps × NumSamples]
rawData    = rawData - staticMean;      % broadcast subtraction

% ===== Accumulate RD map =====
RD_sum = zeros(NumChirps, NumSamples/2);

for f = 1:NumFrames
    frame = squeeze(rawData(f, :, :));  % [NumChirps × NumSamples]

    % Range FFT
    r_fft = fft(frame, NumSamples, 2);
    r_fft = r_fft(:, 1:NumSamples/2);

    % Doppler FFT
    d_fft = fftshift(fft(r_fft, NumChirps, 1), 1);
    RD_sum = RD_sum + abs(d_fft);
end

RD_avg = RD_sum / NumFrames;
RD_dB  = 20*log10(RD_avg + 1e-6);

% ===== Null the zero-Doppler bin explicitly (belt + suspenders) =====
zeroBin = ceil(NumChirps/2) + 1;
RD_dB(zeroBin, :) = min(RD_dB(:));    % set to noise floor visually

% ===== Plot =====
lo = prctile(RD_dB(:), 50);
hi = max(RD_dB(:));

figure('Color','k');
imagesc(rangeAxis, dopplerAxis, RD_dB);
axis xy; colormap('jet'); colorbar;
clim([lo, hi]);
xlabel('Range (m)', 'Color','w');
ylabel('Velocity (m/s)', 'Color','w');
title('Range-Doppler Map (Clutter Removed)', 'Color','w');
set(gca, 'XColor','w', 'YColor','w', 'Color','k');
hold on;
yline(0, '--w', 'Zero Doppler');