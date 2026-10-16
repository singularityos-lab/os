################################################################################
#
# mythes-data
#
################################################################################

MYTHES_DATA_VERSION = 67032ee957631908098a72edf48dc81cac27e369
MYTHES_DATA_SITE = https://raw.githubusercontent.com/LibreOffice/dictionaries/$(MYTHES_DATA_VERSION)
MYTHES_DATA_SOURCE =
MYTHES_DATA_EXTRA_DOWNLOADS = \
	en/th_en_US_v2.dat \
	en/README_en_US.txt \
	it_IT/th_it_IT_v2.dat \
	it_IT/README_th_it_IT.txt
MYTHES_DATA_LICENSE = WordNet (en_US), GPL-3.0 (it_IT)
MYTHES_DATA_LICENSE_FILES = README_en_US.txt README_th_it_IT.txt

define MYTHES_DATA_EXTRACT_CMDS
	cp $(MYTHES_DATA_DL_DIR)/th_en_US_v2.dat $(MYTHES_DATA_DL_DIR)/README_en_US.txt \
		$(MYTHES_DATA_DL_DIR)/th_it_IT_v2.dat $(MYTHES_DATA_DL_DIR)/README_th_it_IT.txt $(@D)/
endef

define MYTHES_DATA_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0644 $(@D)/th_en_US_v2.dat $(TARGET_DIR)/usr/share/mythes/th_en_US_v2.dat
	$(INSTALL) -D -m 0644 $(@D)/th_it_IT_v2.dat $(TARGET_DIR)/usr/share/mythes/th_it_IT_v2.dat
endef

$(eval $(generic-package))
