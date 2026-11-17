################################################################################
#
# glslang
#
################################################################################

HOST_GLSLANG_VERSION = 16.6.0
HOST_GLSLANG_SITE = $(call github,KhronosGroup,glslang,$(HOST_GLSLANG_VERSION))
HOST_GLSLANG_LICENSE = BSD-3-Clause, BSD-2-Clause, MIT, Apache-2.0
HOST_GLSLANG_LICENSE_FILES = LICENSE.txt
HOST_GLSLANG_DEPENDENCIES = host-python3
HOST_GLSLANG_CONF_OPTS = \
	-DENABLE_OPT=OFF \
	-DGLSLANG_TESTS=OFF \
	-DENABLE_GLSLANG_BINARIES=ON \
	-DBUILD_SHARED_LIBS=OFF

$(eval $(host-cmake-package))
