% SIFT Tutorial
%
% Thomas F. El-Maraghi
% May 2004
%
% This tutorial demonstrates the Scale Invariant Feature Transform (SIFT)
% developed by David G. Lowe.  The material in this tutorial is based on
% the papers:
%
% [1] David G. Lowe, "Distinctive Image Features from Sacle-Invariant Keypoints",
%     accepted for publicatoin in the International Journal of Computer
%     Vision, 2004.
% [2] David G. Lowe, "Object Recognition from Local Scale-Invariant Features",
%     Proc. of the International Conference on Computer Vision, Corfu,
%     September 1999.
% [3] David G. Lowe, "Local feature view clustering for 3D object recognition",
%     IEEE Conference on Computer Vision and Pattern Recognition, Kauai, Hawaii
%     (December 2001), pp. 682-688.


% Clear everything to avoid confilicts with previous work
clear;
close all;

% Add the SIFT tutorial directory to the matlab path.  You will have
% to change the value of tutorial_path to the directory where you
% unpacked the tutorial files.
global matlabVisRoot;
matlabVisRoot = '/opt/info/courses/COMP61342/matlab';
tutorial_path = [matlabVisRoot '/utvisToolbox/tutorials/SIFTtutorial'];
addpath( tutorial_path );
im_path = [tutorial_path,'/images/'];

% additional paths added by shaobo
addpath( [matlabVisRoot '/utvisToolbox/file'] );
addpath( [matlabVisRoot '/iseToolbox/pyrTools'] );

% Set the number of octaves and intervals per octave for pyramid used
% by the SIFT transform.
octaves = 4;
intervals = 2;

% Determine how the tutorial handles cached keypoint files.
%
% If you set cache equal to 1 (the default) then the tutorial uses
% cached versions of the keyoints if they exist.  This can significantly
% speed up the tutorial, as recomputing the keypoints can take a long time.
%
% If you set cache equal to 2, then you force the tutorial to recompute
% all of the keypoint files.  This can be useful if you delete the
% cached versions by mistake.
%
% If you set cache equal to 3, then the tutorial runs with the supplied
% keypoint files generated by David Lowe's keypoint demo program.
%
% Note: the first example computes the keypoints whatever the value
% of cache.
cache = 1;


%
% EXAMPLE 1: The Einstein Image
%

% Compute keypoints for the einstein image.  The SIFT function will show intermediate results
% of the computation.  Follow allong in the code as it executes.
fprintf( 2, 'Computing keypoints for the einstein image.\n' )
[im_path 'einstein.pgm']
im1 = pgmRead( [im_path,'einstein.pgm'] )./255;
[ pos1 scale1 orient1 desc1 ] = SIFT( im1, octaves, intervals, ones(size(im1)), 0.02, 10.0, 2 );

% Add the keypoints to a database
fprintf( 2, 'Adding einstein keypoints to database.\n' );
db = add_descriptors_to_database( im1, pos1, scale1, orient1, desc1 );

% Create a rotated version of the einstein image and compute keypoints for it
th = pi/4;
fprintf( 2, 'Rotating image by %g radins and computing keypoints.\n', th );
A = [ cos(th) -sin(th) 0; sin(th) cos(th) 0; 0 0 1 ];
[im2 A] = imWarpAffine( im1, A, 0 );
im2(find(isnan(im2)))=0;
[ pos2 scale2 orient2 desc2 ] = SIFT( im2, octaves, intervals );
fig = figure;
showIm(im2);
hold on;
display_keypoints( pos2, scale2, orient2, 'y' );
resizeImageFig( fig, size(im2), 2 );
fprintf( 2, 'The keypoints for the rotated eninstein image (2x scale).\n' );
fprintf( 2, 'Press any key to continue...\n\n' );
pause;
close(fig);

% Perform hough transform to find constraints which agree on a similarity transformation
% between the rotated einstein image and the original image.
fprintf( 2, 'Performing hough transform for rotated image...\n' );
[im_idx trans theta rho idx nn_idx wght] = hough( db, pos2, scale2, orient2, desc2, 1.5 );

% Robustly fit an affine tranformation to the largest peak of the hough tranformation
fprintf( 2, 'Fitting affine transform to largest peak of hough transform...\n' );
[max_val k] = max(wght);
c_pos = pos2(idx{k},:);
c_desc = desc2(idx{k},:);
c_wght = scale2(idx{k}).^-2;
nn_pos = db.pos(nn_idx{k},:);
[aff outliers] = fit_robust_affine_transform( c_pos', nn_pos', c_wght', 0.75 );

% Display the computed transformation and the actual tranformation
fprintf( 2, 'Computed affine transformation from rotated image to original image:\n' );
disp(aff);
fprintf( 2, 'Actual transformation from rotated image to original image:\n' );
disp(A);
fprintf( 2, 'Press any key to continue...\n\n' );
pause;

% Clear stuff
clear im1 im2 pos1 pos2 scale1 scale1 orient1 orient2 desc1 desc2 db aff outliers c_pos c_desc c_wght nn_pos


%
% EXAMPLE 2: Architectural Images
%

% Load in the images.
im_names = { ...
   'wadham001'; ...  % Reference view
   'wadham002'; ...
   'wadham003'; ...
   'wadham004'; ...
   'wadham005'; ...
};
n = length(im_names);
wadham_view = cell(1,n);
wadham_pos = cell(1,n);
wadham_orient = cell(1,n);
wadham_scale = cell(1,n);
wadham_desc = cell(1,n);
for k = 1:n
   [ wadham_pos{k} wadham_scale{k} wadham_orient{k} wadham_desc{k} wadham_view{k} ] = SIFT_from_cache( im_path, im_names{k}, cache, octaves, intervals );
end

% Add the first image to a database as the reference view
fprintf( 2, 'Adding reference view %s to database.\n\n', im_names{1} );
db = add_descriptors_to_database( wadham_view{1}, wadham_pos{1}, wadham_scale{1}, wadham_orient{1}, wadham_desc{1} );

% Loop over the remaining views
for j = 2:n

   % Compute hough transform back to the reference view
   fprintf( 2, 'Performing hough transform for view %s...\n', im_names{j} );
	[im_idx trans theta rho idx nn_idx wght] = hough( db, wadham_pos{j}, wadham_scale{j}, wadham_orient{j}, wadham_desc{j}, 10.0 );

   % Robustly fit an affine transformation to the largest peak of the hough tranformation
   fprintf( 2, 'Fitting affine transform to largest peak of hough transform...\n' );
   [max_val k] = max(wght);
   c_pos = wadham_pos{j}(idx{k},:);
   c_desc = wadham_desc{j}(idx{k},:);
   c_wght = wadham_scale{j}(idx{k}).^-2;
	nn_pos = db.pos(nn_idx{k},:);
   [aff outliers] = fit_robust_affine_transform( c_pos', nn_pos', c_wght', 0.75 );

   % Dispaly the computed transformation
   fprintf( 2, '\nComputed affine transformation from this view to reference view:\n' );
   disp(aff);

   % Display the view and reference view, showing features the features that match between
   % the images.  Over the reference view, overlay the constraints and indicated whether they
   % are inliers or outliers to the fit.
   fig = figure;
   clf;
   subplot(1,2,1);
   showIm( wadham_view{j} );
   hold on;
   plot( c_pos(:,1), c_pos(:,2), 'y+' );
   title( 'Nearest Neighbours' );
   subplot(1,2,2);
   showIm( db.im{1} );
   hold on;
   plot( nn_pos(:,1), nn_pos(:,2), 'b+' );
   pts = aff * [c_pos'; ones(1,size(c_pos,1))];
   pts = pts(1:2,:)';
   plot( pts(:,1), pts(:,2), 'go' );
   plot( pts(outliers,1), pts(outliers,2), 'ro' );
   title( 'Robust Affine Alignment' );
   fprintf( 2, '\tView features (yellow +)\n\tReference view features (blue +)\n\n' );
   fprintf( 2, '\t%d constraints\n\t%d inliers (green o)\n\t%d outliers (red o)\n\n', size(pts,1), size(pts,1)-length(outliers), length(outliers) );
   fprintf( 2, 'Press any key to continue...\n' );
   pause;
   close(fig);

   % Display the original view, the reference view, the aligned version of the origianl view,
   % and the reference view minus the aligned view.
   fig = figure;
   clf;
   subplot(2,2,1);
   showIm( wadham_view{j} );
   title( 'Orignial View' );
   subplot(2,2,2);
   showIm( db.im{1} );
   title( 'Reference View' );
   subplot(2,2,3);
   warped = imWarpAffine( wadham_view{j}, inv(aff), 1 );
   warped( find(isnan(warped)) ) = 0;
   showIm( warped );
   title( 'Aligned View' );
   subplot(2,2,4);
   showIm( db.im{1} - warped );
   title( 'Reference minus Aligned View' );
   fprintf( 2, 'Press any key to continue...\n\n' );
   pause;
   close(fig);
end

% Clear stuff
clear wadham_view wadham_pos wadham_scale wadham_orient wadham_desc db aff c_pos c_desc c_wght nn_pos


%
% EXAMPLE 3: Object Recognition
%

% Load the images
im_names = { ...
   'nutshell0003'; ...  % Model of Java book
   'phone0003'; ...     % Model of coreless phone
   'phone0007'; ...
   'nutshell0007'; ...
   'phone0018'; ...
   'nutshell0008'; ...
   'phone0005'; ...
   'nutshell0009'; ...
   'phone0017'; ...
   'nutshell0012'; ...
   'phone0016'; ...  % Does not find compute correct affine transform for this image
   'nutshell0004'; ...
   'nutshell0010'; ...
   'nutshell0011'; ...
};
num_obj = 2;
n = length(im_names);
obj_im = cell(1,n);
obj_mask = cell(1,n);
obj_pos = cell(1,n);
obj_scale = cell(1,n);
obj_orient = cell(1,n);
obj_desc = cell(1,n);
for k = 1:n
   [ obj_pos{k} obj_scale{k} obj_orient{k} obj_desc{k} obj_im{k} obj_mask{k} ] = SIFT_from_cache( im_path, im_names{k}, cache, octaves, intervals );
end

% Add the models to the database.  There are two models, a phone and a Java
% book, both segmented from the background.
db = empty_descriptor_database;
for k = 1:num_obj
   fprintf( 2, 'Adding keypoints for image %s to database.\n', im_names{k} );
   db = add_descriptors_to_database( obj_im{k}, obj_pos{k}, obj_scale{k}, obj_orient{k}, obj_desc{k}, db );
end

% Loop over the remaining images
for j = (num_obj+1):n

   % Perform hough tranform between the test image and the database
   fprintf( 2, '\nPerforming hough transform for image %s.\n', im_names{j} );
	[im_idx trans theta rho idx nn_idx wght] = hough( db, obj_pos{j}, obj_scale{j}, obj_orient{j}, obj_desc{j}, 1.5 );

   % Determine if a match is found
   if isempty(im_idx)
      fprintf( 2, 'No match.\n' );
      fprintf( 2, 'Press any key to continue...\n' );
      pause;
   else
      matches = length(im_idx);
      aff = cell(1,matches);
      c_pos = cell(1,matches);
      nn_pos = cell(1,matches);
      outliers = cell(1,matches);

      % Select the match that has the largest peak in the hough transform
      fprintf( 2, 'Determining best match.\n' );
      [max_wght k] = max(wght);
      for m = k
         c_pos{m} = obj_pos{j}(idx{m},:);
         c_desc = obj_desc{j}(idx{m},:);
         c_wght = obj_scale{j}(idx{m}).^-2;
         nn_pos{m} = db.pos(nn_idx{m},:);

         % Robustly fit an affine tranformaton between the image and the model if enough features
         % were matched.
         fprintf( 2, 'Matches %s.\n', im_names{im_idx(m)} );
         if length(idx{m}) < 3
            fprintf( 2, 'Too few points to fit affine transform.\n' );
         else
            fprintf( 2, '\nComputed affine transformation from %s to %s:\n', im_names{j}, im_names{im_idx(m)} );
            [aff{m} outliers{m} robustError] = fit_robust_affine_transform( c_pos{m}', nn_pos{m}', c_wght', 0.75 );
            disp(aff{k});
			   fprintf( 2, '\tImage features (yellow +)\n\tModel features (blue +)\n\n' );
            fprintf( 2, '\t%d constraints\n\t%d inliers (green o)\n\t%d outliers (red o)\n\n', size(c_pos{m},1), size(c_pos{m},1)-length(outliers{m}), length(outliers{m}) );
         end

         % Display the image, the model, and the location of the model in the
         % image according to the computed transfromation.
         fig = figure;
         clf;
         subplot(1,3,1);
         showIm( obj_im{j}, [0 1] );
         hold on;
         plot( c_pos{m}(:,1), c_pos{m}(:,2), 'y+' );
         title( 'Image' );
         subplot(1,3,2);
         im = db.im{im_idx(m)};
         im(find(obj_mask{im_idx(m)}==0)) = 0;
         showIm( im, [0 1] );
         hold on;
         plot( nn_pos{m}(:,1), nn_pos{m}(:,2), 'b+' );
         title( 'Model' );
         if length(idx{m}) >= 3
            pts = aff{m} * [c_pos{m}'; ones(1,size(c_pos{m},1))];
            pts = pts(1:2,:)';
            plot( pts(:,1), pts(:,2), 'go' );
            plot( pts(outliers{m},1), pts(outliers{m},2), 'ro' );
            aligned = imWarpAffine( obj_mask{im_idx(m)}, aff{m}, 1 );
            aligned(find(isnan(aligned))) = 0;
            subplot(1,3,3);
            showIm( obj_im{j} - aligned );
            title( 'Location' );
         end
         fprintf( 2, 'Press any key to continue...\n' );
         pause;
         close(fig);
      end

   end
end

% Clear stuff
clear obj_im obj_mask obj_pos obj_scale obj_orient obj_desc db aff c_pos c_desc c_wght nn_pos

