################################################################################
#
# vetro
#
################################################################################

VETRO_VERSION = 7aa0337f049f535e63ba30f73b85ce446ec17648
VETRO_SITE = $(call github,singularityos-lab,vetro,$(VETRO_VERSION))
VETRO_LICENSE = MIT

HOST_VETRO_BUILD_TARGETS = .
HOST_VETRO_LDFLAGS = -X main.version=$(VETRO_VERSION)

# Upstream go.mod declares "module vetro" and the source imports
# vetro/internal/...; build against that module path instead of the
# URL-inferred github.com/singularityos-lab/vetro.
HOST_VETRO_GOMOD = vetro

$(eval $(host-golang-package))
