include $(BR2_EXTERNAL_SINGULARITY_PATH)/package/fotone/fotone.version
include $(sort $(wildcard $(BR2_EXTERNAL_SINGULARITY_PATH)/package/*/*.mk))

define SINTY_MIME_DESCRIPTIONS
	if [ -x $(HOST_DIR)/bin/update-mime-database ] && [ -f $(HOST_DIR)/share/mime/packages/freedesktop.org.xml ] && [ -d $(TARGET_DIR)/usr/share/mime ]; then \
		mkdir -p $(TARGET_DIR)/usr/share/mime/packages && \
		cp $(HOST_DIR)/share/mime/packages/freedesktop.org.xml $(TARGET_DIR)/usr/share/mime/packages/ && \
		cp $(BR2_EXTERNAL_SINGULARITY_PATH)/board/mime/sinty-html.xml $(TARGET_DIR)/usr/share/mime/packages/ && \
		$(HOST_DIR)/bin/update-mime-database $(TARGET_DIR)/usr/share/mime; \
	fi
endef
TARGET_FINALIZE_HOOKS += SINTY_MIME_DESCRIPTIONS

define SINTY_KEEP_TARGET_SCHEMAS
	mkdir -p $(STAGING_DIR)/usr/share/glib-2.0/schemas
	for f in $(TARGET_DIR)/usr/share/glib-2.0/schemas/*.xml; do \
		[ -e "$$f" ] || continue; \
		[ -e $(STAGING_DIR)/usr/share/glib-2.0/schemas/$${f##*/} ] || cp "$$f" $(STAGING_DIR)/usr/share/glib-2.0/schemas/; \
	done
endef
TARGET_FINALIZE_HOOKS := SINTY_KEEP_TARGET_SCHEMAS $(TARGET_FINALIZE_HOOKS)

WEBKITGTK_MAKE_OPTS += -j$(shell awk '/^MemAvailable:/ { j = int($$2 / 3000000); if (j < 2) j = 2; print j }' /proc/meminfo)

SINTY_MODULE_SIGNING_KEY ?= $(HOME)/.config/sinty/module-signing.pem

define SINTY_STABLE_MODULE_SIGNING_KEY
	if [ -f "$(SINTY_MODULE_SIGNING_KEY)" ]; then \
		install -m 600 "$(SINTY_MODULE_SIGNING_KEY)" $(LINUX_DIR)/certs/signing_key.pem; \
	elif [ -n "$(ATOM_BUILD)" ]; then \
		echo "release kernel needs the module signing key at $(SINTY_MODULE_SIGNING_KEY)" >&2; exit 1; \
	fi
endef
LINUX_PRE_BUILD_HOOKS += SINTY_STABLE_MODULE_SIGNING_KEY
