#!/usr/bin/octave -qf
# usage:
# oCorr.m dataFile1 dataFile2 selection precision

arg_list = argv();
xFile = arg_list{1};
yFile = arg_list{2};
subjSelectedFile = arg_list{3};
if nargin > 3
	precision = arg_list{4};
else
	precision = "4";
end
formatString = ["%.",precision,"f"];
x = load("-ascii",xFile);
y = load("-ascii",yFile);
subjSelected = logical(load("-ascii",subjSelectedFile));

x = x(subjSelected,:);
y = y(subjSelected,:);

corrXY = corr(x,y);
nrRows=size(corrXY,1);
nrCols=size(corrXY,2);
if nrRows == 1
	printf(formatString, corrXY);
else
	for rowNr = 1:nrRows
		for colNr = 1:nrCols-1
			printf(formatString,corrXY(rowNr,colNr));
			printf(",");
		end
		printf([formatString,"\n"],corrXY(rowNr,nrCols));
	end
end
