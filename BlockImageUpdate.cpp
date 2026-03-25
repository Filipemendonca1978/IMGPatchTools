//
//  BlockImageUpdate.cpp
//
//  Created by Erfan Abdi, Updated by rhn_1k
//

#include <iostream>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <unistd.h>

#include "blockimg/blockimg.h"
#include "edify/expr.h"

#define COLOR_RESET   "\x1b[0m"
#define COLOR_GREEN   "\x1b[32m"
#define COLOR_YELLOW  "\x1b[33m"
#define COLOR_CYAN    "\x1b[36m"
#define COLOR_MAGENTA "\x1b[35m"

#define CHUNK_SIZE_TERMUX (16 * 1024 * 1024)

int is_termux(void) {
    const char* prefix = getenv("PREFIX");
    if (prefix != NULL && strstr(prefix, "termux") != NULL) {
        return 1;
    }
    if (access("/data/data/com.termux", F_OK) == 0) {
        return 1;
    }
    return 0;
}

void print_success(const char* msg) {
    fprintf(stderr, "%s[✓]%s %s\n", COLOR_GREEN, COLOR_RESET, msg);
}

void print_info(const char* msg) {
    fprintf(stderr, "%s[*]%s %s\n", COLOR_YELLOW, COLOR_RESET, msg);
}

void print_error(const char* msg) {
    fprintf(stderr, "%s[!]%s %s\n", COLOR_MAGENTA, COLOR_RESET, msg);
}

int main(int argc, char* argv[]) {
    if (argc >= 2) {
        if (strcmp(argv[1], "-h") == 0 || strcmp(argv[1], "--help") == 0) {
            
            printf("usage: %s <system.img> <system.transfer.list> <system.new.dat> <system.patch.dat>\n\n", argv[0]);
            printf("args:\n");
            printf("\t- block device (or file) to modify in-place\n");
            printf("\t- transfer list (blob)\n");
            printf("\t- new data stream (filename within package.zip)\n");
            printf("\t- patch stream (filename within package.zip, must be uncompressed)\n");
            return EXIT_SUCCESS;
        }
    }
    
    if (argc < 5) {
        
        printf("usage: %s <system.img> <system.transfer.list> <system.new.dat> <system.patch.dat>\n\n", argv[0]);
        printf("args:\n");
        printf("\t- block device (or file) to modify in-place\n");
        printf("\t- transfer list (blob)\n");
        printf("\t- new data stream (filename within package.zip)\n");
        printf("\t- patch stream (filename within package.zip, must be uncompressed)\n");
        return EXIT_FAILURE;
    }
    
    
    
    int termux_env = is_termux();
    
    if (termux_env) {
        print_info("Termux Detected, using 16MB chunks to prevent crash");
    } else {
        print_info("Linux Detected, unrestricted chunk processing");
    }
    
    fprintf(stderr, "\n");
    
    State state_obj = {};
    State* state = &state_obj;
    
    int ret = BlockImageUpdateFn("BlockImageUpdateFn", state, argc, argv);
    
    fprintf(stderr, "\n");
    if (ret == 0) {
        print_success("Block Image Update Completed Successfully");
    } else {
        print_error("Block Image Update Failed");
    }
    
    return ret == 0 ? EXIT_SUCCESS : EXIT_FAILURE;
}
