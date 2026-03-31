data = load("data1.mat")
rawData = data.overall_data(1:3:end,:,:);

% Take only 1 receiver


[NumFrames, NumChirps, NumSamples] = size(rawData);

rangeSpectrogram = zeros(NumSamples, NumFrames * NumChirps);

chirpCount = 1;

for f = 1:NumFrames
    for c = 1:NumChirps
        
        chirpSignal = squeeze(rawData(f, c, :));
        r_fft = fft(chirpSignal, NumSamples);
        
        rangeSpectrogram(:, chirpCount) = abs(r_fft);
        
        chirpCount = chirpCount + 1;
    end
end

rangeSpectrogram(1,:) = 0;
figure;
imagesc(abs(rangeSpectrogram(1:32,:)));
axis xy;
xlabel('Chirps (1 to 12800)');
ylabel('Range Bin');
title('Range FFT Spectrogram (Downsampled Frames)');
colorbar;
clim([0 5])