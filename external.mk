include $(sort $(wildcard $(BR2_EXTERNAL_SINGULARITY_PATH)/package/*/*.mk))

define SINTY_MIME_DESCRIPTIONS
	if [ -x $(HOST_DIR)/bin/update-mime-database ] && [ -f $(HOST_DIR)/share/mime/packages/freedesktop.org.xml ] && [ -d $(TARGET_DIR)/usr/share/mime ]; then \
		mkdir -p $(TARGET_DIR)/usr/share/mime/packages && \
		cp $(HOST_DIR)/share/mime/packages/freedesktop.org.xml $(TARGET_DIR)/usr/share/mime/packages/ && \
		$(HOST_DIR)/bin/update-mime-database $(TARGET_DIR)/usr/share/mime; \
	fi
endef
TARGET_FINALIZE_HOOKS += SINTY_MIME_DESCRIPTIONS
