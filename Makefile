# The name of the LF application inside "./src" to build/run/flash etc.
LF_MAIN ?= HelloWorld

# Enable reactor-uc features
# CFLAGS += -DNETWORK_CHANNEL_TCP_POSIX
# CFLAGS += -DNETWORK_CHANNEL_COAP_RIOT

# Make default debug output report only info and errors.
CFLAGS += -DLF_LOG_LEVEL_ALL=LF_LOG_LEVEL_ERROR

# Execute the LF compiler if build target is "all"
ifeq ($(firstword $(MAKECMDGOALS)),all)
  _ :=  $(shell $(REACTOR_UC_PATH)/lfc/bin/lfc-dev src/$(LF_MAIN).lf)
endif

# ---- RIOT specific configuration ----
# This has to be the absolute path to the RIOT base directory:
RIOTBASE = $(CURDIR)/RIOT

# If no BOARD is found in the environment, use this default:
BOARD ?= native

# Comment this out to disable code in RIOT that does safety checking
# which is not needed in a production environment but helps in the
# development process:
DEVELHELP ?= 1

# Change this to 0 show compiler invocation lines by default:
QUIET ?= 1

EVENT_QUEUE_SIZE?=20
REACTION_QUEUE_SIZE?=20


# Skip the reactor-uc include for `docker-*` targets, which run on the host
# where REACTOR_UC_PATH is not set. Inside the container the variable is set
# via the Dockerfile and the include works normally.
ifeq ($(filter docker-%,$(MAKECMDGOALS)),)
include $(REACTOR_UC_PATH)/make/riot/riot-lfc.mk
endif

# ---- Docker dev environment ----
DOCKER_IMAGE     ?= lf-riot-uc-dev
DOCKER_USER_UID  ?= $(shell id -u)
DOCKER_USER_GID  ?= $(shell id -g)
REACTOR_UC_REF   ?= main

# Pass through all USB devices (for picotool) plus any present serial TTYs
# (for bossac). Wildcards are evaluated when make is invoked, so plug the
# board in before running docker-flash / docker-shell.
DOCKER_RUN_FLAGS = --rm -it \
  -v $(CURDIR):/workspace -w /workspace # \
#   --device=/dev/bus/usb:/dev/bus/usb \
#   $(foreach d,$(wildcard /dev/ttyACM*),--device=$(d)) \
#   $(foreach d,$(wildcard /dev/ttyUSB*),--device=$(d))

.PHONY: docker-build docker-shell

docker-build:
	docker build \
	  --build-arg USER_UID=$(DOCKER_USER_UID) \
	  --build-arg USER_GID=$(DOCKER_USER_GID) \
	  --build-arg REACTOR_UC_REF=$(REACTOR_UC_REF) \
	  -t $(DOCKER_IMAGE) .

docker-shell:
	docker run $(DOCKER_RUN_FLAGS) $(DOCKER_IMAGE) bash

# Targets forwarded into the container as `make <target>`. Listed
# explicitly so typos like `make docker-flsh` fail on the host instead of
# silently launching a container with a bogus make invocation.
DOCKER_FORWARD_TARGETS = all flash term clean

.PHONY: $(addprefix docker-,$(DOCKER_FORWARD_TARGETS))

$(addprefix docker-,$(DOCKER_FORWARD_TARGETS)):
	docker run $(DOCKER_RUN_FLAGS) $(DOCKER_IMAGE) make $(patsubst docker-%,%,$@)
