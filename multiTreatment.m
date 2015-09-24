clear;

inputDir = 'input';
outputDir = 'output';

imageFiles = dir(fullfile(inputDir,'*.jpg'));
LengthFiles = length(imageFiles);

for i = 1:LengthFiles
    name = imageFiles(i).name;
    inputPath = [inputDir '/' name];
    outputPath = [outputDir '/' name];
    fprintf('-----------%s------------\n', name);
    pretreatment(inputPath, outputDir, name);
    fprintf('*********************************\n');
end