CC      := clang
CXX     := clang++
AR      := llvm-ar
PREFIX  ?= /usr/local

GREEN  := \033[1;32m
BLUE   := \033[1;34m
CYAN   := \033[1;36m
RESET  := \033[0m

BASE_CFLAGS := -O3 -ffunction-sections -fdata-sections -fPIC
WARN_FLAGS  := -Wall -Wextra -Wformat=2
SUPPRESS_FLAGS := \
    -Wno-deprecated-declarations \
    -Wno-unused-parameter \
    -Wno-unused-variable \
    -Wno-unused-function \
    -Wno-unused-label

CFLAGS   := $(BASE_CFLAGS) $(WARN_FLAGS) $(SUPPRESS_FLAGS) -std=c99
CXXFLAGS := $(BASE_CFLAGS) $(WARN_FLAGS) $(SUPPRESS_FLAGS) -std=c++11

INCLUDES := -I. -I./include -I../include -I/usr/local/include -I../
LIBS     := -lssl -lcrypto -lz -lbz2 -lpthread
LDFLAGS  := -Wl,--gc-sections -s

UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
    LDFLAGS += -dead_strip
endif

SHARED_SOURCES := \
    edify/expr.cpp \
    android-base/stringprintf.cpp \
    android-base/strings.cpp \
    minzip/Hash.c \
    applypatch/bspatch.cpp \
    applypatch/bsdiff.cpp \
    applypatch/imgpatch.cpp \
    applypatch/imgdiff.cpp \
    applypatch/utils.cpp \
    otafault/ota_io.cpp

BLOCKIMG_COMMON := $(SHARED_SOURCES) blockimg/blockimg.cpp

UPDATE_SOURCES     := BlockImageUpdate.cpp $(BLOCKIMG_COMMON)
VERIFY_SOURCES     := BlockImageVerify.cpp $(BLOCKIMG_COMMON)
IMGDIFF_SOURCES    := imgdiff.cpp $(SHARED_SOURCES)
APPLYPATCH_SOURCES := ApplyPatch.cpp applypatch/applypatch.cpp $(SHARED_SOURCES)

OBJ_DIR := obj
BIN_DIR := bin

UPDATE_OBJS     := $(UPDATE_SOURCES:%=$(OBJ_DIR)/%.o)
VERIFY_OBJS     := $(VERIFY_SOURCES:%=$(OBJ_DIR)/%.o)
IMGDIFF_OBJS    := $(IMGDIFF_SOURCES:%=$(OBJ_DIR)/%.o)
APPLYPATCH_OBJS := $(APPLYPATCH_SOURCES:%=$(OBJ_DIR)/%.o)

BINARIES := $(BIN_DIR)/BlockImageUpdate \
            $(BIN_DIR)/BlockImageVerify \
            $(BIN_DIR)/imgdiff \
            $(BIN_DIR)/ApplyPatch

all: $(BINARIES) scriptp

$(OBJ_DIR)/%.cpp.o: %.cpp
	@mkdir -p $(dir $@)
	@printf "  $(BLUE)CXX$(RESET)     %s\n" "$<"
	@$(CXX) $(CXXFLAGS) $(INCLUDES) -c $< -o $@

$(OBJ_DIR)/%.c.o: %.c
	@mkdir -p $(dir $@)
	@printf "  $(CYAN)CC$(RESET)      %s\n" "$<"
	@$(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@

$(BIN_DIR)/BlockImageUpdate: $(UPDATE_OBJS) | $(BIN_DIR)
	@printf "  $(GREEN)LD$(RESET)      %s\n" "$@"
	@$(CXX) $(CXXFLAGS) $^ $(LIBS) $(LDFLAGS) -o $@
	@printf "$(GREEN)[✓] Built: %s$(RESET)\n" "$@"
	@size $@

$(BIN_DIR)/BlockImageVerify: $(VERIFY_OBJS) | $(BIN_DIR)
	@printf "  $(GREEN)LD$(RESET)      %s\n" "$@"
	@$(CXX) $(CXXFLAGS) $^ $(LIBS) $(LDFLAGS) -o $@
	@printf "$(GREEN)[✓] Built: %s$(RESET)\n" "$@"
	@size $@

$(BIN_DIR)/imgdiff: $(IMGDIFF_OBJS) | $(BIN_DIR)
	@printf "  $(GREEN)LD$(RESET)      %s\n" "$@"
	@$(CXX) $(CXXFLAGS) $^ $(LIBS) $(LDFLAGS) -o $@
	@printf "$(GREEN)[✓] Built: %s$(RESET)\n" "$@"
	@size $@

$(BIN_DIR)/ApplyPatch: $(APPLYPATCH_OBJS) | $(BIN_DIR)
	@printf "  $(GREEN)LD$(RESET)      %s\n" "$@"
	@$(CXX) $(CXXFLAGS) $^ $(LIBS) $(LDFLAGS) -o $@
	@printf "$(GREEN)[✓] Built: %s$(RESET)\n" "$@"
	@size $@

scriptp: | $(BIN_DIR)
	@if [ -f scriptpatcher.sh ]; then \
		printf "  $(BLUE)CP$(RESET)      scriptpatcher.sh\n"; \
		cp scriptpatcher.sh $(BIN_DIR)/; \
		chmod +x $(BIN_DIR)/scriptpatcher.sh; \
	fi

$(BIN_DIR):
	@mkdir -p $(BIN_DIR)

clean:
	@printf "  $(CYAN)CLEAN$(RESET)   %s %s\n" "$(BIN_DIR)" "$(OBJ_DIR)"
	@rm -rf $(OBJ_DIR) $(BIN_DIR)

rebuild: clean all

strip: all
	@printf "  $(CYAN)STRIP$(RESET)   %s/*\n" "$(BIN_DIR)"
	@strip -s $(BIN_DIR)/* 2>/dev/null || true

check-warnings: clean
	@printf "  $(BLUE)CHECK$(RESET)   Sources\n"
	@$(CXX) $(BASE_CFLAGS) -Wall -Wextra $(INCLUDES) -c BlockImageUpdate.cpp -o /dev/null 2>&1 | grep -i "warning" | head -5 || printf "  $(GREEN)OK$(RESET)\n"

install: all strip
	@printf "  $(BLUE)INSTALL$(RESET) %s/bin/\n" "$(PREFIX)"
	@mkdir -p $(PREFIX)/bin
	@cp -r $(BIN_DIR)/* $(PREFIX)/bin/

help:
	@printf "$(CYAN)IMGPatchTools Build System$(RESET)\n"
	@echo "Targets: all, clean, rebuild, strip, check-warnings, install"

.PHONY: all clean rebuild strip check-warnings install help scriptp
.DEFAULT_GOAL := all
