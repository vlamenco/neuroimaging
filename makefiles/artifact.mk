include $(pbUdallBin)/exportVars.mk

subjects=$(notdir $(wildcard $(restDir)/RC4[1-2][0-9][0-9]-[1-2]))
mnArtifacts=$(subjects:RC4%=$(restDir)/RC4%/mn_binv_rest_ssmooth.txt)

all: $(mnArtifacts)

%/mn_binv_rest_ssmooth.txt:
	fslmaths $*/mask -binv $*/binv_mask ;\
	fslstats -t $*/rest_ssmooth -k $*/binv_mask -M>$*/mn_binv_rest_ssmooth.txt ;\
	fslstats -t $*/rest_ssmooth -k $*/binv_mask -S>$*/sd_binv_rest_ssmooth.txt
