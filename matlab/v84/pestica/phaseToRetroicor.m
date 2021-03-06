function phaseToRetroicor(varargin)

if nargin == 7
    [currentDir, ep2d_filename, card, resp, M, slice_timing, mask_filename] = varargin{:};
else
    error(['Only ',num2str(narargin),' parameters were entered']);
end


% run_phaseToRetroicor $MCRROOT . ${mcFunc}+orig cardphase_pestica.dat respphase_pestica.dat 2 seq-asc ${mcFunc}.brain+orig
% convert string inputs to function requirements
ep2d_filename = fullfile(currentDir,ep2d_filename);
card = textread(fullfile(currentDir,card));
resp = textread(fullfile(currentDir,resp));
M = str2double(M);
mask_filename = fullfile(currentDir,mask_filename);
% function matlab_retroicor(ep2d_filename,card,resp,M,slice_timing,mask_filename)
% This function performs the 2nd-order RETROICOR algorithm on an epi dataset, using
% input vectors for physiologic data, and returns coupling coefficients and the corrected image
% created for PESTICA distribution
% variance normalization prior to calculation results in statistic values
% use stat=sqrt(sum(im_ca.^2+im_cb.^2,4)), which follows a
% 2*M-th order Chi-square distribution (where M is order of correction, here M=2)

%for simulated data: cardph=unifrnd(0,3.14159*2,zdim,tdim); card=sin(cardph);
if (exist('card','var')==0 | exist('resp','var')==0 | exist('ep2d_filename','var')==0)
  disp('must input three parameters: filename of EPI data, cardiac, and respiratory traces');
  disp('     fourth optional paramter = order of correction (default=2, which is sin(ph)+sin(2*ph)+cos...)');
  disp('     fifth optional paramter = slice acquisition timing string (''alt-asc'' is typical)');
  disp('     sixth optional paramter  = 3D mask file for EPI data');
  return;
end

Opt.Format = 'matrix';
[err, ima, ainfo, ErrMessage]=BrikLoad(ep2d_filename, Opt);
xdim=ainfo.DATASET_DIMENSIONS(1);
ydim=ainfo.DATASET_DIMENSIONS(2);
zdim=ainfo.DATASET_DIMENSIONS(3);
tdim=ainfo.DATASET_RANK(2);
TR=1000*double(ainfo.TAXIS_FLOATS(2));
if (exist('mask_filename','var')~=0)
  [err,mask,minfo,ErrMessage]=BrikLoad(mask_filename, Opt);
  mask(mask~=0)=1;
else
  mask=ones(xdim,ydim,zdim);
end
ima=double(reshape(ima,[xdim ydim zdim tdim]));
mask=double(reshape(mask,[xdim ydim zdim]));

% variance normalize the timeseries
variance=squeeze(std(ima,0,4));
variance=variance.*mask;
ima=ima./repmat(variance,[1 1 1 tdim]);

if (exist('M','var')==0)
  M=2;
  disp(sprintf('setting default RETROICOR model order to %d',M));
end

im_ca=zeros(xdim,ydim,zdim,M);
im_cb=zeros(xdim,ydim,zdim,M);
im_ra=zeros(xdim,ydim,zdim,M);
im_rb=zeros(xdim,ydim,zdim,M);
retima=zeros(xdim,ydim,zdim,tdim);
tim_ca=zeros(xdim,ydim,zdim,M);
tim_cb=zeros(xdim,ydim,zdim,M);
tim_ra=zeros(xdim,ydim,zdim,M);
tim_rb=zeros(xdim,ydim,zdim,M);

cdim=size(card);
if (cdim(1)>cdim(2))
  card=card';
end
cdim=size(resp);
if (cdim(1)>cdim(2))
  resp=resp';
end
% convert physio data input into phase before proceeding
%cardph=convert_physio_into_phase(card);
%respph=convert_physio_into_phase(resp);
cardph=card;
respph=resp;

if (exist('slice_timing','var')==0)
  slice_timing='siemens-alt-asc';
  disp('using interleaved ascending ''alt-asc'' for the slice timing');
end
if (exist('TR','var')==0)
  TR=1;
end
TE=35;
% setup slice timing of physiologic data
cph_slice=disassemble_timeseries_to_slices(cardph,zdim,tdim,TR,TE,slice_timing);
rph_slice=disassemble_timeseries_to_slices(respph,zdim,tdim,TR,TE,slice_timing);

% -ricor_regs REG1 REG2 ...       : specify ricor regressors (1 per run)
% 
%                 e.g. -ricor_regs slibase*.1D
% 
%             This option is required with a 'ricor' processing block.
% 
%             The expected format of the regressor files for RETROICOR processing
%             is one file per run, where each file contains a set of regressors
%             per slice.  If there are 5 runs and 27 slices, and if there are 13
%             regressors per slice, then there should be 5 files input, each with
%             351 (=27*13) columns.
% 
%             This format is based on the output of RetroTS.m, included in the
%             AFNI distribution (as part of the matlab package), by Z Saad.


% oba.slibase.1D contains [8 regressor columns] × [ number of slices ] × [ EPI time points ] rows
% ref: http://afni.nimh.nih.gov/sscc/hjj/anaticor
A=zeros(4*M,zdim,tdim);
for z=1:zdim
  A(:,z,:)=[sin((1:M)'*cph_slice(z,:))' cos((1:M)'*cph_slice(z,:))' sin((1:M)'*rph_slice(z,:))' cos((1:M)'*rph_slice(z,:))']';
end
A = reshape(A,[],tdim)';
save(fullfile(currentDir,'oba.slibase.1D'),'A','-ascii');
disp(['Saving regressors to ',fullfile(currentDir,'oba.slibase.1D')]);
