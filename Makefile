# Variables to override
#
# CC            C compiler
# CROSSCOMPILE	crosscompiler prefix, if any
# CFLAGS	compiler flags for compiling all C files
# ERL_CFLAGS	additional compiler flags for files using Erlang header files
# ERL_EI_INCLUDE_DIR include path to ei.h (Required for crosscompile)
# ERL_EI_LIBDIR path to libei.a (Required for crosscompile)
# LDFLAGS	linker flags for linking all binaries
# ERL_LDFLAGS	additional linker flags for projects referencing Erlang libraries


MIX = mix
PREFIX = $(MIX_APP_PATH)/priv
DEFAULT_TARGETS ?= $(PREFIX) $(PREFIX)/scenic_driver_local

# # Look for the EI library and header files
# # For crosscompiled builds, ERL_EI_INCLUDE_DIR and ERL_EI_LIBDIR must be
# # passed into the Makefile.
# ifeq ($(ERL_EI_INCLUDE_DIR),)
# ERL_ROOT_DIR = $(shell erl -eval "io:format(\"~s~n\", [code:root_dir()])" -s init stop -noshell)
# ifeq ($(ERL_ROOT_DIR),)
# 	$(error Could not find the Erlang installation. Check to see that 'erl' is in your PATH)
# endif
# ERL_EI_INCLUDE_DIR = "$(ERL_ROOT_DIR)/usr/include"
# ERL_EI_LIBDIR = "$(ERL_ROOT_DIR)/usr/lib"
# endif

# # Set Erlang-specific compile and linker flags
# ERL_CFLAGS ?= -I$(ERL_EI_INCLUDE_DIR)
# ERL_LDFLAGS ?= -L$(ERL_EI_LIBDIR) -lei


# $(info $(SCENIC_LOCAL_TARGET))
# $(info ~~~~~~glfw~~~~~~)
$(info ~~~~~~In Makefile~~~~~~)
$(info $(SCENIC_LOCAL_TARGET))

ifeq ($(SCENIC_LOCAL_TARGET),glfw)
$(info ~~~~~~glfw~~~~~~)

	CFLAGS = -O3 -std=c99

	ifndef MIX_ENV
		MIX_ENV = dev
	endif

	ifdef DEBUG
		CFLAGS +=  -pedantic -Weverything -Wall -Wextra -Wno-unused-parameter -Wno-gnu
	endif

	ifeq ($(MIX_ENV),dev)
		CFLAGS += -g
	endif

	LDFLAGS += `pkg-config --static --libs glfw3 glew`
	CFLAGS += `pkg-config --static --cflags glfw3 glew`

	ifneq ($(OS),Windows_NT)
		CFLAGS += -fPIC

		ifeq ($(shell uname),Darwin)
			LDFLAGS += -framework Cocoa -framework OpenGL -Wno-deprecated
		else
		  LDFLAGS += -lGL -lm -lrt
		endif
	endif
	SRCS = c_src/device/glfw.c
endif

ifeq ($(SCENIC_LOCAL_TARGET),bcm)
$(info ~~~~~~ bcm ~~~~~~)
	LDFLAGS += -lGLESv2 -lEGL -lm -lvchostif -lbcm_host
	CFLAGS ?= -O2 -Wall -Wextra -Wno-unused-parameter -pedantic
	CFLAGS += -std=gnu99
	SRCS = c_src/device/bcm.c
endif

ifeq ($(SCENIC_LOCAL_TARGET),drm_gles2)
$(info ~~~~~~ drm_gles2 ~~~~~~)

	LDFLAGS += -lGLESv2 -lEGL -lm -lvchostif -ldrm -lgbm
	CFLAGS ?= -O2 -Wall -Wextra -Wno-unused-parameter -pedantic
	CFLAGS += -std=gnu99

# 	CFLAGS += $(shell pkg-config --cflags libdrm)
# 	LDFLAGS += $(shell pkg-config --libs libdrm)

	CFLAGS += -fPIC -I$(NERVES_SDK_SYSROOT)/usr/include/drm
# 	LDFLAGS += -lGLESv2 -lm -lrt -ldl -lEGL -lgbm -ldrm  -lvchostif

	SRCS = c_src/device/drm_gles2.c
endif

ifeq ($(SCENIC_LOCAL_TARGET),drm_gles3)
$(info ~~~~~~ drm_gles3 ~~~~~~)

	LDFLAGS += -lGLESv2 -lEGL -lm -lvchostif -ldrm -lgbm
	CFLAGS ?= -O2 -Wall -Wextra -Wno-unused-parameter -pedantic
	CFLAGS += -std=gnu99

	CFLAGS += -fPIC -I$(NERVES_SDK_SYSROOT)/usr/include/drm

	SRCS = c_src/device/drm_gles3.c
endif

# $(info $(shell printenv))

SRCS += c_src/main.c c_src/nanovg/nanovg.c c_src/comms.c c_src/unix_comms.c \
c_src/utils.c c_src/script.c c_src/image.c c_src/font.c \
c_src/tommyds/src/tommyhashlin.c c_src/tommyds/src/tommyhash.c

calling_from_make:
	mix compile

all: $(DEFAULT_TARGETS)

$(PREFIX):
	mkdir -p $@

$(PREFIX)/scenic_driver_local: $(SRCS)
	$(CC) $(CFLAGS) -o $@ $(SRCS) $(LDFLAGS)

clean:
	$(RM) -rf $(PREFIX)

.PHONY: all clean calling_from_make

