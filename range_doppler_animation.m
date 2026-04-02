clc; clear; close all;

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
staticMean = mean(rawData, 1);
rawData    = rawData - staticMean;

% ===== Create Figure ONCE =====
figure('Color','k');
h = imagesc(rangeAxis, dopplerAxis, zeros(NumChirps, NumSamples/2));
axis xy; colormap('jet'); colorbar;
xlabel('Range (m)', 'Color','w');
ylabel('Velocity (m/s)', 'Color','w');
set(gca, 'XColor','w', 'YColor','w', 'Color','k');
hold on;
yline(0, '--w', 'Zero Doppler');

% ===== Animation Loop =====
for f = 1:NumFrames
    
    frame = squeeze(rawData(f, :, :));

    % Range FFT
    r_fft = fft(frame, NumSamples, 2);
    r_fft = r_fft(:, 1:NumSamples/2);

    % Doppler FFT
    d_fft = fftshift(fft(r_fft, NumChirps, 1), 1);

    % Convert to dB
    RD_dB = 20*log10(abs(d_fft) + 1e-6);

    % Remove zero Doppler visually
    zeroBin = ceil(NumChirps/2) + 1;
    RD_dB(zeroBin, :) = min(RD_dB(:));

    % Dynamic scaling (important for visibility)
    lo = prctile(RD_dB(:), 50);
    hi = max(RD_dB(:));

    % Update plot (NO new figure)
    set(h, 'CData', RD_dB);
    clim([lo, hi]);

    title(sprintf('Range-Doppler Map (Frame %d / %d)', f, NumFrames), 'Color','w');

    drawnow;

    pause(0.05); % adjust speed (0.01 = fast, 0.1 = slow)
end