data = load("data1.mat");
rawData = data.overall_data(1:3:end,:,:); % if this is intentional

[NumFrames, NumChirps, NumSamples] = size(rawData);

% Storage: (range bins × total chirps)
dopplerSpectrogram = zeros(NumSamples/2, NumFrames * NumChirps);

col = 1;

for f = 1:NumFrames
    
    frame = squeeze(rawData(f,:,:));  % [chirps × samples]

    % Remove DC
    frame = frame - mean(frame, 2);

    % ===== Range FFT =====
    r_fft = fft(frame, NumSamples, 2);
    r_fft = r_fft(:, 1:NumSamples/2);   % keep positive range bins

    % ===== Doppler FFT (across chirps) =====
    d_fft = fftshift(fft(r_fft, NumChirps, 1), 1);

    RD = abs(d_fft);   % Range-Doppler map [chirps × range]

    % ===== Store as spectrogram =====
    for r = 1:(NumSamples/2)
        dopplerSpectrogram(r, col:col+NumChirps-1) = RD(:, r)';
    end

    col = col + NumChirps;
end

%% Plot
figure;
imagesc(abs(dopplerSpectrogram));
axis xy;
xlabel('Chirps (stacked frames)');
ylabel('Range Bin');
title('Range-Doppler Spectrogram');
colorbar;
clim([0 10]);  % adjust if needed