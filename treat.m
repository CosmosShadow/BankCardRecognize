originalImage = imread('1.jpg');
img = originalImage;

% %缩放图片
% img = imresize(img, 0.4);

%灰度化
img = rgb2gray(img);
imwrite(img, 'gray.png');

% 求边缘
img = edge(img, 'prewitt', 0.1);
imwrite(img, 'edge.png');
return;

%灰度反转
img = imcomplement(img);
imwrite(img, 'inverseGray.png');

%去背景
background = imopen(img, strel('disk',15));
img = imsubtract(img, background);
imwrite(img, 'withOutBackground.png');

%增加对比度
treatedGrayImage = imadjust(img,stretchlim(img),[0 1]);
img = treatedGrayImage;
imwrite(img, 'hightLight.png');

imshow(img);
return;

%二值化: 自动阀值
level = graythresh(img);
level = level * 1.2;	%应防止大于1.0
if level >= 1.0
	level = 0.9;
end
binaryImage = im2bw(img, level);
img = binaryImage;

%XY腐蚀去小点
SE = strel('rectangle',[2, 2]);
img = imerode(img,SE);

%去上下白边
row = size(img, 1);	%行
column = size(img, 2);	%列
threadOfHeight = floor(row/3);
for index = 1: column
	colomnElements = img(:, index);
	topWhiteElements = sum(colomnElements(1: threadOfHeight));
	bottomWhiteElements = sum(colomnElements(row - threadOfHeight + 1: end));
	%清理上边
	if topWhiteElements ~= threadOfHeight
		for j = 1: threadOfHeight
			if colomnElements(j) == 1
				img(j, index) = 0;
			else
				break;
			end
		end
	end
	%清理下边
	if topWhiteElements ~= threadOfHeight
		for j = row: -1: row - threadOfHeight + 1
			if colomnElements(j) == 1
				img(j, index) = 0;
			else
				break;
			end
		end
	end
end

%XY轴膨胀
SE = strel('rectangle',[13, 3]);
img = imdilate(img,SE);

% imwrite(img, outputPath);
% return;

%Y轴腐蚀
SE = strel('rectangle',[10, 1]);
img = imerode(img,SE);

% 获取区域
L = bwlabel(img);
layer = max(max(L)); 

% 获取面积大于500的区域
for i = 1:layer
	layerImage = (L == i);
	areaSize = regionprops(layerImage);
	if areaSize.Area > 500
		box = regionprops(layerImage,'BoundingBox');
		rect = box.BoundingBox;
		cropImage = imcrop(treatedGrayImage, rect);
		cropStandardSizeImage = imresize(cropImage, [80, 30]);
		imwrite(cropStandardSizeImage, [outputPath '._' num2str(i) '.png']);
	end
end

%显示
% imshow(img);
