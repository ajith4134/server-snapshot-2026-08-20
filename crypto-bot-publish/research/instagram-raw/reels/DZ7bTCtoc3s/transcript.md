# Transcript — Video by datasciencefoundry

Channel: datasciencefoundry  |  Duration: 00:00
Source: https://www.instagram.com/reel/DZ7bTCtoc3s/
Transcript source: whisper:small

**[00:00]** PCA or Principal Component Analysis is a way to take data with many features and boil it down to just a few. Real datasets often contain hundreds of features, many of them highly correlated, effectively measuring the same underlying information. PCA is built to cut through exactly that, to see how let's use just three features, a cloud of points in three dimensions. But there's a catch, the three features are on completely different scales, so we first

**[00:30]** center and scale them so no single feature dominates PCA just because of its size. Now PCA looks for the single direction along which the points spread out the most. That becomes the first principal component. Then it finds the next most spread at a right angle to the first, and so on, one new axis per dimension. Because they are perpendicular, the new components are uncorrelated. Mathematically, these components are the eigenvectors of the data's covariance matrix. They define the axes along which the data varies the most.

**[01:04]** And each of these new axes is a weighted blend of all the original features, not any single one. So far nothing has been thrown away. All PCA has done is rotate the data onto these new axes. Now comes the simplification. Since the first two components hold most of the spread, we drop the third and project the points onto the first two, still keeping most of the information in just two dimensions. So how do you decide how many components to keep? You plot the variance each one explains and look for the point where adding another barely

**[01:37]** helps, the elbow. And this scales far beyond three features, hundreds of them can collapse to just two or three. Two quick cautions though. First, PCA only chases variance, but the direction with the biggest spread isn't always the one that matters most for your task. And second, PCA is linear. It can only rotate and flatten. So data with curved or tangled structure may need nonlinear tools instead. But the core idea stays simple.

**[02:07]** Standardize the data, rotate it onto the directions of greatest variation and keep just those few a much simpler picture.