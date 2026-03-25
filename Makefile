CC      := clang
CXX     := clang++
AR      := llvm-ar
PREFIX  ?= /usr/local

GREEN  := \033[1;32m
BLUE   := \033[1;34m
CYAN   := \033[1;36m
RESET  := \033[0m

BASE_CFLAGS := -O3 -ffunction-sections -fdata-sections -march=armv8-a -fPIC
WARN_FLAGS  := -Wall -Wextra -Wformat=2
SUPPRESS_FLAGS := \
    -Wno-deprecated-declarations \
    -Wno-unused-parameter \
    -Wno-unused-variable \
    -Wno-unused-function \
    -Wno-unused-label

CFLAGS   := $(BASE_CFLAGS) $(WARN_FLAGS) $(SUPPRESS_FLAGS) -std=c99
CXXFLAGS := $(BASE_CFLAGS) $(WARN_FLAGS) $(SUPPRESS_FLAGS) -std=c++11
INCLUDES := -I. -I./include
LIBS     := -lssl -lcrypto -lz -lbz2 -lpthread
LDFLAGS  := -Wl,--gc-sections -s

BLOCKIMG_SOURCES := BlockImageUpdate.cpp \
                    blockimg/blockimg.cpp \
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

OBJ_DIR := obj
BIN_DIR := bin

BLOCKIMG_OBJS := $(BLOCKIMG_SOURCES:%=$(OBJ_DIR)/%.o)

all: $(BIN_DIR)/BlockImageUpdate

$(OBJ_DIR)/%.cpp.o: %.cpp
	@mkdir -p $(dir $@)
	@printf "  $(BLUE)CXX$(RESET)     %s\n" "$<"
	@$(CXX) $(CXXFLAGS) $(INCLUDES) -c $< -o $@

$(OBJ_DIR)/%.c.o: %.c
	@mkdir -p $(dir $@)
	@printf "  $(CYAN)CC$(RESET)      %s\n" "$<"
	@$(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@

$(BIN_DIR)/BlockImageUpdate: $(BLOCKIMG_OBJS) | $(BIN_DIR)
	@printf "  $(GREEN)LD$(RESET)      %s\n" "$@"
	@$(CXX) $(CXXFLAGS) $^ $(LIBS) $(LDFLAGS) -o $@
	@printf "$(GREEN)[✓] Built: %s$(RESET)\n" "$@"
	@size $@

$(BIN_DIR):
	@mkdir -p $(BIN_DIR)

clean:
	@printf "  $(CYAN)CLEAN$(RESET)   %s %s\n" "$(BIN_DIR)" "$(OBJ_DIR)"
	@rm -rf $(OBJ_DIR) $(BIN_DIR)

rebuild: clean all

strip: all
	@printf "  $(CYAN)STRIP$(RESET)   %s/BlockImageUpdate\n" "$(BIN_DIR)"
	@strip -s $(BIN_DIR)/*

check-warnings: clean
	@printf "  $(BLUE)CHECK$(RESET)   BlockImageUpdate.cpp\n"
	@$(CXX) $(BASE_CFLAGS) -Wall -Wextra $(INCLUDES) -c BlockImageUpdate.cpp -o /dev/null 2>&1 | grep -i "warning" | head -5 || printf "  $(GREEN)OK$(RESET)\n"

install: all strip
	@printf "  $(BLUE)INSTALL$(RESET) %s/bin/\n" "$(PREFIX)"
	@mkdir -p $(PREFIX)/bin
	@cp $(BIN_DIR)/BlockImageUpdate $(PREFIX)/bin/
	@chmod +x $(PREFIX)/bin/BlockImageUpdate

help:
	@printf "$(CYAN)BlockImageUpdate Build System$(RESET)\n"
	@echo "Targets: all, clean, rebuild, strip, check-warnings, install"

.PHONY: all clean rebuild strip check-warnings install help
.DEFAULT_GOAL := all
