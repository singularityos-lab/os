################################################################################
#
# whisper-cpp
#
################################################################################

WHISPER_CPP_VERSION = 1.7.5
WHISPER_CPP_SITE = $(call github,ggml-org,whisper.cpp,v$(WHISPER_CPP_VERSION))
WHISPER_CPP_LICENSE = MIT
WHISPER_CPP_LICENSE_FILES = LICENSE
WHISPER_CPP_INSTALL_STAGING = YES
WHISPER_CPP_CONF_OPTS = \
	-DBUILD_SHARED_LIBS=ON \
	-DWHISPER_BUILD_TESTS=OFF \
	-DWHISPER_BUILD_SERVER=OFF \
	-DWHISPER_BUILD_EXAMPLES=ON \
	-DWHISPER_SDL2=OFF \
	-DWHISPER_CURL=OFF \
	-DGGML_NATIVE=OFF \
	-DGGML_BACKEND_DL=ON \
	-DGGML_CPU_ALL_VARIANTS=ON \
	-DGGML_OPENMP=OFF \
	-DGGML_CCACHE=OFF \
	-DGGML_CUDA=OFF \
	-DGGML_VULKAN=OFF

define WHISPER_CPP_INSTALL_CLI
	$(INSTALL) -d -m 0755 $(TARGET_DIR)/usr/lib/whisper-cpp
	mv $(TARGET_DIR)/usr/bin/whisper-cli $(TARGET_DIR)/usr/lib/whisper-cpp/whisper-cli
	$(INSTALL) -m 0755 $(@D)/buildroot-build/bin/libggml-cpu-*.so $(TARGET_DIR)/usr/lib/whisper-cpp/
	ln -sf ../lib/whisper-cpp/whisper-cli $(TARGET_DIR)/usr/bin/whisper-cli
	rm -f $(addprefix $(TARGET_DIR)/usr/bin/,main bench stream command talk-llama quantize \
		whisper-bench whisper-quantize whisper-server whisper-stream whisper-command)
endef

WHISPER_CPP_POST_INSTALL_TARGET_HOOKS += WHISPER_CPP_INSTALL_CLI

$(eval $(cmake-package))
