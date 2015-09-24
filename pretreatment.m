% 预处理图片
function pretreatment(inputPath, outputDir, name)
	%打开图片
	originalImage = imread(inputPath);
	img = originalImage;

	%缩放图片
	img = imresize(originalImage, [54*4, 85*4]);	%银行卡长宽: 85*54

	%灰度化
	grayImage = rgb2gray(img);
	img = grayImage;
	imwrite(img, [outputDir '/gray_' name]);

	% 求边缘
	edgeImage = edge(img, 'prewitt', 0.1);
	img = edgeImage;
	imwrite(img, [outputDir '/edge_' name]);

	%XY轴膨胀
	SE = strel('rectangle',[2, 30]);
	img = imdilate(img,SE);
	imwrite(img, [outputDir '/imdilate_' name]);

	row = size(img, 1);	%行
	column = size(img, 2);	%列

	%去掉长度小于80%的行
	rowThread = floor(0.8 * column);
	for rowIndex = 1:row
		rowElements = img(rowIndex, :);
		rowElementsCount = sum(rowElements);
		if rowElementsCount < rowThread
			img(rowIndex, :) = 0;
		end
	end

	imwrite(img, [outputDir '/cutShortRow_' name]);

	%去掉长度小于10%的列
	columnThread = floor(0.08 * row);
	for columnIndex = 1: column
		columnElements = img(:, columnIndex);
		columnElementsCount = sum(columnElements);
		if columnElementsCount < columnThread
			img(:, columnIndex) = 0;
		end
	end

	imwrite(img, [outputDir '/cutShortColumn_' name]);

	% 去掉小于4000的区域
	img = bwareaopen(img, 4000);
	imwrite(img, [outputDir '/bigArea_' name]);
	% return;

	% 获取区域
	L = bwlabel(img);
	layer = max(max(L)); 

	var cropGrayImage;
	var cropImage;

	% 获取区域
	for i = 1:layer
		layerImage = (L == i);
		box = regionprops(layerImage,'BoundingBox');
		rect = box.BoundingBox;
		if rect(2) < 100 || rect(2) > 200
			break;
		end
		if rect(1) < 20
			rect(1) = 20;
		end
		if rect(1) + rect(3) > 330
			rect(3) = 330 - rect(1);
		end
		cropImage = imcrop(edgeImage, rect);
		cropGrayImage = imcrop(grayImage, rect);
		imwrite(cropImage, [outputDir '/cropImage_' name]);
	end

	%Y轴膨胀
	img = cropImage;
	SE = strel('rectangle',[20, 5]);
	img = imdilate(img,SE);
	imwrite(img, [outputDir '/localImdilate_' name]);

	rectArr = [];
	% name
	%获取小区域: 获取面积大于200的区域
	L = bwlabel(img);
	layer = max(max(L));
	for i = 1:layer
		layerImage = (L == i);
		areaSize = regionprops(layerImage);
		if areaSize.Area > 200
			box = regionprops(layerImage,'BoundingBox');
			rect = box.BoundingBox;
			rectArr = [rectArr; rect];
		end
	end

	fprintf('rectArr: \n');
	rectArr

	validRectArr = zeros(4, 4);

	%切成四块的
	if size(rectArr, 1) == 4
		fprintf('Has four section: %s\n', name);
		bRight = 1;
		for index = 1: 4
			if rectArr(index, 3) < 55 || rectArr(index, 3) > 65
				bRight = 0;
				break;
			end
		end
		if bRight == 1
			validRectArr = rectArr;
		else

			return;
		end
	% 切成三块: % 切成其它块的就暂不管了
	elseif size(rectArr, 1) == 3
		fprintf('Enter three: \n');
		startX = 0;
		startIndex = 0;
		evenWidth = 0;

		validCount = 0;
		notValidIndex = 0;


		for index = 1: 3
			if rectArr(index, 3) > 55 && rectArr(index, 3) < 65
				validCount = validCount + 1;
				if notValidIndex == 0
					startX = startX + rectArr(index, 1) - (index - 1) * 72;
				else
					startX = startX + rectArr(index, 1) - index * 72;
				end
				
				evenWidth = evenWidth + rectArr(index, 3);
			else
				notValidIndex = index;
			end
		end

		startX = startX / 2;
		evenWidth = evenWidth / 2;
		fprintf('startX: %f\n', startX);
		fprintf('evenWithd: %f\n', evenWidth);


		fprintf('validCount %d\n', validCount);
		if validCount ~= 2
			return
		else
			for index = 1: 3
				if index < notValidIndex
					validRectArr(index, :) = rectArr(index, :);
				elseif index == notValidIndex
					validRectArr(index, :) = rectArr(notValidIndex, :);
					validRectArr(index, 1) = startX + 72 * (index - 1);
					validRectArr(index, 3) = evenWidth;
					validRectArr(index+1, :) = rectArr(notValidIndex, :);
					validRectArr(index+1, 1) = startX + 72 * index;
					validRectArr(index+1, 3) = evenWidth;
				else
					validRectArr(index+1, :) = rectArr(index, :);
				end
			end
		end
	end
	
	fprintf('Valid rect: \n');
	validRectArr

	for rectIndex = 1: 4
		fprintf('crop image for index: %d\n', rectIndex);
		littleCropImage = imcrop(cropGrayImage, validRectArr(rectIndex, :));
		imwrite(littleCropImage, [outputDir '/littleCropImage_' name num2str(rectIndex) '.png']);
		%平均切成四份
		imageWidth = size(littleCropImage, 2);
		imageHeight = size(littleCropImage, 1);
		perImageWidth = imageWidth / 4;
		for perImageIndex = 1:4
			Sx = perImageWidth * (perImageIndex - 1);
			perSmallestImage = imcrop(littleCropImage, [Sx, 0, perImageWidth, imageHeight]);
			imwrite(perSmallestImage, ['source/littleCropImage_' name num2str(rectIndex) '_' num2str(perImageIndex) '.png']);
		end
	end
	
	


	%显示
	% imshow(img);
	