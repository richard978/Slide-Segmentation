% 重新训练分类�?
% classifier = formulaTrain();
% totalClassifier = initialTrain(classifier);
% save classifier_save classifier;
% save totalClassifier_save totalClassifier;

% 读取现有训练过的分类�?
load classifier_save;
load totalClassifier_save;
% 读取图片
img = imread('test_data/102.jpg');

% allnames=struct2cell(dir('test_data/*.jpg'));
% [k,len]=size(allnames); 
% for num=1:len
% name = allnames{1,num};
% img = imread(['test_data/',name]);

% 统一大小并转化为灰度�?
img = imresize(img,500/size(img,1));
RGB = img;
img = rgb2gray(img);

% 拆分二�?�图中的非连接部分，splitBbox的第二个参数为距离像素个�?
img = splitBbox(img,45);
img2 = img;
status = regionprops(img2,'BoundingBox','Area');
figure;imshow(img2);hold on;

% 删除重叠包围�?
deleteIdx = [];
for i=1:length(status)
    for j=1:length(status)
        if status(i).BoundingBox(1)>=status(j).BoundingBox(1)&&status(i).BoundingBox(2)>status(j).BoundingBox(2)...
            &&status(i).BoundingBox(1)+status(i).BoundingBox(3)<=status(j).BoundingBox(1)+status(j).BoundingBox(3)...
            &&status(i).BoundingBox(2)+status(i).BoundingBox(4)<status(j).BoundingBox(2)+status(j).BoundingBox(4)
            deleteIdx = [deleteIdx i];
        end
    end
end
for i=1:size(deleteIdx,1)
    img2(status(deleteIdx(i)).BoundingBox(2):(status(deleteIdx(i)).BoundingBox(2)+status(deleteIdx(i)).BoundingBox(4)) ...
        ,status(deleteIdx(i)).BoundingBox(1):(status(deleteIdx(i)).BoundingBox(1)+status(deleteIdx(i)).BoundingBox(3))) = 0;
end
status(deleteIdx) = [];

% RGB2 = RGB;
% idx = find([status.Area]>200);
% % 单独取出每个部分并分�?
% for i=1:length(idx)
%     testImage = imcrop(RGB,status(idx(i)).BoundingBox);
% %     figure;imshow(testImage);
%     % 获取特征并分�?
%     featureTest = getFeatures(testImage,classifier,i);
%     predictIndex = predict(totalClassifier,featureTest);
%     str = ['id:' num2str(idx(i)) ' feature:' num2str(featureTest) ' ' char(predictIndex)];
% %     disp(str);
% %     RGB2 = insertObjectAnnotation(RGB2, 'rectangle', status(idx(i)).BoundingBox, idx(i));
%     if char(predictIndex) == "formula"
% %         str = ['id:' num2str(idx(i)) ' feature:' num2str(featureTest)];
% %         disp(str);
% %         rectangle('position',status(idx(i)).BoundingBox,'edgecolor','r');
%         RGB2 = insertObjectAnnotation(RGB2, 'rectangle', status(idx(i)).BoundingBox, idx(i));
% %         RGB2 = insertShape(RGB2,'rectangle',status(idx(i)).BoundingBox,'LineWidth',2,'Color','red');
%     end
% end
% figure;imshow(RGB2);
% imwrite(img2,['test_data\binaryImage\',num2str(num) '.jpg']);
% end