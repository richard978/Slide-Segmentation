function [features] = getFeatures(scaleImage,classifier,x)
    bw = rgb2gray(scaleImage);
    lev = graythresh(bw);
    % 二�?�化
    bw = ~imbinarize(bw,lev);
    % 删去过小的连通区�?
    bw = bwareaopen(bw,15);
    cenStatus = regionprops(bw,'BoundingBox');

    % �?个区域中每个字符的垂直位�?
    temp = [];
    for i=1:length(cenStatus)
        temp(i) = cenStatus(i).BoundingBox(2)+cenStatus(i).BoundingBox(4);
    end
    
    % OCR识别字母
    ocrResults = ocr(rgb2gray(scaleImage),'TextLayout','Line');
    text = ocrResults.Text;
    text = text((text>='a'& text<='z')|(text>='A'& text<='Z'));
    bw = rgb2gray(scaleImage);
    bw = ~imbinarize(bw,lev+0.1);

    % 删去图片中置信度高的字母内容
    for i=1:size(ocrResults.CharacterBoundingBoxes,1)
        if(ocrResults.CharacterConfidences(i)>0.5)
        if((ocrResults.Text(i)>='a'&&ocrResults.Text(i)<='z')||(ocrResults.Text(i)>'A'&&ocrResults.Text(i)<'Z')||(ocrResults.Text(i)>='0'&&ocrResults.Text(i)<='9'&&ocrResults.Text(i)~='2')...
                ||ocrResults.Text(i)==',')
            bw((ocrResults.CharacterBoundingBoxes(i,2)):(ocrResults.CharacterBoundingBoxes(i,2)+ocrResults.CharacterBoundingBoxes(i,4)) ...
                ,(ocrResults.CharacterBoundingBoxes(i,1)):(ocrResults.CharacterBoundingBoxes(i,1)+ocrResults.CharacterBoundingBoxes(i,3))) = 0;
        end
        end
    end

    % 清理图片并膨�?单个字符
    bw = bwareaopen(bw,15);
    bw = imdilate(bw,strel('Line',4,90));
%     bw = imdilate(bw,strel('Line',2,0));

    % 取出剩下的字符并分类
    cutFonts = regionprops(bw,'BoundingBox');
    deleteIdx = [];
    for i=1:length(cutFonts)
        for j=1:length(cutFonts)
            if cutFonts(i).BoundingBox(1)>cutFonts(j).BoundingBox(1)&&cutFonts(i).BoundingBox(2)>cutFonts(j).BoundingBox(2)...
                &&cutFonts(i).BoundingBox(1)+cutFonts(i).BoundingBox(3)<cutFonts(j).BoundingBox(1)+cutFonts(j).BoundingBox(3)...
                &&cutFonts(i).BoundingBox(2)+cutFonts(i).BoundingBox(4)<cutFonts(j).BoundingBox(2)+cutFonts(j).BoundingBox(4)
                deleteIdx = [deleteIdx i];
            end
        end
    end
    cutFonts(deleteIdx) = [];
        
    if ~isempty(cutFonts)
        arrayY = zeros(size(cutFonts,1),1);
        for j=1:size(cutFonts,1)
            arrayY(j) = cutFonts(j).BoundingBox(4);
        end
        idx = find(arrayY==max(arrayY));
        cenHeight = cutFonts(idx(1)).BoundingBox(2)+cutFonts(idx(1)).BoundingBox(4)/2;
    end
    recogText = {};
    for j=1:length(cutFonts)
        posY = cutFonts(j).BoundingBox(2)+cutFonts(j).BoundingBox(4)/2;
        if (cutFonts(j).BoundingBox(3)<40&&cutFonts(j).BoundingBox(4)<40)&&abs(posY-cenHeight)<10
            tempCut = imcrop(rgb2gray(scaleImage),cutFonts(j).BoundingBox);
            if size(tempCut,1)>40
                tempCut = imresize(tempCut,39/size(tempCut,1));
            end
            if size(tempCut,2)>40
                tempCut = imresize(tempCut,39/size(tempCut,2));
            end
            padTempCut = padarray(tempCut,[floor((40-size(tempCut,1))/2) floor((40-size(tempCut,2))/2)],255,'post');
            padTempCut = padarray(padTempCut,[ceil((40-size(tempCut,1))/2) ceil((40-size(tempCut,2))/2)],255,'pre');
            featureTest = extractHOGFeatures(padTempCut,'CellSize',[8,8]);
            classified = predict(classifier,featureTest);
            recogText = [recogText,classified];
        end
    end
%     if(x==6)
%     if(~isempty(recogText))
%         id = find(recogText=='theta');
%         for k = 1:size(id,2)
%             figure;imshow(imcrop(rgb2gray(scaleImage),cutFonts(id(k)).BoundingBox));
%         end
%     end
%     end
    % 生成特征�?
    if(isempty(recogText))
        sumFormula = 0;
    else
        sumFormula = 5*(2*sum(recogText=='sigma')+0.5*sum(recogText=='theta')+0.5*sum(recogText=='miu')+0.5*sum(recogText=='delta')+sum(recogText=='equ')+0.5*sum(recogText=='arrow')+sum(recogText=='plus')+...
                0.5*sum(recogText=='minus')+sum(recogText=='greater')+sum(recogText=='less')+0.1*(sum(recogText=='bracket left')+sum(recogText=='bracket right')));
    end
    features = [sumFormula*flucRate(temp)/5 20*(length(text)/length(ocrResults.Text)) size(scaleImage,2)/size(scaleImage,1)];
%     features = [2*sum(recogText=='sigma') sum(recogText=='equ') sum(recogText=='arrow') sum(recogText=='plus') ...
%                 sum(recogText=='greater') sum(recogText=='less') 0.1*sum(recogText=='bracket') flucRate(temp) 5*(1-length(text)/length(ocrResults.Text)) size(scaleImage,1)*size(scaleImage,2)/200 size(scaleImage,2)/size(scaleImage,1)];
    features(isnan(features))=0;
end